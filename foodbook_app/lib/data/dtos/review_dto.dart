import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodbook_app/data/dtos/category_dto.dart';
import 'package:foodbook_app/data/models/category.dart';
import 'package:foodbook_app/data/models/review.dart';
import 'package:intl/intl.dart';
// import 'package:intl/intl.dart'; 

class ReviewDTO {
  final String user;
  final String title;
  final String content;
  final Timestamp date;
  final String? imageUrl;
  final Map<String, double> ratings;
  final List<String> selectedCategories;

  ReviewDTO({
    required this.user,
    required this.title,
    required this.content,
    required this.date,
    required this.imageUrl,
    required this.ratings,
    required this.selectedCategories,
  });

  factory ReviewDTO.fromModel(Review review) {
    return ReviewDTO(
      user: review.user,
      title: review.title,
      content: review.content,
      // date: DateFormat('yyyy-MM-dd').format(review.date),
      date: review.date,
      imageUrl: review.imageUrl,
      ratings: review.ratings,
      selectedCategories: review.selectedCategories,
    );
  }

  Review toModel() {
    return Review(
      user: user,
      title: title,
      content: content,
      date: date,
      // date: date,
      imageUrl: imageUrl,
      ratings: ratings,
      selectedCategories: selectedCategories,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user,
      'title': title,
      'content': content,
      'date': date,
      'imageUrl': imageUrl,
      'ratings': ratings,
      'selectedCategories': selectedCategories.map((category) => category).toList(),
    };
  }

  static ReviewDTO fromJson(Map<String, dynamic> json) {
    var selectedCategoriesJson = json['selectedCategories'] as List<dynamic>;
    return ReviewDTO(
      user: json['user'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      date: json['date'],
      imageUrl: json['imageUrl'] as String,
      ratings: Map<String, double>.from(json['ratings']),
      selectedCategories: selectedCategoriesJson.map((catJson) => CategoryDTO.fromJson(catJson).toString()).toList(),
    );
  }
}
