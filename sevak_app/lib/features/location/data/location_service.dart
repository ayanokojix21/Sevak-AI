import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_constants.dart';

/// Lightweight location service used by WorkManager (periodic) and on-demand.
class LocationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Prevents the foreground startup sync from firing more than once per session.
  // Set back to false on failure so retry happens next time.
  static bool _foregroundSyncDone = false;

  /// Reset the foreground sync flag — call this on logout so next login
  /// triggers a fresh location update.
  static void resetSyncState() => _foregroundSyncDone = false;


  /// Returns true if GPS hardware is enabled.
  static Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  /// Returns true if the app has been granted at least WhileInUse permission.
  static Future<bool> hasLocationPermission() async {
    final perm = await Geolocator.checkPermission();
    return perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always;
  }

  /// Requests location permission. Returns the updated permission status.
  static Future<LocationPermission> requestLocationPermission() =>
      Geolocator.requestPermission();

  /// Opens the device location settings page (so user can enable GPS).
  static Future<void> openDeviceLocationSettings() =>
      Geolocator.openLocationSettings();

  /// Opens the app permission settings page.
  static Future<void> openAppPermissionSettings() =>
      Geolocator.openAppSettings();


  /// Gets current GPS position and saves it to the volunteer's Firestore doc.
  ///
  /// Returns `true` if location was successfully updated.
  /// [force] bypasses the single-session dedup guard (used by WorkManager).
  Future<bool> updateVolunteerLocation(String volunteerUid,
      {bool force = false}) async {
    if (!force && _foregroundSyncDone) return false;

    try {
      // Step 1: Check permission
      LocationPermission permission = await Geolocator.checkPermission();

      // Step 2: Request only if denied (not denied forever)
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // Bail if permanently denied
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Permission denied ($permission) — cannot update location.');
        return false;
      }

      // Step 3: Check GPS hardware is on
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] Location services disabled on device.');
        return false;
      }

      // Mark done before the async GPS call to avoid duplicate calls
      if (!force) _foregroundSyncDone = true;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, // upgraded from medium for matching
          timeLimit: Duration(seconds: 15),
        ),
      );

      await _db
          .collection(AppConstants.volunteersCollection)
          .doc(volunteerUid)
          .update({
        'currentLat': position.latitude,
        'currentLng': position.longitude,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[LocationService] ✅ Updated location for $volunteerUid: '
          '${position.latitude}, ${position.longitude}');
      return true;
    } catch (e) {
      debugPrint('[LocationService] Error updating location: $e');
      if (!force) _foregroundSyncDone = false; // Allow retry
      return false;
    }
  }
  static StreamSubscription<Position>? _liveTrackingSub;

  /// Starts continuous location streaming when a volunteer has an active task.
  /// Updates Firestore only when the volunteer moves > 10 meters.
  void startLiveTracking(String volunteerUid) async {
    if (_liveTrackingSub != null) return; // Already streaming
    
    debugPrint('[LocationService] 🟢 Starting Live Location Tracking for $volunteerUid');
    
    // Ensure permission & GPS first
    final hasPerm = await hasLocationPermission();
    final isGpsOn = await isLocationServiceEnabled();
    if (!hasPerm || !isGpsOn) {
      debugPrint('[LocationService] Cannot start live tracking — missing perm or GPS.');
      return;
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 10, // only update every 10 meters of movement
    );

    _liveTrackingSub = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) async {
      try {
        await _db
            .collection(AppConstants.volunteersCollection)
            .doc(volunteerUid)
            .update({
          'currentLat': position.latitude,
          'currentLng': position.longitude,
          'locationUpdatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[LocationService] 📍 Live Track Update: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        debugPrint('[LocationService] Live Track Update Failed: $e');
      }
    });
  }

  /// Stops the live location stream when the task is complete/declined.
  void stopLiveTracking() {
    if (_liveTrackingSub != null) {
      debugPrint('[LocationService] 🔴 Stopping Live Location Tracking');
      _liveTrackingSub?.cancel();
      _liveTrackingSub = null;
    }
  }
}
