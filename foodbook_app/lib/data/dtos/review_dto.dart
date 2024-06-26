import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodbook_app/data/models/review.dart';
// import 'package:intl/intl.dart'; 

class ReviewDTO {
  final Map<String, String> user;
  final String? title;
  final String? content;
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
    Map<String, double> ratings = {};
    json['ratings']?.forEach((key, value) {
      ratings[key] = (value as num).toDouble();
    });

    Map<String, String> userData = {'id': json['user']['id'], 'name': json['user']['name']};

    return ReviewDTO(
      user: userData,
      title: json['title'],
      content: json['content'],
      date: json['date'] as Timestamp,
      imageUrl: json['imageUrl'],
      ratings: ratings,
      selectedCategories: List<String>.from(json['selectedCategories'] ?? []),
    );
  }
  
  Map<String, dynamic> toJsonCache() {
    return {
      'user': user,
      'title': title,
      'content': content,
      'date': {'seconds': date.seconds, 'nanoseconds': date.nanoseconds},
      'imageUrl': imageUrl,
      'ratings': ratings,
      'selectedCategories': selectedCategories.map((category) => category).toList(),
    };
  }
  static ReviewDTO fromJsonCache(Map<String, dynamic> json) {
    Map<String, double> ratings = {};
    json['ratings']?.forEach((key, value) {
      ratings[key] = (value as num).toDouble();
    });

    Map<String, String> userData = {'id': json['user']['id'], 'name': json['user']['name']};

    return ReviewDTO(
      user: userData,
      title: json['title'],
      content: json['content'],
      date: Timestamp(json['date']['seconds'], json['date']['nanoseconds']),
      imageUrl: json['imageUrl'],
      ratings: ratings,
      selectedCategories: List<String>.from(json['selectedCategories'] ?? []),
    );
  }

}
