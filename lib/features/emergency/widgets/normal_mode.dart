import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../providers/emergency_provider.dart';
import '../../mesh/providers/mesh_provider.dart';
import '../../hazards/providers/nasa_provider.dart';
import '../../mesh/screens/mesh_debug_screen.dart';
import '../../settings/screens/settings_screen.dart';

/// Normal mode UI - shows hazard info and SOS button
class NormalModeWidget extends StatefulWidget {
  const NormalModeWidget({super.key});

  @override
  State<NormalModeWidget> createState() => _NormalModeWidgetState();
}

class _NormalModeWidgetState extends State<NormalModeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.normalBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildStatusBar(context),
            Expanded(
              child: _buildMainContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(BuildContext context) {
    return Consumer<MeshProvider>(
      builder: (context, meshProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgTertiary,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Debug and Settings buttons (left side)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.bug_report, color: AppColors.textSecondary),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MeshDebugScreen(),
                        ),
                      );
                    },
                    tooltip: 'Mesh Debug',
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: AppColors.textSecondary),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                    tooltip: 'Settings',
                  ),
                ],
              ),
              const Text(
                'Beacon',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    Icons.devices,
                    color: meshProvider.discoveredDevices.isNotEmpty
                        ? AppColors.meshSignalStrong
                        : AppColors.meshSignalWeak,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${meshProvider.shortDeviceId}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Consumer2<NasaProvider, MeshProvider>(
      builder: (context, nasaProvider, meshProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Beacon logo/title
              Image.asset(
                'assets/logo.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 16),
              const Text(
                'Beacon',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                'Find. Survive. Together.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 48),

              // Stats cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.devices,
                      label: 'Nearby',
                      value: '${meshProvider.discoveredDevices.length}',
                      color: AppColors.meshSignalStrong,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.local_fire_department,
                      label: 'Fires',
                      value: '${nasaProvider.fires.length}',
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // SOS Button
              _buildSOSButton(context),

              const SizedBox(height: 32),

              // Status info
              if (nasaProvider.isInDangerZone)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning,
                        color: AppColors.error,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You are near an active fire zone. Stay alert.',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSButton(BuildContext context) {
    return Consumer2<EmergencyProvider, MeshProvider>(
      builder: (context, emergencyProvider, meshProvider, child) {
        return GestureDetector(
          onTap: () async {
            // Activate emergency mode
            await emergencyProvider.activateEmergency();

            // TODO: Get actual GPS coordinates
            // For now, using placeholder coordinates
            await meshProvider.broadcastSOS(
              latitude: 0.0,
              longitude: 0.0,
            );
          },
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: AppColors.sosGradient,
                    center: Alignment.topLeft,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.sosRed.withOpacity(0.4 + _pulseController.value * 0.3),
                      blurRadius: 20 + _pulseController.value * 10,
                      spreadRadius: 5 + _pulseController.value * 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emergency,
                        size: 64,
                        color: Colors.white,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'SOS',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tap to activate',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
