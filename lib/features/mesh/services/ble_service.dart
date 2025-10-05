import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/ble_constants.dart';

/// BLE Service for managing Bluetooth operations
class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  final _discoveredDevicesController =
      StreamController<List<ScanResult>>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();

  Stream<List<ScanResult>> get discoveredDevices =>
      _discoveredDevicesController.stream;
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  final List<BluetoothDevice> _connectedDevices = [];
  bool _isScanning = false;
  bool _isDisposed = false;

  List<BluetoothDevice> get connectedDevices => List.unmodifiable(_connectedDevices);
  bool get isScanning => _isScanning;

  /// Initialize BLE and request permissions
  Future<bool> initialize() async {
    try {
      // Check if Bluetooth is supported
      if (await FlutterBluePlus.isSupported == false) {
        print('Bluetooth not supported by this device');
        return false;
      }

      // Request permissions
      final permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        print('Bluetooth permissions not granted');
        return false;
      }

      // Check if Bluetooth is on
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        print('Bluetooth is not enabled');
        // Try to turn on Bluetooth
        await FlutterBluePlus.turnOn();
      }

      print('BLE initialized successfully');
      return true;
    } catch (e) {
      print('Error initializing BLE: $e');
      return false;
    }
  }

  /// Request necessary Bluetooth permissions
  Future<bool> _requestPermissions() async {
    final permissions = [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.location, // Required for BLE scanning on Android
    ];

    final statuses = await permissions.request();

    // Log permission statuses
    for (var permission in permissions) {
      final status = await permission.status;
      print('Permission ${permission.toString()}: ${status.toString()}');
    }

    // Check which permissions are granted
    final allGranted = statuses.values.every((status) => status.isGranted);
    if (!allGranted) {
      print('Some permissions were denied:');
      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          print('  - ${permission.toString()}: ${status.toString()}');
        }
      });
    }

    return allGranted;
  }

  /// Start scanning for Beacon devices
  Future<void> startScanning({bool emergencyMode = false}) async {
    if (_isScanning) {
      print('Already scanning');
      return;
    }

    try {
      _isScanning = true;

      // Clear previous scan results
      final scanResults = <ScanResult>[];

      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: Duration(milliseconds: BleConstants.scanTimeout),
        androidUsesFineLocation: true,
      );

      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        if (_isDisposed) return;

        scanResults.clear();

        // Filter only Beacon devices
        final beaconDevices = results.where((result) => _isBeaconDevice(result)).toList();
        scanResults.addAll(beaconDevices);

        if (!_discoveredDevicesController.isClosed) {
          _discoveredDevicesController.add(beaconDevices);
        }

        // Log only Beacon devices for debugging
        for (var result in beaconDevices) {
          print('✅ BEACON: ${result.device.platformName} (${result.device.remoteId})');
          print('   RSSI: ${result.rssi} dBm');
        }

        // Auto-connect to Beacon devices if in emergency mode
        if (emergencyMode) {
          for (var result in beaconDevices) {
            _autoConnect(result.device);
          }
        }
      });

      print('Started BLE scanning');
    } catch (e) {
      print('Error starting scan: $e');
      _isScanning = false;
    }
  }

  /// Stop scanning
  Future<void> stopScanning() async {
    try {
      await FlutterBluePlus.stopScan();
      _isScanning = false;
      print('Stopped BLE scanning');
    } catch (e) {
      print('Error stopping scan: $e');
    }
  }

  /// Check if device is a Beacon device
  bool _isBeaconDevice(ScanResult result) {
    // Check if device advertises Beacon service UUID
    final serviceUuids = result.advertisementData.serviceUuids;
    final beaconGuid = Guid(BleConstants.beaconServiceUuid);
    return serviceUuids.contains(beaconGuid);
  }

  /// Auto-connect to discovered Beacon device
  Future<void> _autoConnect(BluetoothDevice device) async {
    if (_connectedDevices.contains(device)) {
      return; // Already connected
    }

    if (_connectedDevices.length >= BleConstants.maxConnections) {
      print('Max connections reached');
      return;
    }

    await connectToDevice(device);
  }

  /// Connect to a specific device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      if (_connectedDevices.contains(device)) {
        print('Already connected to ${device.platformName}');
        return true;
      }

      await device.connect(
        timeout: Duration(milliseconds: BleConstants.connectionTimeout),
      );

      _connectedDevices.add(device);

      if (!_connectionStatusController.isClosed) {
        _connectionStatusController.add(true);
      }

      print('Connected to ${device.platformName}');
      return true;
    } catch (e) {
      print('Error connecting to device: $e');
      return false;
    }
  }

  /// Disconnect from a device
  Future<void> disconnectFromDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
      _connectedDevices.remove(device);

      if (!_connectionStatusController.isClosed) {
        _connectionStatusController.add(false);
      }

      print('Disconnected from ${device.platformName}');
    } catch (e) {
      print('Error disconnecting from device: $e');
    }
  }

  /// Disconnect from all devices
  Future<void> disconnectAll() async {
    for (var device in List.from(_connectedDevices)) {
      await disconnectFromDevice(device);
    }
  }

  /// Send message to a specific device
  Future<bool> sendMessage(BluetoothDevice device, List<int> data) async {
    try {
      // Discover services
      final services = await device.discoverServices();

      // Find Beacon service
      final beaconService = services.firstWhere(
        (service) => service.uuid.toString() == BleConstants.beaconServiceUuid,
        orElse: () => throw Exception('Beacon service not found'),
      );

      // Find message characteristic
      final messageChar = beaconService.characteristics.firstWhere(
        (char) => char.uuid.toString() == BleConstants.messageCharUuid,
        orElse: () => throw Exception('Message characteristic not found'),
      );

      // Write message
      await messageChar.write(data, withoutResponse: false);
      print('Message sent to ${device.platformName}');
      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  /// Broadcast message to all connected devices
  Future<void> broadcastMessage(List<int> data) async {
    for (var device in _connectedDevices) {
      await sendMessage(device, data);
    }
  }

  /// Listen for messages from a device
  Stream<List<int>> listenForMessages(BluetoothDevice device) async* {
    try {
      final services = await device.discoverServices();
      final beaconService = services.firstWhere(
        (service) => service.uuid.toString() == BleConstants.beaconServiceUuid,
      );

      final messageChar = beaconService.characteristics.firstWhere(
        (char) => char.uuid.toString() == BleConstants.messageCharUuid,
      );

      // Enable notifications
      await messageChar.setNotifyValue(true);

      // Listen for value changes
      await for (var value in messageChar.lastValueStream) {
        if (value.isNotEmpty) {
          yield value;
        }
      }
    } catch (e) {
      print('Error listening for messages: $e');
    }
  }

  /// Get device count
  int get deviceCount => _connectedDevices.length;

  /// Dispose resources
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    stopScanning();
    disconnectAll();

    if (!_discoveredDevicesController.isClosed) {
      _discoveredDevicesController.close();
    }
    if (!_connectionStatusController.isClosed) {
      _connectionStatusController.close();
    }
  }
}
