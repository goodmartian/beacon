/// Fire event from NASA FIRMS
class FireEvent {
  final String id;
  final double latitude;
  final double longitude;
  final double brightness; // Kelvin
  final String confidence; // 'low', 'nominal', 'high'
  final DateTime acquisitionTime;
  final double frp; // Fire Radiative Power (MW)
  final String satellite; // 'N' (NOAA-20) or 'S' (Suomi-NPP)
  final bool isDayTime;

  FireEvent({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.brightness,
    required this.confidence,
    required this.acquisitionTime,
    required this.frp,
    required this.satellite,
    required this.isDayTime,
  });

  /// Priority for rescue operations (1-10)
  int get priority {
    int score = 0;

    // Confidence weight
    if (confidence == 'high') {
      score += 3;
    } else if (confidence == 'nominal') {
      score += 2;
    } else {
      score += 1;
    }

    // FRP weight (higher = more dangerous)
    if (frp > 50) {
      score += 3;
    } else if (frp > 20) {
      score += 2;
    } else {
      score += 1;
    }

    // Recency weight
    final age = DateTime.now().difference(acquisitionTime).inHours;
    if (age < 3) {
      score += 3;
    } else if (age < 12) {
      score += 2;
    } else {
      score += 1;
    }

    return score;
  }

  /// Distance from user in kilometers
  double distanceFromUser(double userLat, double userLon) {
    return _calculateDistance(latitude, longitude, userLat, userLon);
  }

  /// Haversine formula for distance calculation
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Earth radius in kilometers
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) * _cos(_toRadians(lat2)) *
        _sin(dLon / 2) * _sin(dLon / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));

    return R * c;
  }

  static double _toRadians(double degrees) => degrees * 3.14159265359 / 180;
  static double _sin(double x) => x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  static double _cos(double x) => 1 - (x * x) / 2 + (x * x * x * x) / 24;
  static double _sqrt(double x) {
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
  static double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.14159265359;
    if (x < 0 && y < 0) return _atan(y / x) - 3.14159265359;
    if (x == 0 && y > 0) return 3.14159265359 / 2;
    if (x == 0 && y < 0) return -3.14159265359 / 2;
    return 0;
  }
  static double _atan(double x) => x - (x * x * x) / 3 + (x * x * x * x * x) / 5;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'latitude': latitude,
        'longitude': longitude,
        'brightness': brightness,
        'confidence': confidence,
        'acquisitionTime': acquisitionTime.toIso8601String(),
        'frp': frp,
        'satellite': satellite,
        'isDayTime': isDayTime,
      };

  /// Create from JSON
  factory FireEvent.fromJson(Map<String, dynamic> json) {
    return FireEvent(
      id: json['id'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      brightness: json['brightness'],
      confidence: json['confidence'],
      acquisitionTime: DateTime.parse(json['acquisitionTime']),
      frp: json['frp'],
      satellite: json['satellite'],
      isDayTime: json['isDayTime'],
    );
  }

  @override
  String toString() {
    return 'FireEvent(id: $id, lat: $latitude, lon: $longitude, confidence: $confidence, frp: $frp)';
  }
}
