import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/fire_event.dart';
import '../services/nasa_firms_service.dart';
import '../services/mock_nasa_service.dart';
import '../services/fire_cache_service.dart';

/// Provider for NASA FIRMS data management
/// Handles fire events, user location, and automatic updates
class NasaProvider extends ChangeNotifier {
  final NasaFirmsService? _realService;
  final MockNasaService _mockService = MockNasaService();
  final FireCacheService _cacheService = FireCacheService();

  // State
  List<FireEvent> _fires = [];
  Position? _userLocation;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastUpdate;
  Timer? _updateTimer;

  // Settings
  bool _useMockData = true; // Use mock data by default
  bool _autoUpdate = true;
  int _updateIntervalMinutes = 30;
  double _searchRadiusKm = 50;

  // Getters
  List<FireEvent> get fires => List.unmodifiable(_fires);
  Position? get userLocation => _userLocation;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdate => _lastUpdate;
  bool get useMockData => _useMockData;
  bool get autoUpdate => _autoUpdate;
  int get updateIntervalMinutes => _updateIntervalMinutes;
  double get searchRadiusKm => _searchRadiusKm;

  /// Has fires been loaded at least once
  bool get hasData => _fires.isNotEmpty || _lastUpdate != null;

  /// User location available
  bool get hasLocation => _userLocation != null;

  /// Is user in danger zone (within 10km of high-priority fire)
  bool get isInDangerZone {
    if (_userLocation == null || _fires.isEmpty) return false;

    for (var fire in _fires) {
      if (fire.confidence == 'high' || fire.confidence == 'nominal') {
        final distance = fire.distanceFromUser(
          _userLocation!.latitude,
          _userLocation!.longitude,
        );
        if (distance < 10.0) return true;
      }
    }
    return false;
  }

  /// Get fires sorted by priority
  List<FireEvent> get firesByPriority {
    final sorted = List<FireEvent>.from(_fires);
    sorted.sort((a, b) => b.priority.compareTo(a.priority));
    return sorted;
  }

  /// Get fires sorted by distance
  List<FireEvent> get firesByDistance {
    if (_userLocation == null) return _fires;

    final sorted = List<FireEvent>.from(_fires);
    sorted.sort((a, b) {
      final distA = a.distanceFromUser(
        _userLocation!.latitude,
        _userLocation!.longitude,
      );
      final distB = b.distanceFromUser(
        _userLocation!.latitude,
        _userLocation!.longitude,
      );
      return distA.compareTo(distB);
    });
    return sorted;
  }

  /// Get nearest fire
  FireEvent? get nearestFire {
    if (_fires.isEmpty || _userLocation == null) return null;
    return firesByDistance.first;
  }

  NasaProvider({
    String? apiKey,
    bool useMockData = true,
  })  : _useMockData = useMockData,
        _realService = useMockData || apiKey == null
            ? null
            : NasaFirmsService(mapKey: apiKey);

  /// Initialize provider with location permissions and first data load
  Future<void> initialize() async {
    // Initialize cache service
    await _cacheService.initialize();

    // Try to load cached data first
    await _loadCachedData();

    await _requestLocationPermission();
    await updateUserLocation();

    if (_autoUpdate) {
      startAutoUpdate();
    }
  }

  /// Load cached fire data
  Future<void> _loadCachedData() async {
    try {
      final cachedFires = await _cacheService.getCachedFires();
      if (cachedFires.isNotEmpty) {
        _fires = cachedFires;
        final cacheAge = await _cacheService.getCacheAge();
        debugPrint('Loaded ${cachedFires.length} fires from cache (age: ${cacheAge?.inHours}h)');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load cached data: $e');
    }
  }

  /// Request location permissions
  Future<bool> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _errorMessage = 'Location services are disabled';
      notifyListeners();
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _errorMessage = 'Location permissions denied';
        notifyListeners();
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _errorMessage = 'Location permissions permanently denied';
      notifyListeners();
      return false;
    }

