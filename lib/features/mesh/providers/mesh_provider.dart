import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/mesh_message.dart';
import '../services/mesh_network.dart';
import '../../emergency/models/radar_device.dart';

/// Provider for mesh network state management
class MeshProvider extends ChangeNotifier {
  final MeshNetworkService _meshNetwork = MeshNetworkService();

  bool _isInitialized = false;
  bool _isRunning = false;
  int _deviceCount = 0;
  final List<MeshMessage> _messages = [];
  final List<MeshMessage> _sosMessages = [];
  final List<ScanResult> _discoveredDevices = [];
  final Map<String, String> _deviceStatuses = {}; // deviceId -> medical status
  String? _deviceId;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isRunning => _isRunning;
  int get deviceCount => _deviceCount;
  List<MeshMessage> get messages => List.unmodifiable(_messages);
  List<MeshMessage> get sosMessages => List.unmodifiable(_sosMessages);
  List<ScanResult> get discoveredDevices => List.unmodifiable(_discoveredDevices);
  List<BluetoothDevice> get connectedDevices => _meshNetwork.connectedDevices;
  String? get deviceId => _deviceId;
  String get shortDeviceId => _deviceId?.substring(0, 8) ?? 'Unknown';

  /// Set user name for messages
  void setUserName(String? name) {
    _meshNetwork.setUserName(name);
  }

  /// Initialize mesh network
  Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    try {
      final success = await _meshNetwork.initialize();
      if (success) {
        _isInitialized = true;
        _deviceId = _meshNetwork.deviceId;

        // Listen for messages
        _meshNetwork.messages.listen(_onMessageReceived);
        _meshNetwork.sosMessages.listen(_onSOSReceived);

        // Listen for discovered devices
        _meshNetwork.discoveredDevices.listen(_onDevicesDiscovered);

        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error initializing mesh provider: $e');
      return false;
    }
  }

  /// Start mesh network
  Future<void> start({bool emergencyMode = false}) async {
    if (!_isInitialized) {
      await initialize();
    }

    await _meshNetwork.start(emergencyMode: emergencyMode);
    _isRunning = true;

    // Start periodic device count updates
    _startDeviceCountUpdates();

    notifyListeners();
  }

  /// Stop mesh network
  Future<void> stop() async {
    await _meshNetwork.stop();
    _isRunning = false;
    notifyListeners();
  }

