import 'dart:async';
import 'package:dio/dio.dart';
import '../models/fire_event.dart';

/// NASA FIRMS (Fire Information for Resource Management System) API service
/// Provides real-time active fire data from MODIS and VIIRS satellites
class NasaFirmsService {
  final Dio _dio;

  /// NASA FIRMS API base URL
  static const String _baseUrl = 'https://firms.modaps.eosdis.nasa.gov/api/area';

  /// Default API key (should be replaced with actual key from NASA)
  /// Get your free MAP_KEY at: https://firms.modaps.eosdis.nasa.gov/api/
  final String _mapKey;

  /// Data source options:
  /// - VIIRS_NOAA20_NRT: VIIRS on NOAA-20 (most recent)
  /// - VIIRS_SNPP_NRT: VIIRS on Suomi-NPP
  /// - MODIS_NRT: MODIS combined Aqua and Terra
  static const String defaultSource = 'VIIRS_NOAA20_NRT';

  NasaFirmsService({
    Dio? dio,
    required String mapKey,
  })  : _dio = dio ?? Dio(),
        _mapKey = mapKey {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  /// Get active fires within a radius around user location
  ///
  /// [latitude] - User's latitude
  /// [longitude] - User's longitude
  /// [radiusKm] - Radius in kilometers (default: 50km)
  /// [dayRange] - Number of days to look back (1-10, default: 1)
  /// [source] - Data source (default: VIIRS_NOAA20_NRT)
  Future<List<FireEvent>> getActiveFires({
    required double latitude,
    required double longitude,
    double radiusKm = 50,
    int dayRange = 1,
    String source = defaultSource,
  }) async {
    try {
      // Calculate bounding box from center point and radius
      // Approximate: 1 degree latitude ≈ 111 km
      // 1 degree longitude ≈ 111 km * cos(latitude)
      final double latDelta = radiusKm / 111.0;
      final double lonDelta = radiusKm / (111.0 * _cos(_toRadians(latitude)));

      final double minLat = latitude - latDelta;
      final double maxLat = latitude + latDelta;
      final double minLon = longitude - lonDelta;
      final double maxLon = longitude + lonDelta;

      // Build area parameter: "minLon,minLat,maxLon,maxLat"
      final String area = '${minLon.toStringAsFixed(4)},${minLat.toStringAsFixed(4)},'
          '${maxLon.toStringAsFixed(4)},${maxLat.toStringAsFixed(4)}';

      // Ensure day range is within valid bounds
      final int validDayRange = dayRange.clamp(1, 10);

      // Make API request
      // Format: /csv/[MAP_KEY]/[SOURCE]/[AREA]/[DAY_RANGE]
      final response = await _dio.get(
        '/csv/$_mapKey/$source/$area/$validDayRange',
      );

      if (response.statusCode == 200) {
        return _parseCSVResponse(response.data);
      } else {
        throw Exception('Failed to fetch fire data: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get active fires: $e');
    }
  }

  /// Parse CSV response from NASA FIRMS API
  ///
  /// CSV format:
  /// latitude,longitude,brightness,scan,track,acq_date,acq_time,satellite,
  /// instrument,confidence,version,bright_t31,frp,daynight
  List<FireEvent> _parseCSVResponse(String csvData) {
    final List<FireEvent> fires = [];
    final lines = csvData.split('\n');

    // Skip header line
    if (lines.isEmpty || lines.length < 2) {
      return fires;
    }

    // Parse each data line
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        final fields = line.split(',');
        if (fields.length < 14) continue;

        // Extract fields
        final lat = double.parse(fields[0]);
        final lon = double.parse(fields[1]);
        final brightness = double.parse(fields[2]);
        final acqDate = fields[5]; // Format: YYYY-MM-DD
        final acqTime = fields[6]; // Format: HHMM
        final satellite = fields[7]; // 'N' (NOAA-20) or 'S' (Suomi-NPP)
        final confidence = fields[9].toLowerCase(); // 'low', 'nominal', 'high'
        final frp = double.tryParse(fields[12]) ?? 0.0; // Fire Radiative Power
        final daynight = fields[13].trim(); // 'D' or 'N'

        // Parse acquisition time
        final acquisitionTime = _parseAcquisitionTime(acqDate, acqTime);

        // Create fire event
        final fire = FireEvent(
          id: 'FIRMS_${satellite}_${acqDate}_${acqTime}_${lat}_${lon}',
          latitude: lat,
          longitude: lon,
          brightness: brightness,
          confidence: confidence,
          acquisitionTime: acquisitionTime,
          frp: frp,
          satellite: satellite,
          isDayTime: daynight == 'D',
        );

        fires.add(fire);
      } catch (e) {
        // Skip invalid lines
        continue;
      }
    }

    return fires;
  }

