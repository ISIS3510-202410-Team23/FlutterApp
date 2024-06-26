import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:foodbook_app/data/data_access_objects/restaurants_cache_dao.dart';
import 'package:foodbook_app/data/dtos/review_dto.dart';
import 'package:foodbook_app/data/models/review.dart';
import 'package:http/http.dart' as http;
import 'package:foodbook_app/data/dtos/restaurant_dto.dart';
import 'package:foodbook_app/data/models/restaurant.dart';

class RestaurantRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RestaurantsCacheDAO _restaurantsCacheDAO = RestaurantsCacheDAO();

  Future<List<Restaurant>> fetchRestaurants() async {
    List<Restaurant> restaurants = [];
    try {
      final pro = await _firestore.collection('spots').get();
      for (var element in pro.docs) {
        // Guarda el id del restaurante
        String restaurantId = element.id;
        var restaurantData = element.data();
        var restaurantDTO = RestaurantDTO.fromJson(restaurantId, restaurantData);
        Restaurant restaurant = restaurantDTO.toModel();
        _restaurantsCacheDAO.cacheRestaurant(restaurant);
        var reviewReferences = restaurantData['reviewData']['userReviews'] as List<dynamic>?;
        if (reviewReferences != null) {
          List<Review> reviews = [];
          for (var reviewRef in reviewReferences) {
            DocumentSnapshot reviewSnapshot = await (reviewRef as DocumentReference).get();
            if (reviewSnapshot.exists) {
              reviews.add(ReviewDTO.fromJson(reviewSnapshot.data() as Map<String, dynamic>).toModel());
            }
          }
          restaurant.reviews = reviews;
        }
        restaurants.add(restaurant);
      }
      return restaurants;
    }
    on FirebaseException catch (e) {
      if (kDebugMode) {
        print("Failed to fetch restaurants: $e");
      }
      return [];
    }
    catch (e) {
      if (kDebugMode) {
        print("Failed to fetch restaurants: $e");
      }
    return [];
    }
  }

  Future<List<Restaurant>> fetchRestaurantsFromCache() async {
    List<Restaurant> restaurants = [];
    List<String> restaurantNames = await _restaurantsCacheDAO.getCachedRestaurants();
    if (restaurantNames.isNotEmpty) {
      for (var name in restaurantNames) {
        var details = await _restaurantsCacheDAO.findRestaurantByName(name);
        if (details != null) {
          restaurants.add(details);
        }
      }
    }
    return restaurants;
  }


  Future<void> addReviewToRestaurant(String restaurantId, String reviewId) async {
    try {
      DocumentReference restaurantRef = _firestore.collection('spots').doc(restaurantId);
      
      DocumentReference reviewRef = _firestore.collection('reviews').doc(reviewId);
      
      await restaurantRef.update({
        'reviewData.userReviews': FieldValue.arrayUnion([reviewRef])
      });
    } catch (e) {
      if (kDebugMode) {
        print("Failed to add review to restaurant: $e");
      }
      rethrow;
    }
  }
  
  Future<String?> findRestaurantIdByName(String name) async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('spots')
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>> getRestaurantsIdsFromIntAPI(String username) async {
    final response = await http.get(Uri.parse('https://foodbook-app-backend.vercel.app/recommendation/$username'));
    if (response.statusCode == 404) {
      throw Exception('Leave reviews to get personalized recommendations!');
    }
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['spots'];
    }
    else{
      throw Exception('Failed to fetch recommended restaurants');
    }
    
  }

  Future<Restaurant?> fetchRestaurantById(String restaurantId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> restaurantSnapshot = await _firestore.collection('spots').doc(restaurantId).get();
      if (restaurantSnapshot.exists && restaurantSnapshot.data() != null) {
        var restaurantDTO = RestaurantDTO.fromJson(restaurantId,restaurantSnapshot.data()!);
        Restaurant restaurant = restaurantDTO.toModel();
        _restaurantsCacheDAO.cacheRestaurantFYP(restaurant);
        List<dynamic>? reviewRefs = restaurantSnapshot.data()?['reviewData']['userReviews'];
        if (reviewRefs is List<dynamic>) {
        List<Review> reviews = [];
        for (DocumentReference reviewRef in reviewRefs) {
          DocumentSnapshot<Map<String, dynamic>> reviewSnapshot = await reviewRef.get() as DocumentSnapshot<Map<String, dynamic>>;
          if (reviewSnapshot.exists && reviewSnapshot.data() != null) {
            reviews.add(ReviewDTO.fromJson(reviewSnapshot.data()!).toModel());
          }
        }
        restaurant.reviews = reviews;
        }
        return restaurant;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching restaurant by ID: $e");
      }
      return null;
    }
  }

  Future<List<Restaurant>> fetchCachedFYP() async {
    List<Restaurant> restaurants = [];
    List<String> restaurantNames = await _restaurantsCacheDAO.getCachedRestaurantFYP();
    if (restaurantNames.isNotEmpty) {
      for (var name in restaurantNames) {
        var details = await _restaurantsCacheDAO.findRestaurantByName(name);
        if (details != null) {
          restaurants.add(details);
        }
      }
    }
    return restaurants;
  }
  
  Future<void> addSpotDetailFetchingTime(String id, double time) async {
    String spot = '';

    // get spot name
    DocumentSnapshot<Map<String, dynamic>> restaurantSnapshot = await _firestore.collection('spots').doc(id).get();
    if (restaurantSnapshot.exists && restaurantSnapshot.data() != null) {
      spot = restaurantSnapshot.data()!['name'];
    }

    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('spotDetailFetchingTime')
          .where('spot', isEqualTo: spot)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final id = querySnapshot.docs.first.id;
        DocumentReference restaurantSnapshot = _firestore.collection('spotDetailFetchingTime').doc(id);
        await restaurantSnapshot.update({
          'times': FieldValue.arrayUnion([{
            'date': Timestamp.fromDate(DateTime.now()),
            'platform': 'Android',
            'time': time
          }])
        });
      } else {
        return;
      }
    } catch (e) {
      return null;
    }
  }

}