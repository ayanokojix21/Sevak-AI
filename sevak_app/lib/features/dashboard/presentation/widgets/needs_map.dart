import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../needs/domain/entities/need_entity.dart';

/// Interactive map displaying needs as color-coded pins.
/// Uses flutter_map + OpenStreetMap (free, no API key).
/// Marker clustering prevents overlap in high-density areas.
class NeedsMap extends StatefulWidget {
  final List<NeedEntity> needs;
  final NeedEntity? selectedNeed;
  final ValueChanged<NeedEntity> onNeedTapped;

  const NeedsMap({
    super.key,
    required this.needs,
    this.selectedNeed,
    required this.onNeedTapped,
  });

  @override
  State<NeedsMap> createState() => _NeedsMapState();
}

class _NeedsMapState extends State<NeedsMap> {
  final MapController _mapController = MapController();
  bool _mapReady = false;

  @override
  Widget build(BuildContext context) {
    // Default center: India (Lucknow) if no needs have coordinates
    final centerLat = widget.needs.isNotEmpty
        ? widget.needs
                .where((n) => n.lat != 0.0)
                .fold<double>(0, (sum, n) => sum + n.lat) /
            (widget.needs.where((n) => n.lat != 0.0).length.clamp(1, 9999))
        : 26.8467;
    final centerLng = widget.needs.isNotEmpty
        ? widget.needs
                .where((n) => n.lng != 0.0)
                .fold<double>(0, (sum, n) => sum + n.lng) /
            (widget.needs.where((n) => n.lng != 0.0).length.clamp(1, 9999))
        : 80.9462;

    final markers = widget.needs
        .where((n) => n.lat != 0.0 && n.lng != 0.0)
        .map((need) => _buildMarker(need))
        .toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(centerLat, centerLng),
              initialZoom: 11.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              onMapReady: () => setState(() => _mapReady = true),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // OSM Tile Layer — free, no API key needed
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sevakai.sevak_app',
                maxZoom: 19,
              ),

              // Marker Cluster Layer for high-density areas
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 80,
                  size: const Size(48, 48),
                  markers: markers,
                  builder: (context, clusterMarkers) {
                    // Determine cluster color by highest urgency in cluster
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withAlpha(204),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(102),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          clusterMarkers.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Map unavailable fallback overlay
          if (!_mapReady && markers.isEmpty)
            Container(
              color: AppColors.bgSurface,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined, size: 48, color: AppColors.textDisabled),
                    SizedBox(height: 12),
                    Text(
                      'Loading map...',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),

          // Zoom controls
          Positioned(
            right: 12,
            bottom: 12,
            child: Column(
              children: [
                _MapButton(
                  icon: Icons.add,
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      (currentZoom + 1).clamp(3.0, 18.0),
                    );
                  },
                ),
                const SizedBox(height: 4),
                _MapButton(
                  icon: Icons.remove,
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      (currentZoom - 1).clamp(3.0, 18.0),
                    );
                  },
                ),
                const SizedBox(height: 4),
                _MapButton(
                  icon: Icons.center_focus_strong,
                  onPressed: () {
                    if (widget.needs.isNotEmpty) {
                      _mapController.move(
                        LatLng(centerLat, centerLng),
                        11.0,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Marker _buildMarker(NeedEntity need) {
    final color = AppTheme.urgencyColor(need.urgencyScore);
    final isSelected = widget.selectedNeed?.id == need.id;

    return Marker(
      point: LatLng(need.lat, need.lng),
      width: isSelected ? 48 : 40,
      height: isSelected ? 48 : 40,
      child: GestureDetector(
        onTap: () {
          widget.onNeedTapped(need);
          // Animate to selected pin
          _mapController.move(LatLng(need.lat, need.lng), 14.0);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withAlpha(isSelected ? 255 : 204),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white70,
              width: isSelected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(isSelected ? 153 : 76),
                blurRadius: isSelected ? 12 : 6,
                spreadRadius: isSelected ? 3 : 1,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              _needTypeIcon(need.needType),
              color: Colors.white,
              size: isSelected ? 22 : 18,
            ),
          ),
        ),
      ),
    );
  }

  IconData _needTypeIcon(String needType) {
    switch (needType) {
      case 'FOOD':
        return Icons.restaurant_rounded;
      case 'MEDICAL':
        return Icons.local_hospital_rounded;
      case 'SHELTER':
        return Icons.home_rounded;
      case 'CLOTHING':
        return Icons.checkroom_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _MapButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgElevated.withAlpha(230),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
