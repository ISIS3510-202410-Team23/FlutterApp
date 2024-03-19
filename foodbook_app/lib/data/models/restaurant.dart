import 'package:foodbook_app/data/models/review.dart';

class Restaurant {
  final String id;
  final String name;
  final String priceRange;
  final String timeRange;
  final double distance;
  final List<String> categories;
  final List<String> imagePaths;
  final List<Review> reviews;
  final int cleanliness_avg;
  final int waiting_time_avg;
  final int service_avg;
  final int food_quality_avg;
  final double latitude;
  final double longitude;
  bool bookmarked;

  Restaurant({
    required this.id,
    required this.name,
    required this.priceRange,
    required this.timeRange,
    required this.distance,
    required this.categories,
    required this.imagePaths,
    required this.reviews,
    required this.cleanliness_avg,
    required this.waiting_time_avg,
    required this.service_avg,
    required this.food_quality_avg,
    required this.latitude,
    required this.longitude,
    required this.bookmarked,
  });

  // Method to create a Restaurant from a JSON object
  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      name: json['name'],
      priceRange: json['priceRange'],
      timeRange: json['timeRange'],
      distance: json['distance'],
      categories: List<String>.from(json['categories']),
      imagePaths: List<String>.from(json['imagePaths']),
      reviews: List<Review>.from(json['reviews']),
      cleanliness_avg: json['cleanliness_avg'],
      waiting_time_avg: json['waiting_time_avg'],
      service_avg: json['service_avg'],
      food_quality_avg: json['food_quality_avg'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      bookmarked: false,
    );
  }

  // Method to convert a Restaurant object to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'priceRange': priceRange,
      'timeRange': timeRange,
      'distance': distance,
      'categories': categories,
      'imagePaths': imagePaths,
      'reviews': reviews,
      'cleanliness_avg': cleanliness_avg,
      'waiting_time_avg': waiting_time_avg,
      'service_avg': service_avg,
      'food_quality_avg': food_quality_avg,
      'latitude': latitude,
      'longitude': longitude,
      'bookmarked': bookmarked,
    };
  }
}