  /// Broadcast SOS
  Future<void> broadcastSOS({
    required double latitude,
    required double longitude,
  }) async {
    await _meshNetwork.broadcastSOS(
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Send text message
  Future<void> sendTextMessage(String content) async {
    await _meshNetwork.sendTextMessage(content);
  }

  /// Send medical status
  Future<void> sendMedicalStatus(String status) async {
    await _meshNetwork.sendMedicalStatus(status);
  }

  /// Send location update
  Future<void> sendLocationUpdate({
    required double latitude,
    required double longitude,
  }) async {
    await _meshNetwork.sendLocationUpdate(
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Handle received message
  void _onMessageReceived(MeshMessage message) {
    _messages.add(message);

    // Track medical status updates
    if (message.type == MessageType.medical) {
      final status = message.payload['status'] as String?;
      if (status != null) {
        _deviceStatuses[message.senderId] = status;
      }
    }

    // Keep only last 100 messages to prevent memory issues
    if (_messages.length > 100) {
      _messages.removeRange(0, _messages.length - 100);
    }

    notifyListeners();
  }

  /// Handle received SOS
  void _onSOSReceived(MeshMessage message) {
    _sosMessages.add(message);

    // Keep only last 50 SOS messages
    if (_sosMessages.length > 50) {
      _sosMessages.removeRange(0, _sosMessages.length - 50);
    }

    notifyListeners();
  }

  /// Handle discovered devices
  void _onDevicesDiscovered(List<ScanResult> devices) {
    _discoveredDevices.clear();
    _discoveredDevices.addAll(devices);
    notifyListeners();
  }

  /// Start periodic device count updates
  void _startDeviceCountUpdates() {
    Future.doWhile(() async {
      if (!_isRunning) return false;

      await Future.delayed(const Duration(seconds: 2));

      final newCount = _meshNetwork.deviceCount;
      if (newCount != _deviceCount) {
        _deviceCount = newCount;
        notifyListeners();
      }

      return _isRunning;
    });
  }

  /// Get messages by type
  List<MeshMessage> getMessagesByType(MessageType type) {
    return _messages.where((m) => m.type == type).toList();
  }

  /// Clear all messages
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  /// Clear SOS messages
  void clearSOSMessages() {
    _sosMessages.clear();
    notifyListeners();
  }

  /// Connect to a device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    final success = await _meshNetwork.connectToDevice(device);
    notifyListeners();
    return success;
  }

  /// Disconnect from a device
  Future<void> disconnectFromDevice(BluetoothDevice device) async {
    await _meshNetwork.disconnectFromDevice(device);
    notifyListeners();
  }

  /// Convert discovered BLE devices to RadarDevice list
  List<RadarDevice> getRadarDevices() {
    final radarDevices = <RadarDevice>[];
    final random = math.Random();

    for (int i = 0; i < _discoveredDevices.length; i++) {
      final scanResult = _discoveredDevices[i];
      final deviceId = scanResult.device.remoteId.toString();

      // Estimate distance from RSSI (rough approximation)
      // RSSI typically ranges from -30 (very close) to -100 (far)
      final distance = _estimateDistanceFromRSSI(scanResult.rssi);

      // Distribute devices evenly around the circle for demo
      // In production, this would use actual GPS bearing
      final bearing = (i * 360.0 / math.max(_discoveredDevices.length, 1)) % 360;

      // Determine status based on medical messages or SOS
      final status = _getDeviceStatus(deviceId);

      // Signal strength normalized to 0-1
      final signalStrength = ((scanResult.rssi + 100) / 70).clamp(0.0, 1.0);

      radarDevices.add(RadarDevice(
        id: deviceId,
        distance: distance,
        bearing: bearing,
        status: status,
        signalStrength: signalStrength,
        lastSeen: DateTime.now(),
        name: scanResult.device.platformName.isNotEmpty
            ? scanResult.device.platformName
            : null,
      ));
    }

    return radarDevices;
  }

  /// Estimate distance in meters from RSSI
  /// Using simplified path loss formula
  double _estimateDistanceFromRSSI(int rssi) {
    // Reference: RSSI at 1 meter for BLE is typically -59 dBm
    const txPower = -59;
    const pathLossExponent = 2.5; // 2-4 for indoor environments

    if (rssi == 0) return 100.0; // Unknown distance

    final ratio = (txPower - rssi) / (10 * pathLossExponent);
    final distance = math.pow(10, ratio).toDouble();

    // Clamp to reasonable range for display (0-200m)
    return distance.clamp(5.0, 200.0);
  }

  /// Get device status from messages
  DeviceStatus _getDeviceStatus(String deviceId) {
    // Check if device sent SOS
    final hasSOS = _sosMessages.any((msg) => msg.senderId == deviceId);
    if (hasSOS) return DeviceStatus.sos;

    // Check medical status
    final medicalStatus = _deviceStatuses[deviceId];
    if (medicalStatus == 'injured' || medicalStatus == 'critical') {
      return DeviceStatus.needHelp;
    }
    if (medicalStatus == 'safe') {
      return DeviceStatus.safe;
    }

    // Check if device is relaying messages (has sent messages but no status)
    final hasMessages = _messages.any((msg) => msg.senderId == deviceId);
    if (hasMessages) {
      return DeviceStatus.relay;
    }

    // Default to safe
    return DeviceStatus.safe;
  }

  @override
  void dispose() {
    _meshNetwork.dispose();
    super.dispose();
  }
}
