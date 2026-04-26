import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'auth_providers.dart';
import '../features/auth/domain/entities/volunteer.dart';
import '../features/location/data/osrm_datasource.dart';
import '../features/needs/domain/entities/need_entity.dart';

final osrmDatasourceProvider = Provider((ref) => OsrmDatasource());

class LiveTrackingState {
  final Volunteer? volunteer;
  final List<LatLng> routePoints;
  final double distanceMeters;
  final double durationSeconds;
  final bool isLoadingRoute;
  final String? errorMessage;

  LiveTrackingState({
    this.volunteer,
    this.routePoints = const [],
    this.distanceMeters = 0.0,
    this.durationSeconds = 0.0,
    this.isLoadingRoute = false,
    this.errorMessage,
  });

  LiveTrackingState copyWith({
    Volunteer? volunteer,
    List<LatLng>? routePoints,
    double? distanceMeters,
    double? durationSeconds,
    bool? isLoadingRoute,
    String? errorMessage,
  }) {
    return LiveTrackingState(
      volunteer: volunteer ?? this.volunteer,
      routePoints: routePoints ?? this.routePoints,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isLoadingRoute: isLoadingRoute ?? this.isLoadingRoute,
      errorMessage: errorMessage,
    );
  }
}

class LiveTrackingController extends StateNotifier<LiveTrackingState> {
  final Ref _ref;
  final NeedEntity _need;
  StreamSubscription<Volunteer?>? _volunteerSub;
  Timer? _routeRefreshTimer;

  LiveTrackingController(this._ref, this._need) : super(LiveTrackingState()) {
    _init();
  }

  void _init() {
    // Resolve volunteer UID: prefer assignedTo, then first of assignedVolunteerIds
    final volunteerUid = (_need.assignedTo != null && _need.assignedTo!.isNotEmpty)
        ? _need.assignedTo!
        : (_need.assignedVolunteerIds.isNotEmpty ? _need.assignedVolunteerIds.first : null);

    if (volunteerUid == null || volunteerUid.isEmpty) {
      debugPrint('[LiveTracking] No assigned volunteer UID found.');
      state = state.copyWith(errorMessage: 'No volunteer assigned yet.');
      return;
    }

    debugPrint('[LiveTracking] Watching volunteer: $volunteerUid');

    // Subscribe to real-time volunteer location stream
    _volunteerSub = _ref
        .read(userRepositoryProvider)
        .streamVolunteerProfile(volunteerUid)
        .listen((volunteer) {
      if (!mounted) return;

      final prevLat = state.volunteer?.currentLat;
      final prevLng = state.volunteer?.currentLng;
      state = state.copyWith(volunteer: volunteer);

      // Fetch route if volunteer has a valid location
      if (volunteer != null &&
          volunteer.currentLat != 0.0 &&
          volunteer.currentLng != 0.0) {
        // Only re-fetch route if volunteer moved significantly OR first load
        final moved = prevLat != volunteer.currentLat || prevLng != volunteer.currentLng;
        if (moved || state.routePoints.isEmpty) {
          _fetchRoute(volunteer);
        }
      }
    });

    // Also periodically refresh route every 30 seconds for live feel
    _routeRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      final v = state.volunteer;
      if (v != null && v.currentLat != 0.0 && v.currentLng != 0.0) {
        _fetchRoute(v);
      }
    });
  }

  Future<void> _fetchRoute(Volunteer volunteer) async {
    if (!mounted) return;

    // Guard: need must have valid destination coordinates
    if (_need.lat == 0.0 && _need.lng == 0.0) {
      debugPrint('[LiveTracking] Need has no destination coordinates — skipping route fetch.');
      return;
    }

    state = state.copyWith(isLoadingRoute: true, errorMessage: null);
    try {
      final start = LatLng(volunteer.currentLat, volunteer.currentLng);
      final end = LatLng(_need.lat, _need.lng);

      debugPrint('[LiveTracking] Fetching route: ${start.latitude},${start.longitude} → ${end.latitude},${end.longitude}');

      final routeData = await _ref.read(osrmDatasourceProvider).getRoute(start, end);

      if (mounted) {
        state = state.copyWith(
          routePoints: routeData['points'] as List<LatLng>,
          distanceMeters: (routeData['distance'] as num).toDouble(),
          durationSeconds: (routeData['duration'] as num).toDouble(),
          isLoadingRoute: false,
        );
        debugPrint('[LiveTracking] Route fetched: ${state.distanceMeters.toStringAsFixed(0)}m, ${state.durationSeconds.toStringAsFixed(0)}s');
      }
    } catch (e) {
      debugPrint('[LiveTracking] Route fetch failed: $e');
      if (mounted) {
        state = state.copyWith(
          isLoadingRoute: false,
          errorMessage: 'Could not calculate route. Showing live position only.',
        );
      }
    }
  }

  @override
  void dispose() {
    _volunteerSub?.cancel();
    _routeRefreshTimer?.cancel();
    super.dispose();
  }
}

final liveTrackingProvider =
    StateNotifierProvider.family<LiveTrackingController, LiveTrackingState, NeedEntity>(
        (ref, need) {
  return LiveTrackingController(ref, need);
});
