import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../emergency/models/radar_device.dart';

/// Compact radar painter for emergency mode center display
class CompactRadarPainter extends CustomPainter {
  final List<RadarDevice> devices;
  final double userBearing;
  final List<double> radiusRings; // Радиусы в метрах для каждого круга

  CompactRadarPainter({
    required this.devices,
    this.userBearing = 0.0,
    this.radiusRings = const [25, 50, 100], // По умолчанию: 25м, 50м, 100м
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background removed - transparent

    // Calculate max radius from rings (последний круг = 100% радиуса)
    final maxRadiusMeters = radiusRings.isNotEmpty ? radiusRings.last : 100.0;

    // Draw concentric rings based on configured radiuses
    for (int i = 0; i < radiusRings.length; i++) {
      final radiusMeters = radiusRings[i];
      final ringRadius = radius * (radiusMeters / maxRadiusMeters);

      final ringPaint = Paint()
        ..color = const Color(0xFF00FF88).withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(center, ringRadius, ringPaint);

      // Draw radius label at top (0°) to avoid collision with degree markers
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${radiusMeters.toInt()}m',
          style: const TextStyle(
            fontSize: 9,
            color: Color(0xFF00FF88),
            fontWeight: FontWeight.w400,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(center.dx - textPainter.width / 2, center.dy - ringRadius - 12),
      );
    }

    // Draw grid lines (8 lines radiating from center)
    final gridPaint = Paint()
      ..color = const Color(0xFF00FF88).withOpacity(0.08)
      ..strokeWidth = 1;

    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * (math.pi / 180);
      final endX = center.dx + radius * math.cos(angle - math.pi / 2);
      final endY = center.dy + radius * math.sin(angle - math.pi / 2);
      canvas.drawLine(center, Offset(endX, endY), gridPaint);
    }

    // Draw user direction cone (field of view)
    final conePaint = Paint()
      ..color = const Color(0xFF00FF88).withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final coneAngle = 75 * (math.pi / 180);
    final bearingRad = (userBearing - 90) * (math.pi / 180);

    final path = Path();
    path.moveTo(center.dx, center.dy);
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      bearingRad - coneAngle / 2,
      coneAngle,
      false,
    );
    path.close();
    canvas.drawPath(path, conePaint);

    // Draw real device dots based on actual positions
    for (final device in devices) {
      // Convert polar coordinates to cartesian
      final devicePosition = device.toCartesian(radius, maxRadiusMeters);
      final dotX = center.dx + devicePosition.dx;
      final dotY = center.dy + devicePosition.dy;

      // Get device-specific color and size
      final deviceColor = device.getColor();
      final dotSize = 3.0 + (device.signalStrength * 2.0); // 3-5 pixels

      // Glow effect (stronger for SOS)
      final glowSize = device.status == DeviceStatus.sos ? 8.0 : 6.0;
      final glowPaint = Paint()
        ..color = deviceColor.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(dotX, dotY), glowSize, glowPaint);

      // Main dot
      final dotPaint = Paint()
        ..color = deviceColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(dotX, dotY), dotSize, dotPaint);

      // SOS pulse ring
      if (device.status == DeviceStatus.sos) {
        final pulsePaint = Paint()
          ..color = deviceColor.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(Offset(dotX, dotY), glowSize + 3, pulsePaint);
      }
    }

    // Draw center dot (user position)
    final centerGlowPaint = Paint()
      ..color = const Color(0xFF00FF88).withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, 10, centerGlowPaint);

    final centerDotPaint = Paint()
      ..color = const Color(0xFF00FF88)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6, centerDotPaint);

    final centerHighlightPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2, centerHighlightPaint);

    // Draw degree markers every 30° around the radar
    for (int deg = 0; deg < 360; deg += 30) {
      // Only arrow for North (0°), no text labels
      String label = deg == 0 ? '' : '$deg°';
      _drawDirectionMarker(canvas, center, radius, deg.toDouble(), label);
    }

    // Outer ring border removed
  }

  /// Draw direction marker with degrees
  void _drawDirectionMarker(
    Canvas canvas,
    Offset center,
    double radius,
    double degrees,
    String label,
  ) {
    // Convert degrees to radians (0° = North = up)
    final angleRadians = (degrees - 90) * (math.pi / 180);

    // Position outside the radar circle
    final markerRadius = radius + 18;
    final x = center.dx + markerRadius * math.cos(angleRadians);
    final y = center.dy + markerRadius * math.sin(angleRadians);

    // Check if this is a cardinal direction
    final isCardinal = degrees == 0 || degrees == 90 || degrees == 180 || degrees == 270;

    // Draw arrow for North only
    if (degrees == 0) {
      final arrowPaint = Paint()
        ..color = const Color(0xFF00FF88)
        ..style = PaintingStyle.fill;

      final arrowPath = Path();
      final arrowSize = 8.0;
      arrowPath.moveTo(x, y - arrowSize); // Top point
      arrowPath.lineTo(x - arrowSize / 2, y + arrowSize / 2); // Bottom left
      arrowPath.lineTo(x + arrowSize / 2, y + arrowSize / 2); // Bottom right
      arrowPath.close();
      canvas.drawPath(arrowPath, arrowPaint);
    }

    // Draw text label
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: isCardinal ? 11 : 9,
          color: const Color(0xFF00FF88).withOpacity(isCardinal ? 1.0 : 0.7),
          fontWeight: isCardinal ? FontWeight.bold : FontWeight.w500,
          height: 1.1,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();

    // Center the text at the marker position
    final textOffset = Offset(
      x - textPainter.width / 2,
      degrees == 0 ? y + 2 : y - textPainter.height / 2,
    );
    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(CompactRadarPainter oldDelegate) {
    return oldDelegate.devices.length != devices.length ||
        oldDelegate.userBearing != userBearing ||
        !_listEquals(oldDelegate.radiusRings, radiusRings) ||
        !_devicesEqual(oldDelegate.devices, devices);
  }

  /// Compare two device lists for changes
  bool _devicesEqual(List<RadarDevice> a, List<RadarDevice> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].distance != b[i].distance ||
          a[i].bearing != b[i].bearing ||
          a[i].status != b[i].status) {
        return false;
      }
    }
    return true;
  }

  /// Сравнить два списка double
  bool _listEquals(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
