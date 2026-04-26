import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../providers/live_tracking_providers.dart';
import '../../../needs/domain/entities/need_entity.dart';

class LiveTrackingPage extends ConsumerStatefulWidget {
  final NeedEntity need;

  const LiveTrackingPage({super.key, required this.need});

  @override
  ConsumerState<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends ConsumerState<LiveTrackingPage> {
  late final MapController _mapController;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // Determine safe initial map center
  LatLng get _safeCenter {
    if (widget.need.lat != 0.0 || widget.need.lng != 0.0) {
      return LatLng(widget.need.lat, widget.need.lng);
    }
    // Default to India center if no coords
    return const LatLng(20.5937, 78.9629);
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(liveTrackingProvider(widget.need));
    final vol = trackingState.volunteer;
    final volHasLocation = vol != null && vol.currentLat != 0.0;

    // Auto-pan map when volunteer location updates
    if (_mapReady && volHasLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && trackingState.routePoints.isEmpty) {
          _mapController.move(LatLng(vol.currentLat, vol.currentLng), 14);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        backgroundColor: AppColors.bgSurface,
        actions: [
          if (trackingState.isLoadingRoute)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _safeCenter,
              initialZoom: 13.0,
              onMapReady: () => setState(() => _mapReady = true),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sevakai.sevak_app',
                maxZoom: 19,
              ),
              // Route polyline
              if (trackingState.routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: trackingState.routePoints,
                      strokeWidth: 5.0,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Destination marker (only if coords available)
                  if (widget.need.lat != 0.0 || widget.need.lng != 0.0)
                    Marker(
                      point: LatLng(widget.need.lat, widget.need.lng),
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on, color: AppColors.error, size: 40),
                    ),
                  // Volunteer marker (only if location is valid)
                  if (volHasLocation)
                    Marker(
                      point: LatLng(vol.currentLat, vol.currentLng),
                      width: 52,
                      height: 52,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.directions_run, color: AppColors.primary, size: 26),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildInfoBanner(trackingState),
          ),

          if (trackingState.errorMessage != null)
            Positioned(
              bottom: 90,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(230),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trackingState.errorMessage!,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        heroTag: 'live_track_fab',
        onPressed: () {
          if (!_mapReady) return;
          final points = <LatLng>[];
          if (widget.need.lat != 0.0 || widget.need.lng != 0.0) {
            points.add(LatLng(widget.need.lat, widget.need.lng));
          }
          if (volHasLocation) {
            points.add(LatLng(vol.currentLat, vol.currentLng));
          }
          if (trackingState.routePoints.isNotEmpty) {
            points.addAll(trackingState.routePoints);
          }
          if (points.length >= 2) {
            final bounds = LatLngBounds.fromPoints(points);
            _mapController.fitCamera(
              CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
            );
          } else if (points.length == 1) {
            _mapController.move(points.first, 14);
          }
        },
        backgroundColor: AppColors.bgSurface,
        foregroundColor: AppColors.primary,
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }

  Widget _buildInfoBanner(LiveTrackingState state) {
    final vol = state.volunteer;

    if (vol == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              state.errorMessage ?? 'Waiting for volunteer assignment...',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final distanceText = state.distanceMeters > 0
        ? '${(state.distanceMeters / 1000).toStringAsFixed(1)} km away  •  ~${(state.durationSeconds / 60).round()} min ETA'
        : (state.isLoadingRoute
            ? 'Calculating route...'
            : (vol.currentLat == 0.0 ? 'Waiting for volunteer location...' : 'Volunteer is nearby'));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withAlpha(50),
            child: Text(
              vol.name.isNotEmpty ? vol.name.substring(0, 1).toUpperCase() : '?',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        vol.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    // Live indicator dot
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('Live', style: TextStyle(fontSize: 11, color: AppColors.success)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  distanceText,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