    return true;
  }

  /// Update user location
  Future<void> updateUserLocation() async {
    try {
      final hasPermission = await _requestLocationPermission();
      if (!hasPermission) return;

      _userLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      debugPrint('User location updated: ${_userLocation!.latitude}, ${_userLocation!.longitude}');
      notifyListeners();

      // Auto-fetch fires after location update
      await fetchFires();
    } catch (e) {
      _errorMessage = 'Failed to get location: $e';
      debugPrint(_errorMessage);
      notifyListeners();
    }
  }

  /// Fetch active fires around user location
  Future<void> fetchFires({
    double? latitude,
    double? longitude,
    double? radiusKm,
    int dayRange = 1,
  }) async {
    // Use provided coordinates or user location
    final lat = latitude ?? _userLocation?.latitude;
    final lon = longitude ?? _userLocation?.longitude;

    if (lat == null || lon == null) {
      _errorMessage = 'Location not available';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final radius = radiusKm ?? _searchRadiusKm;

      List<FireEvent> fetchedFires;

      if (_useMockData || _realService == null) {
        // Use mock service
        fetchedFires = await _mockService.getActiveFires(
          userLat: lat,
          userLon: lon,
          radiusKm: radius,
        );
        debugPrint('Fetched ${fetchedFires.length} mock fires');
      } else {
        // Use real NASA FIRMS API
        fetchedFires = await _realService!.getActiveFires(
          latitude: lat,
          longitude: lon,
          radiusKm: radius,
          dayRange: dayRange,
        );
        debugPrint('Fetched ${fetchedFires.length} fires from NASA FIRMS');
      }

      _fires = fetchedFires;
      _lastUpdate = DateTime.now();
      _errorMessage = null;

      // Cache the data
      await _cacheService.cacheFires(fetchedFires);
      debugPrint('Cached ${fetchedFires.length} fire events');
    } catch (e) {
      _errorMessage = 'Failed to fetch fires: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Start automatic updates
  void startAutoUpdate() {
    _autoUpdate = true;
    _updateTimer?.cancel();

    _updateTimer = Timer.periodic(
      Duration(minutes: _updateIntervalMinutes),
      (_) => fetchFires(),
    );

    debugPrint('Auto-update started: every $_updateIntervalMinutes minutes');
    notifyListeners();
  }

  /// Stop automatic updates
  void stopAutoUpdate() {
    _autoUpdate = false;
    _updateTimer?.cancel();
    _updateTimer = null;

    debugPrint('Auto-update stopped');
    notifyListeners();
  }

  /// Update settings
  void updateSettings({
    bool? useMockData,
    bool? autoUpdate,
    int? updateIntervalMinutes,
    double? searchRadiusKm,
  }) {
    bool needsRestart = false;

    if (useMockData != null && useMockData != _useMockData) {
      _useMockData = useMockData;
      debugPrint('Data source changed: ${useMockData ? "Mock" : "Real"}');
    }

    if (autoUpdate != null && autoUpdate != _autoUpdate) {
      if (autoUpdate) {
        startAutoUpdate();
      } else {
        stopAutoUpdate();
      }
      needsRestart = true;
    }

    if (updateIntervalMinutes != null &&
        updateIntervalMinutes != _updateIntervalMinutes) {
      _updateIntervalMinutes = updateIntervalMinutes;
      needsRestart = true;
    }

    if (searchRadiusKm != null && searchRadiusKm != _searchRadiusKm) {
      _searchRadiusKm = searchRadiusKm;
    }

    if (needsRestart && _autoUpdate) {
      startAutoUpdate();
    }

    notifyListeners();
  }

  /// Get fire statistics
  Map<String, dynamic> getStatistics() {
    if (_fires.isEmpty) {
      return {
        'total': 0,
        'high_confidence': 0,
        'nominal_confidence': 0,
        'low_confidence': 0,
        'average_frp': 0.0,
        'nearest_distance_km': null,
      };
    }

    final highConf = _fires.where((f) => f.confidence == 'high').length;
    final nomConf = _fires.where((f) => f.confidence == 'nominal').length;
    final lowConf = _fires.where((f) => f.confidence == 'low').length;

    final avgFrp =
        _fires.map((f) => f.frp).reduce((a, b) => a + b) / _fires.length;

    double? nearestDist;
    if (_userLocation != null) {
      final distances = _fires
          .map((f) => f.distanceFromUser(
                _userLocation!.latitude,
                _userLocation!.longitude,
              ))
          .toList();
      distances.sort();
      nearestDist = distances.first;
    }

    return {
      'total': _fires.length,
      'high_confidence': highConf,
      'nominal_confidence': nomConf,
      'low_confidence': lowConf,
      'average_frp': avgFrp,
      'nearest_distance_km': nearestDist,
    };
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}
