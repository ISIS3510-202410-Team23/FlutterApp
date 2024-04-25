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
  final RestaurantsCacheDAO _restaurantsCacheDAO = RestaurantsCacheDAO();

  Future<List<Restaurant>> fetchRestaurants() async {
  List<Restaurant> restaurants = [];
  try {
    final pro = await FirebaseFirestore.instance.collection('spots').get();

    for (var element in pro.docs) {
      var restaurantData = element.data();
      var restaurantDTO = RestaurantDTO.fromJson(restaurantData);
      Restaurant restaurant = restaurantDTO.toModel();
      _restaurantsCacheDAO.cacheRestaurant(restaurant);
      print("cached restaurant: ${restaurant.name}");
      
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
  } on FirebaseException catch (e) {
    print("Failed to fetch restaurants with error '${e.code}': ${e.message}");
    // Intenta recuperar los datos desde la caché
    // print('intentando recuperar datos desde la caché');
    // List<String> cachedData = await _restaurantsCacheDAO.getBrowseCache();
    // print('cachedData: $cachedData');
    // if (cachedData.isNotEmpty) {
    //   for (var jsonData in cachedData) {
    //     var restDTO = RestaurantDTO.fromJson(json.decode(jsonData));
    //     restaurants.add(restDTO.toModel());
    //   }
    //   print("Fetched restaurants from cache due to Firebase error.");
    // }
    return restaurants;
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
      print('RESTAURANT ID: $restaurantId');
      DocumentReference restaurantRef = FirebaseFirestore.instance.collection('spots').doc(restaurantId);
      
      DocumentReference reviewRef = FirebaseFirestore.instance.collection('reviews').doc(reviewId);
      
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
      print("Error al buscar el restaurante: $e");
      return null;
    }
  }

  Future<List<dynamic>> getRestaurantsIdsFromIntAPI(String username) async {
    final response = await http.get(Uri.parse('https://foodbook-app-backend.2.us-1.fl0.io/recommendation/$username'));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch recommended restaurants');
    }

    final jsonResponse = jsonDecode(response.body);
    print('JSON RESPONSE: ${jsonResponse}');
    return jsonResponse['spots'];
  }

  Future<Restaurant?> fetchRestaurantById(String restaurantId) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    try {
      DocumentSnapshot<Map<String, dynamic>> restaurantSnapshot = await db.collection('spots').doc(restaurantId).get();
      if (restaurantSnapshot.exists && restaurantSnapshot.data() != null) {
        var restaurantDTO = RestaurantDTO.fromJson(restaurantSnapshot.data()!);
        Restaurant restaurant = restaurantDTO.toModel();

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
        print('O: ${restaurant.reviews}');
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

  // Find restaurant by name
  Future<Restaurant?> findRestaurantByName(String name) async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('spots')
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var restaurantData = querySnapshot.docs.first.data();
        var restaurantDTO = RestaurantDTO.fromJson(restaurantData);
        Restaurant restaurant = restaurantDTO.toModel();
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
        return restaurant;
      } else {
        return null;
      }
    } catch (e) {
      print("Error finding restaurant: $e");
      return null;
    }
  }
  
}