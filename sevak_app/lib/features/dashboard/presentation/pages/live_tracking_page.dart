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

  LatLng get _safeCenter {
    if (widget.need.lat != 0.0 || widget.need.lng != 0.0) {
      return LatLng(widget.need.lat, widget.need.lng);
    }
    return const LatLng(20.5937, 78.9629); // India center default
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final trackingState = ref.watch(liveTrackingProvider(widget.need));
    final vol = trackingState.volunteer;
    final volHasLocation = vol != null && vol.currentLat != 0.0;

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
              if (trackingState.routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: trackingState.routePoints,
                      strokeWidth: 5.0,
                      color: cs.primary,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (widget.need.lat != 0.0 || widget.need.lng != 0.0)
                    Marker(
                      point: LatLng(widget.need.lat, widget.need.lng),
                      width: 40,
                      height: 40,
                      child: Icon(Icons.location_on_rounded,
                          color: cs.error, size: 40),
                    ),
                  if (volHasLocation)
                    Marker(
                      point: LatLng(vol.currentLat, vol.currentLng),
                      width: 52,
                      height: 52,
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.primary, width: 3),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 2))
                          ],
                        ),
                        child: Center(
                          child: Icon(Icons.directions_run_rounded,
                              color: cs.onPrimaryContainer, size: 26),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Info banner
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildInfoBanner(trackingState, cs, tt),
          ),

          // Error/warning banner
          if (trackingState.errorMessage != null)
            Positioned(
              bottom: 90,
              left: 16,
              right: 16,
              child: Card(
                color: SevakColors.warning.withAlpha(230),
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          trackingState.errorMessage!,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
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
              CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(60)),
            );
          } else if (points.length == 1) {
            _mapController.move(points.first, 14);
          }
        },
        child: const Icon(Icons.center_focus_strong_rounded),
      ),
    );
  }

  Widget _buildInfoBanner(
      LiveTrackingState state, ColorScheme cs, TextTheme tt) {
    final vol = state.volunteer;

    if (vol == null) {
      return Card(
        color: cs.surfaceContainerHigh,
        elevation: 3,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  state.errorMessage ?? 'Waiting for volunteer assignment...',
                  style:
                      tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final distanceText = state.distanceMeters > 0
        ? '${(state.distanceMeters / 1000).toStringAsFixed(1)} km away  •  ~${(state.durationSeconds / 60).round()} min ETA'
        : (state.isLoadingRoute
            ? 'Calculating route...'
            : (vol.currentLat == 0.0
                ? 'Waiting for volunteer location...'
                : 'Volunteer is nearby'));

    return Card(
      color: cs.surfaceContainerHigh,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: cs.primaryContainer,
              child: Text(
                vol.name.isNotEmpty
                    ? vol.name.substring(0, 1).toUpperCase()
                    : '?',
                style: TextStyle(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.bold),
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
                        child: Text(vol.name,
                            style: tt.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      // Live indicator
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: SevakColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('Live',
                          style: tt.labelSmall
                              ?.copyWith(color: SevakColors.success)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(distanceText,
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
