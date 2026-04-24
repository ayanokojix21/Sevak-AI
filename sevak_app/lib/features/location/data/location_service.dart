import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Lightweight location service used by WorkManager (periodic) and on-demand.
class LocationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Gets current GPS position and saves it to the volunteer's Firestore doc.
  Future<void> updateVolunteerLocation(String volunteerUid) async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Permission denied');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      await _db.collection('volunteers').doc(volunteerUid).update({
        'lat': position.latitude,
        'lng': position.longitude,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint(
          '[LocationService] Updated location for $volunteerUid: '
          '${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('[LocationService] Error: $e');
    }
  }
}
