import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../../core/constants/colors.dart';
import '../providers/emergency_provider.dart';
import '../../mesh/providers/mesh_provider.dart';
import '../models/radar_device.dart';
import 'compact_radar_painter.dart';
import '../screens/emergency_chat_screen.dart';

/// Emergency mode UI - black background, radar visualization, minimal UI
class EmergencyModeWidget extends StatefulWidget {
  const EmergencyModeWidget({super.key});

  @override
  State<EmergencyModeWidget> createState() => _EmergencyModeWidgetState();
}

class _EmergencyModeWidgetState extends State<EmergencyModeWidget> {
  double _userBearing = 0.0; // 0 = North (up)
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  // Smoothing values - exponential smoothing instead of moving average
  double _smoothedBearing = 0.0;
  static const double _smoothingFactor = 0.15; // Slower smoothing for stability

  // Calibration offset - adjust if compass is consistently off
  static const double _calibrationOffset = 10.0; // degrees to add/subtract

  // Throttle updates for better FPS
  DateTime _lastUpdate = DateTime.now();
  static const _updateInterval = Duration(milliseconds: 50); // 20 FPS max for compass

  // Accelerometer for tilt compensation
  double _pitch = 0.0;
  double _roll = 0.0;

  @override
  void initState() {
    super.initState();
    _startSensors();
  }

  @override
  void dispose() {
    _magnetometerSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  void _startSensors() {
    // Listen to accelerometer for tilt compensation
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        if (!mounted) return;

        // Calculate pitch and roll for tilt compensation
        _pitch = math.atan2(event.y, math.sqrt(event.x * event.x + event.z * event.z));
        _roll = math.atan2(-event.x, math.sqrt(event.y * event.y + event.z * event.z));
      },
    );

    // Listen to magnetometer events for compass bearing
    _magnetometerSubscription = magnetometerEventStream().listen(
      (MagnetometerEvent event) {
        if (!mounted) return;

        // Throttle updates to improve FPS
        final now = DateTime.now();
        if (now.difference(_lastUpdate) < _updateInterval) {
          return;
        }
        _lastUpdate = now;

        // Calculate bearing with tilt compensation
        final bearing = _calculateBearing(event.x, event.y, event.z);

        // Exponential smoothing for faster response
        if (_smoothedBearing == 0.0) {
          _smoothedBearing = bearing; // Initialize
        } else {
          // Handle wrap-around at 0°/360°
          double delta = bearing - _smoothedBearing;
          if (delta > 180) delta -= 360;
          if (delta < -180) delta += 360;

          _smoothedBearing = (_smoothedBearing + _smoothingFactor * delta) % 360;
          if (_smoothedBearing < 0) _smoothedBearing += 360;
        }

        // Update only if bearing changed significantly (> 3 degrees)
        if ((_smoothedBearing - _userBearing).abs() > 3.0) {
          setState(() {
            _userBearing = _smoothedBearing;
          });
        }
      },
      onError: (error) {
        debugPrint('Magnetometer error: $error');
      },
    );
  }

  double _calculateBearing(double mx, double my, double mz) {
    // Simplified calculation - phone held upright (portrait)
    // Android coordinate system:
    // X = right side of phone (when upright)
    // Y = top of phone
    // Z = out of screen

    // When phone is upright and pointing North:
    // - Compass Y (top) aligns with North
    // - Compass X (right) aligns with East

    // Calculate angle from North (Y-axis)
    // atan2 gives angle from positive X-axis (East)
    // We want angle from Y-axis (North), so use -X, Y
    double bearing = math.atan2(-mx, my) * (180 / math.pi);

    // Apply calibration offset
    bearing += _calibrationOffset;

    // Normalize to 0-360 range
    if (bearing < 0) bearing += 360;
    if (bearing >= 360) bearing -= 360;

    return bearing;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.emergencyBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              _buildHeader(context),
              const Spacer(flex: 2),
              _buildPulsingCircle(context),
              const SizedBox(height: 16),
              _buildStatus(context),
              const Spacer(flex: 2),
              _buildActionButtons(context),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emergency,
              color: AppColors.sosRed,
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              'EMERGENCY MODE',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.emergencyText,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Debug: show current bearing
        Text(
          'Heading: ${_userBearing.toInt()}°',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF00FF88),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPulsingCircle(BuildContext context) {
    return Consumer<MeshProvider>(
      builder: (context, meshProvider, child) {
        // Get real radar devices from mesh provider
        final radarDevices = meshProvider.getRadarDevices();

        final screenWidth = MediaQuery.of(context).size.width;
        final radarSize = (screenWidth * 0.85).clamp(200.0, 300.0);

        return RepaintBoundary(
          child: SizedBox(
            width: radarSize,
            height: radarSize,
            child: CustomPaint(
              painter: CompactRadarPainter(
                devices: radarDevices,
                userBearing: _userBearing,
                radiusRings: const [25, 50, 100], // Радиусы в метрах
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatus(BuildContext context) {
    return Consumer2<MeshProvider, EmergencyProvider>(
      builder: (context, meshProvider, emergencyProvider, child) {
        // Get actual device count from radar devices
        final radarDevices = meshProvider.getRadarDevices();
        final deviceCount = radarDevices.length;
        final duration = emergencyProvider.emergencyDuration;

        // Count devices by status
        final sosCount = radarDevices.where((d) => d.status == DeviceStatus.sos).length;
        final needHelpCount = radarDevices.where((d) => d.status == DeviceStatus.needHelp).length;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            // Large device count display
            Text(
              '$deviceCount',
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00FF88),
                height: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${deviceCount == 1 ? 'person' : 'people'} nearby',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF00FF88),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (sosCount > 0 || needHelpCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                '${sosCount > 0 ? '$sosCount SOS' : ''}${sosCount > 0 && needHelpCount > 0 ? ' • ' : ''}${needHelpCount > 0 ? '$needHelpCount need help' : ''}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFFF3366),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (duration != null) ...[
              const SizedBox(height: 8),
              Text(
                'SOS active for ${duration.inMinutes}m ${duration.inSeconds % 60}s',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF00FF88),
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Consumer2<EmergencyProvider, MeshProvider>(
      builder: (context, emergencyProvider, meshProvider, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              context,
              icon: Icons.check_circle,
              label: 'SAFE',
              color: const Color(0xFF10B981),
              onTap: () async {
                await meshProvider.sendMedicalStatus('safe');
                await emergencyProvider.deactivateEmergency();
              },
            ),
            _buildActionButton(
              context,
              icon: Icons.local_hospital,
              label: 'MEDICAL',
              color: const Color(0xFFF59E0B),
              onTap: () async {
                await meshProvider.sendMedicalStatus('injured');
              },
            ),
            _buildActionButton(
              context,
              icon: Icons.message,
              label: 'MESSAGE',
              color: const Color(0xFF3B82F6),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmergencyChatScreen(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
