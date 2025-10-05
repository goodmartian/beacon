import 'dart:ui';
import 'dart:math' as math;

/// Device status for radar visualization
enum DeviceStatus {
  safe,      // Green dot
  needHelp,  // Yellow/amber dot
  sos,       // Red pulsing dot
  relay,     // Cyan dot (mesh relay)
}

/// Represents a device on the radar display
class RadarDevice {
  final String id;
  final double distance;      // meters from user
  final double bearing;       // degrees from north (0-360)
  final DeviceStatus status;
  final double signalStrength; // 0.0-1.0
  final DateTime lastSeen;
  final String? name;

  const RadarDevice({
    required this.id,
    required this.distance,
    required this.bearing,
    required this.status,
    required this.signalStrength,
    required this.lastSeen,
    this.name,
  });

  /// Convert polar coordinates (distance, bearing) to Cartesian (x, y)
  /// relative to radar center
  Offset toCartesian(double radarRadius, double maxDistance) {
    final normalizedDistance = (distance / maxDistance).clamp(0.0, 1.0);
    final radiusPixels = normalizedDistance * radarRadius;

    // Convert bearing to radians (0° = North = up)
    // Subtract 90° to align with typical coordinate system
    final angleRadians = (bearing - 90) * (math.pi / 180);

    final x = radiusPixels * math.cos(angleRadians);
    final y = radiusPixels * math.sin(angleRadians);

    return Offset(x, y);
  }

  /// Get color for device status
  Color getColor() {
    switch (status) {
      case DeviceStatus.safe:
        return const Color(0xFF00FF88);      // Bright green
      case DeviceStatus.needHelp:
        return const Color(0xFFFFB800);      // Amber
      case DeviceStatus.sos:
        return const Color(0xFFFF3366);      // Red
      case DeviceStatus.relay:
        return const Color(0xFF00D9FF);      // Cyan
    }
  }

  /// Get dot size based on signal strength
  double getDotSize() {
    return 8.0 + (signalStrength * 8.0); // 8-16 pixels
  }

  /// Whether this device should pulse (SOS only)
  bool shouldPulse() => status == DeviceStatus.sos;
}
