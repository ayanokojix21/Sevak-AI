import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/volunteer.dart';

/// Riverpod provider for the UserRepository
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(FirebaseFirestore.instance);
});

/// Handles reading and writing Volunteer profiles to Firestore.
class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository(this._firestore);

  /// Saves a new volunteer profile or updates an existing one.
  Future<void> saveVolunteerProfile(Volunteer volunteer) async {
    try {
      await _firestore
          .collection(AppConstants.volunteersCollection)
          .doc(volunteer.uid)
          .set(volunteer.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw const DatabaseFailure('Failed to save user profile to database.');
    }
  }

  /// Fetches a volunteer profile by UID. Returns null if not found.
  Future<Volunteer?> getVolunteerProfile(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.volunteersCollection)
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return Volunteer.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw const DatabaseFailure('Failed to fetch user profile from database.');
    }
  }
}
