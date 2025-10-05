/// Bluetooth Low Energy constants for Beacon mesh network
class BleConstants {
  // Service and Characteristic UUIDs
  static const String beaconServiceUuid = '12345678-1234-5678-1234-56789abcdef0';
  static const String messageCharUuid = '12345678-1234-5678-1234-56789abcdef1';
  static const String statusCharUuid = '12345678-1234-5678-1234-56789abcdef2';
  static const String locationCharUuid = '12345678-1234-5678-1234-56789abcdef3';
  static const String batteryCharUuid = '12345678-1234-5678-1234-56789abcdef4';

  // Connection Parameters
  static const int maxConnections = 7; // Android BLE limit
  static const int connectionTimeout = 5000; // milliseconds
  static const int scanTimeout = 10000; // milliseconds

  // Advertisement Parameters
  static const int advertisementIntervalNormal = 1000; // ms
  static const int advertisementIntervalEmergency = 250; // ms

  // Message Parameters
  static const int maxMessageSize = 512; // bytes
  static const int deduplicationWindowMinutes = 5;
}
