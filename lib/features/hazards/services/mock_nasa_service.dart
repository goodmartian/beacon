import 'dart:async';
import '../models/fire_event.dart';

/// Mock NASA FIRMS service for demo
/// Uses realistic California wildfire data
class MockNasaService {
  /// Get mock active fires near user location
  Future<List<FireEvent>> getActiveFires({
    required double userLat,
    required double userLon,
    double radiusKm = 50,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Return fires based on user location
    if (_isInCalifornia(userLat, userLon)) {
      return _getCaliforniaFires(userLat, userLon);
    } else if (_isInEurope(userLat, userLon)) {
      return _getEuropeFires(userLat, userLon);
    } else if (_isInAustralia(userLat, userLon)) {
      return _getAustraliaFires(userLat, userLon);
    } else {
      // Default: California fires for demo
      return _getCaliforniaFires(37.7749, -122.4194);
    }
  }

  bool _isInCalifornia(double lat, double lon) {
    return lat >= 32.0 && lat <= 42.0 && lon >= -125.0 && lon <= -114.0;
  }

  bool _isInEurope(double lat, double lon) {
    return lat >= 35.0 && lat <= 71.0 && lon >= -10.0 && lon <= 40.0;
  }

  bool _isInAustralia(double lat, double lon) {
    return lat >= -44.0 && lat <= -10.0 && lon >= 113.0 && lon <= 154.0;
  }

  /// California wildfires (realistic demo data)
  List<FireEvent> _getCaliforniaFires(double centerLat, double centerLon) {
    final now = DateTime.now();

    return [
      // High priority - recent, high confidence, close
      FireEvent(
        id: 'FIRMS_CA_001',
        latitude: centerLat + 0.05, // ~5km north
        longitude: centerLon + 0.02,
        brightness: 345.5,
        confidence: 'high',
        acquisitionTime: now.subtract(const Duration(hours: 1)),
        frp: 65.3,
        satellite: 'N',
        isDayTime: true,
      ),

      // Medium priority - nominal confidence
      FireEvent(
        id: 'FIRMS_CA_002',
        latitude: centerLat - 0.08, // ~8km south
        longitude: centerLon - 0.05,
        brightness: 320.2,
        confidence: 'nominal',
        acquisitionTime: now.subtract(const Duration(hours: 3)),
        frp: 42.1,
        satellite: 'S',
        isDayTime: true,
      ),

      // Lower priority - older, farther
      FireEvent(
        id: 'FIRMS_CA_003',
        latitude: centerLat + 0.15, // ~15km north
        longitude: centerLon + 0.10,
        brightness: 315.8,
        confidence: 'nominal',
        acquisitionTime: now.subtract(const Duration(hours: 8)),
        frp: 28.5,
        satellite: 'N',
        isDayTime: false,
      ),

      // Low confidence
      FireEvent(
        id: 'FIRMS_CA_004',
        latitude: centerLat - 0.12,
        longitude: centerLon + 0.08,
        brightness: 305.1,
        confidence: 'low',
        acquisitionTime: now.subtract(const Duration(hours: 12)),
        frp: 15.2,
        satellite: 'S',
        isDayTime: false,
      ),

      // Very recent, very dangerous
      FireEvent(
        id: 'FIRMS_CA_005',
        latitude: centerLat + 0.03, // ~3km north
        longitude: centerLon - 0.01,
        brightness: 355.7,
        confidence: 'high',
        acquisitionTime: now.subtract(const Duration(minutes: 30)),
        frp: 85.9,
        satellite: 'N',
        isDayTime: true,
      ),
    ];
  }

  /// Europe wildfires
  List<FireEvent> _getEuropeFires(double centerLat, double centerLon) {
    final now = DateTime.now();

    return [
      FireEvent(
        id: 'FIRMS_EU_001',
        latitude: centerLat + 0.04,
        longitude: centerLon + 0.03,
        brightness: 325.3,
        confidence: 'high',
        acquisitionTime: now.subtract(const Duration(hours: 2)),
        frp: 48.7,
        satellite: 'N',
        isDayTime: true,
      ),
      FireEvent(
        id: 'FIRMS_EU_002',
        latitude: centerLat - 0.06,
        longitude: centerLon - 0.04,
        brightness: 318.9,
        confidence: 'nominal',
        acquisitionTime: now.subtract(const Duration(hours: 5)),
        frp: 35.2,
        satellite: 'S',
        isDayTime: true,
      ),
    ];
  }

  /// Australia wildfires
  List<FireEvent> _getAustraliaFires(double centerLat, double centerLon) {
    final now = DateTime.now();

    return [
      FireEvent(
        id: 'FIRMS_AU_001',
        latitude: centerLat + 0.07,
        longitude: centerLon + 0.05,
        brightness: 340.1,
        confidence: 'high',
        acquisitionTime: now.subtract(const Duration(hours: 1)),
        frp: 72.4,
        satellite: 'N',
        isDayTime: true,
      ),
      FireEvent(
        id: 'FIRMS_AU_002',
        latitude: centerLat - 0.09,
        longitude: centerLon + 0.06,
        brightness: 328.5,
        confidence: 'nominal',
        acquisitionTime: now.subtract(const Duration(hours: 4)),
        frp: 55.8,
        satellite: 'S',
        isDayTime: false,
      ),
      FireEvent(
        id: 'FIRMS_AU_003',
        latitude: centerLat + 0.12,
        longitude: centerLon - 0.08,
        brightness: 312.7,
        confidence: 'low',
        acquisitionTime: now.subtract(const Duration(hours: 10)),
        frp: 22.3,
        satellite: 'N',
        isDayTime: false,
      ),
    ];
  }

  /// Get fires sorted by priority (most dangerous first)
  Future<List<FireEvent>> getFiresByPriority({
    required double userLat,
    required double userLon,
  }) async {
    final fires = await getActiveFires(
      userLat: userLat,
      userLon: userLon,
    );

    fires.sort((a, b) => b.priority.compareTo(a.priority));
    return fires;
  }

  /// Check if user is in danger zone (within 10km of high-priority fire)
  Future<bool> isUserInDanger({
    required double userLat,
    required double userLon,
  }) async {
    final fires = await getActiveFires(
      userLat: userLat,
      userLon: userLon,
    );

    for (var fire in fires) {
      if (fire.confidence == 'high' || fire.confidence == 'nominal') {
        final distance = fire.distanceFromUser(userLat, userLon);
        if (distance < 10.0) {
          // Within 10km
          return true;
        }
      }
    }

    return false;
  }

  /// Get nearest fire
  Future<FireEvent?> getNearestFire({
    required double userLat,
    required double userLon,
  }) async {
    final fires = await getActiveFires(
      userLat: userLat,
      userLon: userLon,
    );

    if (fires.isEmpty) return null;

    fires.sort((a, b) {
      final distA = a.distanceFromUser(userLat, userLon);
      final distB = b.distanceFromUser(userLat, userLon);
      return distA.compareTo(distB);
    });

    return fires.first;
  }
}
