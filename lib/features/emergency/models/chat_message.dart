import '../../mesh/models/mesh_message.dart';

/// Sender role for UI categorization
enum SenderRole {
  civilian,
  rescuer,
  medical,
  system,
}

/// Extended message model for chat UI with display metadata
class ChatMessage {
  final MeshMessage meshMessage;
  final SenderRole role;
  final double? distanceMeters;
  final double? bearingDegrees;
  final int? batteryLevel;
  final String? groupId; // For deduplication
  final int duplicateCount; // How many identical messages

  ChatMessage({
    required this.meshMessage,
    this.role = SenderRole.civilian,
    this.distanceMeters,
    this.bearingDegrees,
    this.batteryLevel,
    this.groupId,
    this.duplicateCount = 1,
  });

  /// Get display priority (higher = more important)
  int get displayPriority {
    // SOS always highest
    if (meshMessage.type == MessageType.sos) return 100;

    // Rescuer messages high priority
    if (role == SenderRole.rescuer) return 90;

    // Medical messages
    if (meshMessage.type == MessageType.medical) {
      final status = meshMessage.payload['status'] as String?;
      if (status == 'critical') return 85;
      if (status == 'injured') return 80;
    }

    // Text messages
    if (meshMessage.type == MessageType.text) return 70;

    // System messages
    if (role == SenderRole.system) return 60;

    // Default
    return 50;
  }

  /// Get age of message
  Duration get age => DateTime.now().difference(meshMessage.timestamp);

  /// Format distance for display
  String get formattedDistance {
    if (distanceMeters == null) return 'Unknown distance';
    if (distanceMeters! < 1000) {
      return '${distanceMeters!.round()}m';
    }
    return '${(distanceMeters! / 1000).toStringAsFixed(1)}km';
  }

  /// Format age for display
  String get formattedAge {
    final duration = age;
    if (duration.inMinutes < 1) return 'Just now';
    if (duration.inMinutes < 60) return '${duration.inMinutes}m ago';
    if (duration.inHours < 24) return '${duration.inHours}h ago';
    return '${duration.inDays}d ago';
  }

  /// Get bearing arrow
  String get bearingArrow {
    if (bearingDegrees == null) return '';

    // Convert bearing to 8-direction arrow
    final directions = ['↑', '↗', '→', '↘', '↓', '↙', '←', '↖'];
    final index = ((bearingDegrees! + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  /// Check if battery is low
  bool get isLowBattery => batteryLevel != null && batteryLevel! < 20;

  /// Get message content text
  String get contentText {
    switch (meshMessage.type) {
      case MessageType.sos:
        return 'SOS - Emergency assistance needed';
      case MessageType.medical:
        final status = meshMessage.payload['status'] as String? ?? 'unknown';
        return 'Medical status: $status';
      case MessageType.text:
        return meshMessage.payload['content'] as String? ?? '';
      case MessageType.location:
        return 'Shared location';
      default:
        return 'System message';
    }
  }

  /// Create from MeshMessage with location data
  factory ChatMessage.fromMeshMessage(
    MeshMessage message, {
    SenderRole? role,
    double? userLatitude,
    double? userLongitude,
    double? userBearing,
    int? batteryLevel,
  }) {
    double? distance;
    double? bearing;

    // Calculate distance if both locations available
    if (userLatitude != null && userLongitude != null) {
      final msgLat = message.payload['lat'] as double?;
      final msgLon = message.payload['lon'] as double?;

      if (msgLat != null && msgLon != null) {
        distance = _calculateDistance(userLatitude, userLongitude, msgLat, msgLon);
        bearing = _calculateBearing(userLatitude, userLongitude, msgLat, msgLon);
      }
    }

    // Determine role
    SenderRole messageRole = role ?? SenderRole.civilian;
    if (message.type == MessageType.nasaData) {
      messageRole = SenderRole.system;
    }

    return ChatMessage(
      meshMessage: message,
      role: messageRole,
      distanceMeters: distance,
      bearingDegrees: bearing,
      batteryLevel: batteryLevel,
    );
  }

  /// Calculate distance between two coordinates (Haversine formula)
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0; // Earth radius in meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) * _cos(_toRadians(lat2)) *
        _sin(dLon / 2) * _sin(dLon / 2);

    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return R * c;
  }

  /// Calculate bearing between two coordinates
  static double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = _toRadians(lon2 - lon1);
    final y = _sin(dLon) * _cos(_toRadians(lat2));
    final x = _cos(_toRadians(lat1)) * _sin(_toRadians(lat2)) -
        _sin(_toRadians(lat1)) * _cos(_toRadians(lat2)) * _cos(dLon);

    final bearing = _atan2(y, x);
    return (_toDegrees(bearing) + 360) % 360;
  }

  // Math helpers
  static double _toRadians(double degrees) => degrees * 3.14159265359 / 180.0;
  static double _toDegrees(double radians) => radians * 180.0 / 3.14159265359;
  static double _sin(double x) => _sinApprox(x);
  static double _cos(double x) => _sinApprox(x + 1.5707963267949);
  static double _sqrt(double x) {
    if (x == 0) return 0;
    double result = x;
    for (int i = 0; i < 10; i++) {
      result = (result + x / result) / 2;
    }
    return result;
  }
  static double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.14159265359;
    if (x < 0 && y < 0) return _atan(y / x) - 3.14159265359;
    if (x == 0 && y > 0) return 1.5707963267949;
    if (x == 0 && y < 0) return -1.5707963267949;
    return 0;
  }
  static double _atan(double x) {
    return x - (x * x * x) / 3 + (x * x * x * x * x) / 5;
  }
  static double _sinApprox(double x) {
    x = x % (2 * 3.14159265359);
    if (x > 3.14159265359) x -= 2 * 3.14159265359;
    return x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  }
}
