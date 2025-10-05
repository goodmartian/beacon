import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Manages unique device identifier for mesh network
class DeviceIdManager {
  static const String _deviceIdKey = 'beacon_device_id';
  static String? _cachedDeviceId;

  /// Get or create unique device ID
  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, deviceId);
    }

    _cachedDeviceId = deviceId;
    return deviceId;
  }

  /// Get short device ID for display (first 8 chars)
  static Future<String> getShortDeviceId() async {
    final fullId = await getDeviceId();
    return fullId.substring(0, 8);
  }
}
