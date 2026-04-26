import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/volunteer.dart';



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

  /// Real-time stream of a volunteer profile. Used by StreamProvider.
  Stream<Volunteer?> streamVolunteerProfile(String uid) {
    return _firestore
        .collection(AppConstants.volunteersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return Volunteer.fromJson(doc.data()!, doc.id);
      }
      return null;
    });
  }

  /// Streams the list of Coordinators and NGO Admins for a specific NGO.
  Stream<List<Volunteer>> streamNgoStaff(String ngoId) {
    return _firestore
        .collection(AppConstants.volunteersCollection)
        .where('primaryNgoId', isEqualTo: ngoId)
        .where('platformRole', whereIn: ['CO', 'NA'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Volunteer.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Streams ALL members (including volunteers) for a specific NGO.
  Stream<List<Volunteer>> streamNgoMembers(String ngoId) {
    return _firestore
        .collection(AppConstants.volunteersCollection)
        .where('primaryNgoId', isEqualTo: ngoId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Volunteer.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Updates only the cross-NGO consent flag for a volunteer.
  Future<void> updateCrossNgoConsent(String uid, bool consent) async {
    await _firestore
        .collection(AppConstants.volunteersCollection)
        .doc(uid)
        .update({'isAvailable': consent});
  }

  /// Removes a volunteer from an NGO. If they have no other NGOs, they become a CU.
  Future<void> removeNgoMembership(String uid, String ngoId) async {
    final doc = await _firestore.collection(AppConstants.volunteersCollection).doc(uid).get();
    if (!doc.exists || doc.data() == null) return;
    
    final volunteer = Volunteer.fromJson(doc.data()!, doc.id);
    
    // Remove the membership
    final updatedMemberships = volunteer.ngoMemberships.where((m) => m.ngoId != ngoId).toList();
    
    // If primary NGO is removed, assign a new one or clear it
    String newPrimaryNgoId = volunteer.primaryNgoId;
    if (newPrimaryNgoId == ngoId) {
      newPrimaryNgoId = updatedMemberships.isNotEmpty ? updatedMemberships.first.ngoId : '';
    }
    
    // If they have no NGOs left, they revert to a Community User
    String newRole = volunteer.platformRole;
    if (updatedMemberships.isEmpty) {
      newRole = 'CU';
    } else if (volunteer.primaryNgoId == ngoId && (newRole == 'CO' || newRole == 'NA')) {
      // If they were admin/coordinator of the removed NGO, revert to VL for the fallback NGO
      // unless we want to keep their role, but safe default is VL
      newRole = 'VL'; 
    }

    final updatedVolunteer = volunteer.copyWith(
      ngoMemberships: updatedMemberships,
      primaryNgoId: newPrimaryNgoId,
      platformRole: newRole,
    );

    await saveVolunteerProfile(updatedVolunteer);
  }
}
