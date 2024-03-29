import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodbook_app/data/dtos/review_dto.dart';
import 'package:foodbook_app/data/models/review.dart';

class ReviewRepository {
  final _fireCloud = FirebaseFirestore.instance.collection("reviews");

  Future<String> create({ required ReviewDTO review }) async {
    try {
      DocumentReference reviewRef = await _fireCloud.add(review.toJson());
      return reviewRef.id;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print("Failed with error '${e.code}': ${e.message}");
      }
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: "Failed to add review: '${e.code}': ${e.message}"
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future getReviewById(String id) async {
    try {
      DocumentSnapshot review = await _fireCloud.doc(id).get();
      return review.data();
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print("Failed with error '${e.code}': ${e.message}");
      }
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: "Failed to get review: '${e.code}': ${e.message}"
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<List<Review>> fetchReviews(List<String> reviewIds) async {
    List<Review> reviews = [];
    print('REVIEW IDS: $reviewIds');
    for (String id in reviewIds) {
      var reviewData = await getReviewById(id);
      print('REVIEW DATA: $reviewData');
      if (reviewData != null) {
        ReviewDTO reviewDTO = ReviewDTO.fromJson(reviewData);
        reviews.add(reviewDTO.toModel());
      }
    }
    return reviews;
  }

  Future<String> saveImage(File image) async {
    Reference referenceRoot = FirebaseStorage.instance.ref();
    Reference referenceDirImages = referenceRoot.child('reviewImages');

    String uniqueFileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
    Reference referenceImageToUpload = referenceDirImages.child(uniqueFileName);

    SettableMetadata metadata = SettableMetadata(
      contentType: 'image/jpeg',
    );

    try {
      await referenceImageToUpload.putFile(File(image.path), metadata);
      String path = await referenceImageToUpload.getDownloadURL();
      return path;
    } catch(error) {
      if (kDebugMode) {
        print("Failed to save image with error: $error");
      }
      throw Exception("Failed to save image: $error");
    }
  }

  Future<ImageProvider> getImage(String fullPath) async {
    final ref = FirebaseStorage.instance.ref().child(fullPath);
    final String downloadUrl = await ref.getDownloadURL();
    return NetworkImage(downloadUrl);
  }
}
