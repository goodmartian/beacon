import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../hazards/providers/nasa_provider.dart';
import '../../hazards/models/fire_event.dart';
import '../../../core/constants/colors.dart';

/// Map widget displaying NASA hazard data on OpenStreetMap
class HazardMap extends StatefulWidget {
  const HazardMap({super.key});

  @override
  State<HazardMap> createState() => _HazardMapState();
}

class _HazardMapState extends State<HazardMap> {
  final MapController _mapController = MapController();

  // Default center (will be updated with user location)
  LatLng _center = const LatLng(0, 0);
  double _zoom = 10.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCameraPosition();
    });
  }

  void _updateCameraPosition() {
    final nasaProvider = context.read<NasaProvider>();
    if (nasaProvider.hasLocation) {
      setState(() {
        _center = LatLng(
          nasaProvider.userLocation!.latitude,
          nasaProvider.userLocation!.longitude,
        );
      });
      _mapController.move(_center, _zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NasaProvider>(
      builder: (context, nasaProvider, child) {
        // Update center when location becomes available
        if (nasaProvider.hasLocation && _center.latitude == 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateCameraPosition();
          });
        }

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: _zoom,
                minZoom: 3,
                maxZoom: 18,
                onPositionChanged: (position, hasGesture) {
                  if (hasGesture) {
                    setState(() {
                      _center = position.center!;
                      _zoom = position.zoom!;
                    });
                  }
                },
              ),
              children: [
                // OpenStreetMap tiles
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.beacon.app',
                  maxZoom: 19,
                ),

                // Fire markers
                if (nasaProvider.fires.isNotEmpty)
                  MarkerLayer(
                    markers: _buildFireMarkers(nasaProvider.fires, nasaProvider),
                  ),

                // User location marker
                if (nasaProvider.hasLocation)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          nasaProvider.userLocation!.latitude,
                          nasaProvider.userLocation!.longitude,
                        ),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.my_location,
                          color: AppColors.accentBlue,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // Loading indicator
            if (nasaProvider.isLoading)
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgSecondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accentBlue,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Loading hazard data...',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Error message
            if (nasaProvider.errorMessage != null)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          nasaProvider.errorMessage!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Controls
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                children: [
                  // Zoom in
                  FloatingActionButton.small(
                    heroTag: 'zoom_in',
                    backgroundColor: AppColors.bgSecondary,
                    onPressed: () {
                      _mapController.move(_center, _zoom + 1);
                      setState(() => _zoom += 1);
                    },
                    child: const Icon(Icons.add, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),

                  // Zoom out
                  FloatingActionButton.small(
                    heroTag: 'zoom_out',
                    backgroundColor: AppColors.bgSecondary,
                    onPressed: () {
                      _mapController.move(_center, _zoom - 1);
                      setState(() => _zoom -= 1);
                    },
                    child: const Icon(Icons.remove, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),

                  // Center on user
                  if (nasaProvider.hasLocation)
                    FloatingActionButton.small(
                      heroTag: 'center_user',
                      backgroundColor: AppColors.bgSecondary,
                      onPressed: () {
                        final center = LatLng(
                          nasaProvider.userLocation!.latitude,
                          nasaProvider.userLocation!.longitude,
                        );
                        _mapController.move(center, 12);
                        setState(() {
                          _center = center;
                          _zoom = 12;
                        });
                      },
                      child: const Icon(
                        Icons.my_location,
                        color: AppColors.accentBlue,
                      ),
                    ),
                ],
              ),
            ),

            // Fire count badge
            if (nasaProvider.fires.isNotEmpty)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department,
                        color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${nasaProvider.fires.length} fires',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  List<Marker> _buildFireMarkers(List<FireEvent> fires, NasaProvider provider) {
    return fires.map((fire) {
      // Calculate distance if user location available
      double? distance;
      if (provider.hasLocation) {
        distance = fire.distanceFromUser(
          provider.userLocation!.latitude,
          provider.userLocation!.longitude,
        );
      }

      // Color based on confidence
      Color markerColor;
      switch (fire.confidence) {
        case 'high':
          markerColor = const Color(0xFFE74C3C); // Bright red
          break;
        case 'nominal':
          markerColor = const Color(0xFFF39C12); // Orange
          break;
        default:
          markerColor = const Color(0xFFF39C12).withOpacity(0.6); // Light orange
      }

      return Marker(
        point: LatLng(fire.latitude, fire.longitude),
        width: 30,
        height: 30,
        child: GestureDetector(
          onTap: () => _showFireInfo(fire, distance),
          child: Container(
            decoration: BoxDecoration(
              color: markerColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: markerColor.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      );
    }).toList();
  }

  void _showFireInfo(FireEvent fire, double? distance) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: AppColors.error,
                  size: 32,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Fire Detected',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Confidence', fire.confidence.toUpperCase()),
            _buildInfoRow('Brightness', '${fire.brightness.toStringAsFixed(1)}K'),
            _buildInfoRow('Power (FRP)', '${fire.frp.toStringAsFixed(1)} MW'),
            if (distance != null)
              _buildInfoRow('Distance', '${distance.toStringAsFixed(1)} km'),
            _buildInfoRow(
              'Detected',
              fire.formattedAcqTime,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