  /// Parse acquisition date and time into DateTime
  DateTime _parseAcquisitionTime(String date, String time) {
    try {
      // Date format: YYYY-MM-DD
      final dateParts = date.split('-');
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      // Time format: HHMM
      final hour = int.parse(time.substring(0, 2));
      final minute = int.parse(time.substring(2, 4));

      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      return DateTime.now();
    }
  }

  /// Get fires sorted by priority (most dangerous first)
  Future<List<FireEvent>> getFiresByPriority({
    required double latitude,
    required double longitude,
    double radiusKm = 50,
    int dayRange = 1,
  }) async {
    final fires = await getActiveFires(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      dayRange: dayRange,
    );

    fires.sort((a, b) => b.priority.compareTo(a.priority));
    return fires;
  }

  /// Get fires sorted by distance (nearest first)
  Future<List<FireEvent>> getFiresByDistance({
    required double latitude,
    required double longitude,
    double radiusKm = 50,
    int dayRange = 1,
  }) async {
    final fires = await getActiveFires(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      dayRange: dayRange,
    );

    fires.sort((a, b) {
      final distA = a.distanceFromUser(latitude, longitude);
      final distB = b.distanceFromUser(latitude, longitude);
      return distA.compareTo(distB);
    });

    return fires;
  }

  /// Check if user is in danger zone (within 10km of high-priority fire)
  Future<bool> isUserInDanger({
    required double latitude,
    required double longitude,
  }) async {
    final fires = await getActiveFires(
      latitude: latitude,
      longitude: longitude,
      radiusKm: 50, // Check 50km radius
      dayRange: 1,  // Only recent fires
    );

    for (var fire in fires) {
      if (fire.confidence == 'high' || fire.confidence == 'nominal') {
        final distance = fire.distanceFromUser(latitude, longitude);
        if (distance < 10.0) {
          // Within 10km danger zone
          return true;
        }
      }
    }

    return false;
  }

  /// Get nearest fire to user location
  Future<FireEvent?> getNearestFire({
    required double latitude,
    required double longitude,
    double radiusKm = 50,
  }) async {
    final fires = await getFiresByDistance(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );

    return fires.isEmpty ? null : fires.first;
  }

  /// Get fire statistics for an area
  Future<Map<String, dynamic>> getFireStatistics({
    required double latitude,
    required double longitude,
    double radiusKm = 50,
    int dayRange = 1,
  }) async {
    final fires = await getActiveFires(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      dayRange: dayRange,
    );

    if (fires.isEmpty) {
      return {
        'total': 0,
        'high_confidence': 0,
        'nominal_confidence': 0,
        'low_confidence': 0,
        'average_frp': 0.0,
        'nearest_distance_km': null,
      };
    }

    final highConf = fires.where((f) => f.confidence == 'high').length;
    final nomConf = fires.where((f) => f.confidence == 'nominal').length;
    final lowConf = fires.where((f) => f.confidence == 'low').length;

    final avgFrp = fires.map((f) => f.frp).reduce((a, b) => a + b) / fires.length;

    final distances = fires.map((f) => f.distanceFromUser(latitude, longitude)).toList();
    distances.sort();

    return {
      'total': fires.length,
      'high_confidence': highConf,
      'nominal_confidence': nomConf,
      'low_confidence': lowConf,
      'average_frp': avgFrp,
      'nearest_distance_km': distances.first,
    };
  }

  // Math helpers
  static double _toRadians(double degrees) => degrees * 3.14159265359 / 180;
  static double _cos(double x) => 1 - (x * x) / 2 + (x * x * x * x) / 24;
}
