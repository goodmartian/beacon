import 'package:hive_flutter/hive_flutter.dart';
import '../models/fire_event.dart';

/// Service for caching fire events locally with Hive
/// Provides 24-hour offline data storage
class FireCacheService {
  static const String _boxName = 'fire_events';
  static const String _timestampKey = 'last_cache_update';
  static const Duration _cacheExpiration = Duration(hours: 24);

  Box<FireEvent>? _box;
  Box<dynamic>? _metaBox;

  /// Initialize Hive and open boxes
  Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapter if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      // Import and register adapter
      // Note: Adapter registration should be done in main.dart
    }

    _box = await Hive.openBox<FireEvent>(_boxName);
    _metaBox = await Hive.openBox('fire_cache_meta');
  }

  /// Cache fire events
  Future<void> cacheFires(List<FireEvent> fires) async {
    if (_box == null) {
      throw Exception('Cache service not initialized');
    }

    // Clear old data
    await _box!.clear();

    // Cache new data
    for (var fire in fires) {
      await _box!.put(fire.id, fire);
    }

    // Update timestamp
    await _metaBox?.put(_timestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Get cached fires
  Future<List<FireEvent>> getCachedFires() async {
    if (_box == null) {
      throw Exception('Cache service not initialized');
    }

    // Check if cache is expired
    if (await isCacheExpired()) {
      return [];
    }

    return _box!.values.toList();
  }

  /// Check if cache is expired (older than 24 hours)
  Future<bool> isCacheExpired() async {
    if (_metaBox == null) return true;

    final timestamp = _metaBox!.get(_timestampKey);
    if (timestamp == null) return true;

    final lastUpdate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    return now.difference(lastUpdate) > _cacheExpiration;
  }

  /// Get cache age
  Future<Duration?> getCacheAge() async {
    if (_metaBox == null) return null;

    final timestamp = _metaBox!.get(_timestampKey);
    if (timestamp == null) return null;

    final lastUpdate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(lastUpdate);
  }

  /// Clear cache
  Future<void> clearCache() async {
    await _box?.clear();
    await _metaBox?.delete(_timestampKey);
  }

  /// Close boxes
  Future<void> close() async {
    await _box?.close();
    await _metaBox?.close();
  }
}
