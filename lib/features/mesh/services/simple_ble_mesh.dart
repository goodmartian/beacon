import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:permission_handler/permission_handler.dart';

/// Simplified BLE Mesh - focuses on basic peer-to-peer communication
/// Uses advertising data for message exchange (simpler than GATT)
class SimpleBLEMesh {
  static final SimpleBLEMesh _instance = SimpleBLEMesh._internal();
  factory SimpleBLEMesh() => _instance;
  SimpleBLEMesh._internal();

  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();
  final _messagesController = StreamController<Map<String, dynamic>>.broadcast();
  final _devicesController = StreamController<int>.broadcast();

  bool _isInitialized = false;
  bool _isRunning = false;
  String? _deviceId;
  final Set<String> _nearbyDevices = {};

  Stream<Map<String, dynamic>> get messages => _messagesController.stream;
  Stream<int> get deviceCount => _devicesController.stream;

  bool get isInitialized => _isInitialized;
  bool get isRunning => _isRunning;
  int get connectedDevices => _nearbyDevices.length;

  /// Initialize BLE mesh
  Future<bool> initialize(String deviceId) async {
    if (_isInitialized) return true;

    try {
      _deviceId = deviceId;

      // Request permissions
      final permissions = await _requestPermissions();
      if (!permissions) {
        print('❌ Permissions denied');
        return false;
      }

      // Check Bluetooth availability
      if (await FlutterBluePlus.isSupported == false) {
        print('❌ Bluetooth not supported');
        return false;
      }

      _isInitialized = true;
      print('✅ SimpleBLEMesh initialized');
      return true;
    } catch (e) {
      print('❌ Error initializing SimpleBLEMesh: $e');
      return false;
    }
  }

  /// Request necessary permissions
  Future<bool> _requestPermissions() async {
    final permissions = [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.location,
    ];

    final statuses = await permissions.request();
    final allGranted = statuses.values.every((status) => status.isGranted);

    if (!allGranted) {
      print('⚠️ Some permissions not granted:');
      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          print('  - $permission: $status');
        }
      });
    }

    return allGranted;
  }

  /// Start mesh network (advertising + scanning)
  Future<void> start() async {
    if (!_isInitialized || _isRunning) return;

    try {
      // Start advertising (make this device discoverable)
      await _startAdvertising();

      // Start scanning (discover other devices)
      await _startScanning();

      _isRunning = true;
      print('✅ SimpleBLEMesh started');
    } catch (e) {
      print('❌ Error starting SimpleBLEMesh: $e');
    }
  }

  /// Stop mesh network
  Future<void> stop() async {
    if (!_isRunning) return;

    try {
      await _peripheral.stop();
      await FlutterBluePlus.stopScan();

      _isRunning = false;
      _nearbyDevices.clear();
      _devicesController.add(0);

      print('✅ SimpleBLEMesh stopped');
    } catch (e) {
      print('❌ Error stopping SimpleBLEMesh: $e');
    }
  }

  /// Start advertising this device
  Future<void> _startAdvertising() async {
    try {
      // Create advertisement data with device ID
      final advertiseData = AdvertiseData(
        serviceUuid: 'beef', // Short UUID for Beacon
        manufacturerId: 0x004C, // Apple manufacturer ID
        manufacturerData: utf8.encode(_deviceId!.substring(0, 8)),
        includeDeviceName: false,
      );

      await _peripheral.start(advertiseData: advertiseData);
      print('📡 Advertising as Beacon device');
    } catch (e) {
      print('❌ Error starting advertising: $e');
    }
  }

  /// Start scanning for other devices
  Future<void> _startScanning() async {
    try {
      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        for (var result in results) {
          _processDiscoveredDevice(result);
        }
      });

      // Start continuous scanning
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 4),
        androidUsesFineLocation: true,
      );

      // Restart scan every 5 seconds
      Timer.periodic(const Duration(seconds: 5), (timer) async {
        if (!_isRunning) {
          timer.cancel();
          return;
        }

        await FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 4),
          androidUsesFineLocation: true,
        );
      });

      print('🔍 Scanning for Beacon devices');
    } catch (e) {
      print('❌ Error starting scanning: $e');
    }
  }

  /// Process discovered device
  void _processDiscoveredDevice(ScanResult result) {
    final deviceId = result.device.remoteId.toString();

    // Check if it's a Beacon device (has our service UUID or manufacturer data)
    final hasBeaconService = result.advertisementData.serviceUuids
        .any((uuid) => uuid.toString().contains('beef'));

    if (!hasBeaconService) return;

    // Add to nearby devices
    if (!_nearbyDevices.contains(deviceId)) {
      _nearbyDevices.add(deviceId);
      _devicesController.add(_nearbyDevices.length);
      print('📱 Discovered Beacon device: ${deviceId.substring(0, 8)}');
    }

    // Extract message from manufacturer data if present
    final manufacturerData = result.advertisementData.manufacturerData;
    if (manufacturerData.isNotEmpty) {
      _processReceivedData(deviceId, manufacturerData);
    }
  }

  /// Process received data from advertisement
  void _processReceivedData(String deviceId, Map<int, List<int>> manufacturerData) {
    try {
      // Extract data from first manufacturer entry
      final data = manufacturerData.values.first;
      if (data.isEmpty) return;

      // Try to decode as string
      final decoded = utf8.decode(data, allowMalformed: true);

      // Emit as message
      _messagesController.add({
        'from': deviceId,
        'data': decoded,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      print('📥 Received data from ${deviceId.substring(0, 8)}: $decoded');
    } catch (e) {
      print('⚠️ Error processing received data: $e');
    }
  }

  /// Broadcast message (via advertising data)
  Future<void> broadcastMessage(String message) async {
    if (!_isRunning) {
      print('⚠️ Mesh not running, cannot broadcast');
      return;
    }

    try {
      // Update advertisement data with message
      final advertiseData = AdvertiseData(
        serviceUuid: 'beef',
        manufacturerId: 0x004C,
        manufacturerData: utf8.encode(message.substring(0, message.length.clamp(0, 20))),
        includeDeviceName: false,
      );

      await _peripheral.stop();
      await _peripheral.start(advertiseData: advertiseData);

      print('📤 Broadcasting: $message');

      // Restore normal advertising after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        _startAdvertising();
      });
    } catch (e) {
      print('❌ Error broadcasting message: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    stop();
    _messagesController.close();
    _devicesController.close();
  }
}
