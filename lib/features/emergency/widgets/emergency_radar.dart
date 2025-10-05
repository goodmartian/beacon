import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/radar_device.dart';

/// Circular radar-style heatmap interface for emergency mode
class EmergencyRadarWidget extends StatefulWidget {
  final List<RadarDevice> devices;
  final double userBearing; // User's facing direction in degrees
  final VoidCallback? onCenterTap;
  final Function(RadarDevice)? onDeviceTap;

  const EmergencyRadarWidget({
    super.key,
    required this.devices,
    this.userBearing = 0.0,
    this.onCenterTap,
    this.onDeviceTap,
  });

  @override
  State<EmergencyRadarWidget> createState() => _EmergencyRadarWidgetState();
}

class _EmergencyRadarWidgetState extends State<EmergencyRadarWidget>
    with TickerProviderStateMixin {
  late AnimationController _sweepController;
  late AnimationController _pulseController;

  double _zoomLevel = 200.0; // Current max distance in meters
  Offset _panOffset = Offset.zero;
  double _scale = 1.0;

  final List<double> _zoomLevels = [50, 100, 200, 500];

  @override
  void initState() {
    super.initState();

    // Sweep animation (3 second rotation)
    _sweepController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Pulse animation for SOS devices
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTapUp(TapUpDetails details, Size radarSize) {
    final center = Offset(radarSize.width / 2, radarSize.height / 2);
    final tapOffset = details.localPosition - center;

    // Check if tapped on a device
    for (final device in widget.devices) {
      final deviceOffset = device.toCartesian(
        radarSize.width / 2,
        _zoomLevel,
      );

      if ((tapOffset - deviceOffset).distance < 20) {
        widget.onDeviceTap?.call(device);
        return;
      }
    }

    // Check if tapped on center
    if (tapOffset.distance < 30) {
      widget.onCenterTap?.call();
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _scale = 1.0;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = details.scale;
    });
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    // Snap to nearest zoom level
    if (_scale > 1.2) {
      // Zoom in
      final currentIndex = _zoomLevels.indexOf(_zoomLevel);
      if (currentIndex > 0) {
        setState(() {
          _zoomLevel = _zoomLevels[currentIndex - 1];
        });
      }
    } else if (_scale < 0.8) {
      // Zoom out
      final currentIndex = _zoomLevels.indexOf(_zoomLevel);
      if (currentIndex < _zoomLevels.length - 1) {
        setState(() {
          _zoomLevel = _zoomLevels[currentIndex + 1];
        });
      }
    }

    setState(() {
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sosDevices = widget.devices.where((d) => d.status == DeviceStatus.sos).toList();
    final nearestSos = sosDevices.isNotEmpty
        ? sosDevices.reduce((a, b) => a.distance < b.distance ? a : b)
        : null;

    return Container(
      color: const Color(0xFF0A0E27),
      child: Stack(
        children: [
          // Main radar display
          Center(
            child: GestureDetector(
              onTapUp: (details) {
                final renderBox = context.findRenderObject() as RenderBox;
                _handleTapUp(details, renderBox.size);
              },
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              onScaleEnd: _handleScaleEnd,
              child: AspectRatio(
                aspectRatio: 1.0,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_sweepController, _pulseController]),
                  builder: (context, child) {
                    return CustomPaint(
                      painter: RadarPainter(
                        devices: widget.devices,
                        sweepAngle: _sweepController.value * 2 * math.pi,
                        pulseValue: _pulseController.value,
                        userBearing: widget.userBearing,
                        maxDistance: _zoomLevel,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
              ),
            ),
          ),

          // Top left: Device count
          Positioned(
            top: 16,
            left: 16,
            child: _buildInfoCard(
              '${widget.devices.length} devices in range',
              Icons.devices,
            ),
          ),

          // Bottom left: Nearest SOS
          if (nearestSos != null)
            Positioned(
              bottom: 16,
              left: 16,
              child: _buildInfoCard(
                'SOS: ${nearestSos.distance.toInt()}m →',
                Icons.emergency,
                color: const Color(0xFFFF3366),
              ),
            ),

          // Bottom right: Safe zone (placeholder)
          Positioned(
            bottom: 16,
            right: 16,
            child: _buildInfoCard(
              'Safety: Calculating... ↗',
              Icons.shield,
              color: const Color(0xFF00FF88),
            ),
          ),

          // Top right: Zoom level indicator
          Positioned(
            top: 16,
            right: 16,
            child: _buildInfoCard(
              '${_zoomLevel.toInt()}m',
              Icons.zoom_out_map,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String text, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2645).withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color ?? const Color(0xFF00D9FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? const Color(0xFF00D9FF)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color ?? const Color(0xFFE8EDF2),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the radar visualization
class RadarPainter extends CustomPainter {
  final List<RadarDevice> devices;
  final double sweepAngle;
  final double pulseValue;
  final double userBearing;
  final double maxDistance;

  RadarPainter({
    required this.devices,
    required this.sweepAngle,
    required this.pulseValue,
    required this.userBearing,
    required this.maxDistance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Draw layers
    _drawBackground(canvas, center, radius);
    _drawRadarCircles(canvas, center, radius);
    _drawDirectionCone(canvas, center, radius);
    _drawHeatmap(canvas, center, radius);
    _drawDevices(canvas, center, radius);
    _drawSweepLine(canvas, center, radius);
    _drawCenterDot(canvas, center);
    _drawNorthIndicator(canvas, center, radius);
  }

  void _drawBackground(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = const Color(0xFF0A0E27)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, center.dx * 2, center.dy * 2),
      paint,
    );

    // Draw subtle grid dots
    final dotPaint = Paint()
      ..color = const Color(0xFF2D3E5F).withOpacity(0.2)
      ..style = PaintingStyle.fill;

    for (double x = 0; x < center.dx * 2; x += 20) {
      for (double y = 0; y < center.dy * 2; y += 20) {
        canvas.drawCircle(Offset(x, y), 1, dotPaint);
      }
    }
  }

  void _drawRadarCircles(Canvas canvas, Offset center, double radius) {
    final circlePaint = Paint()
      ..color = const Color(0xFF1A2645).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Distances for concentric circles based on zoom level
    final distances = [
      maxDistance * 0.125,  // 25m at 200m zoom
      maxDistance * 0.25,   // 50m
      maxDistance * 0.5,    // 100m
      maxDistance * 1.0,    // 200m (full radius)
    ];

    for (int i = 0; i < distances.length; i++) {
      final distance = distances[i];
      final circleRadius = radius * (distance / maxDistance);

      // Draw circle
      canvas.drawCircle(center, circleRadius, circlePaint);

      // Draw distance label
      final label = '${distance.toInt()}m';
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF8B95A8),
          fontWeight: FontWeight.w400,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(center.dx + circleRadius + 5, center.dy - 5),
      );
    }
  }

  void _drawDirectionCone(Canvas canvas, Offset center, double radius) {
    final conePaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [
          const Color(0xFF00D9FF).withOpacity(0.3),
          const Color(0xFF00D9FF).withOpacity(0.0),
        ],
        [0.0, 1.0],
      )
      ..style = PaintingStyle.fill;

    final path = Path();
    final coneAngle = 75 * (math.pi / 180); // 75 degree cone
    final bearingRad = (userBearing - 90) * (math.pi / 180);

    path.moveTo(center.dx, center.dy);
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      bearingRad - coneAngle / 2,
      coneAngle,
      false,
    );
    path.close();

    canvas.drawPath(path, conePaint);
  }

  void _drawHeatmap(Canvas canvas, Offset center, double radius) {
    if (devices.isEmpty) return;

    // Create density grid
    final gridSize = 50;
    final cellSize = (radius * 2) / gridSize;
    final densityGrid = List.generate(
      gridSize,
      (_) => List.filled(gridSize, 0.0),
    );

    // Calculate density for each cell
    for (final device in devices) {
      final devicePos = device.toCartesian(radius, maxDistance);
      final gridX = ((devicePos.dx + radius) / cellSize).floor();
      final gridY = ((devicePos.dy + radius) / cellSize).floor();

      if (gridX >= 0 && gridX < gridSize && gridY >= 0 && gridY < gridSize) {
        // Gaussian falloff
        for (int x = math.max(0, gridX - 3); x < math.min(gridSize, gridX + 4); x++) {
          for (int y = math.max(0, gridY - 3); y < math.min(gridSize, gridY + 4); y++) {
            final dx = x - gridX;
            final dy = y - gridY;
            final distance = math.sqrt(dx * dx + dy * dy);
            final weight = math.exp(-distance * distance / 2);
            densityGrid[x][y] += weight;
          }
        }
      }
    }

    // Draw heatmap
    for (int x = 0; x < gridSize; x++) {
      for (int y = 0; y < gridSize; y++) {
        final density = densityGrid[x][y];
        if (density > 0.1) {
          final color = _getHeatmapColor(density);
          final paint = Paint()
            ..color = color
            ..style = PaintingStyle.fill;

          canvas.drawRect(
            Rect.fromLTWH(
              center.dx - radius + x * cellSize,
              center.dy - radius + y * cellSize,
              cellSize,
              cellSize,
            ),
            paint,
          );
        }
      }
    }
  }

  Color _getHeatmapColor(double density) {
    if (density < 0.5) {
      return const Color(0xFF0A2540).withOpacity(0.4);
    } else if (density < 1.0) {
      return const Color(0xFF00D9FF).withOpacity(0.5);
    } else if (density < 1.5) {
      return const Color(0xFF00FF88).withOpacity(0.55);
    } else if (density < 2.0) {
      return const Color(0xFFFFB800).withOpacity(0.6);
    } else {
      return const Color(0xFFFF6B35).withOpacity(0.65);
    }
  }

  void _drawDevices(Canvas canvas, Offset center, double radius) {
    for (final device in devices) {
      final devicePos = center + device.toCartesian(radius, maxDistance);
      final dotSize = device.getDotSize();
      final color = device.getColor();

      // Draw glow effect
      final glowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(devicePos, dotSize * 1.5, glowPaint);

      // Draw pulsing effect for SOS
      if (device.shouldPulse()) {
        final pulsePaint = Paint()
          ..color = color.withOpacity(0.3 * (1 - pulseValue))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawCircle(
          devicePos,
          dotSize + (pulseValue * 15),
          pulsePaint,
        );
      }

      // Draw device dot
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(devicePos, dotSize, dotPaint);

      // Draw inner highlight
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(devicePos, dotSize * 0.4, highlightPaint);
    }
  }

  void _drawSweepLine(Canvas canvas, Offset center, double radius) {
    final sweepPaint = Paint()
      ..shader = ui.Gradient.linear(
        center,
        Offset(
          center.dx + radius * math.cos(sweepAngle),
          center.dy + radius * math.sin(sweepAngle),
        ),
        [
          const Color(0xFF00D9FF).withOpacity(0.8),
          const Color(0xFF00D9FF).withOpacity(0.0),
        ],
      )
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * math.cos(sweepAngle),
        center.dy + radius * math.sin(sweepAngle),
      ),
      sweepPaint,
    );
  }

  void _drawCenterDot(Canvas canvas, Offset center) {
    // Outer glow
    final glowPaint = Paint()
      ..color = const Color(0xFF00D9FF).withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawCircle(center, 12, glowPaint);

    // Main dot
    final dotPaint = Paint()
      ..color = const Color(0xFF00D9FF)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 8, dotPaint);

    // Inner highlight
    final highlightPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 3, highlightPaint);
  }

  void _drawNorthIndicator(Canvas canvas, Offset center, double radius) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF8B95A8),
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - 7, center.dy - radius - 25),
    );
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.userBearing != userBearing ||
        oldDelegate.maxDistance != maxDistance ||
        oldDelegate.devices.length != devices.length;
  }
}
