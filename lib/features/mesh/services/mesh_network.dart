import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/mesh_message.dart';
import '../../../core/utils/device_id.dart';
import 'ble_service.dart';

/// Mesh Network Service for message routing and relay
class MeshNetworkService {
  static final MeshNetworkService _instance = MeshNetworkService._internal();
  factory MeshNetworkService() => _instance;
  MeshNetworkService._internal();

  final BleService _bleService = BleService();
  final Map<String, DateTime> _seenMessages = {};
  final _messageController = StreamController<MeshMessage>.broadcast();
  final _sosController = StreamController<MeshMessage>.broadcast();

  Stream<MeshMessage> get messages => _messageController.stream;
  Stream<MeshMessage> get sosMessages => _sosController.stream;
  Stream<List<ScanResult>> get discoveredDevices => _bleService.discoveredDevices;

  String? _deviceId;
  String? _userName;
  bool _isInitialized = false;

  /// Set user name for messages
  void setUserName(String? name) {
    _userName = name;
  }

  /// Initialize mesh network
  Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    try {
      // Get device ID
      _deviceId = await DeviceIdManager.getDeviceId();

      // Initialize BLE
      final bleInitialized = await _bleService.initialize();
      if (!bleInitialized) {
        print('Failed to initialize BLE');
        return false;
      }

      _isInitialized = true;
      print('Mesh network initialized with device ID: $_deviceId');
      return true;
    } catch (e) {
      print('Error initializing mesh network: $e');
      return false;
    }
  }

  /// Start mesh network (scanning and listening)
  Future<void> start({bool emergencyMode = false}) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Start scanning for devices
    await _bleService.startScanning(emergencyMode: emergencyMode);

    // Listen for messages from connected devices
    _listenForMessages();

    print('Mesh network started');
  }

  /// Stop mesh network
  Future<void> stop() async {
    await _bleService.stopScanning();
    print('Mesh network stopped');
  }

  /// Broadcast SOS message
  Future<void> broadcastSOS({
    required double latitude,
    required double longitude,
  }) async {
    if (_deviceId == null) {
      print('Device ID not initialized');
      return;
    }

    final sosMessage = MeshMessage.sos(
      senderId: _deviceId!,
      senderName: _userName,
      latitude: latitude,
      longitude: longitude,
    );

    await _sendMessage(sosMessage);
    print('SOS broadcasted');
  }

  /// Send text message
  Future<void> sendTextMessage(String content) async {
    if (_deviceId == null) {
      print('Device ID not initialized');
      return;
    }

    final textMessage = MeshMessage.text(
      senderId: _deviceId!,
      senderName: _userName,
      content: content,
    );

    await _sendMessage(textMessage);
    print('Text message sent');
  }

  /// Send medical status
  Future<void> sendMedicalStatus(String status) async {
    if (_deviceId == null) {
      print('Device ID not initialized');
      return;
    }

    final medicalMessage = MeshMessage.medical(
      senderId: _deviceId!,
      senderName: _userName,
      status: status,
    );

    await _sendMessage(medicalMessage);
    print('Medical status sent: $status');
  }

  /// Send location update
  Future<void> sendLocationUpdate({
    required double latitude,
    required double longitude,
  }) async {
    if (_deviceId == null) {
      print('Device ID not initialized');
      return;
    }

    final locationMessage = MeshMessage.location(
      senderId: _deviceId!,
      senderName: _userName,
      latitude: latitude,
      longitude: longitude,
    );

    await _sendMessage(locationMessage);
    print('Location update sent');
  }

  /// Internal: Send message to all connected devices
  Future<void> _sendMessage(MeshMessage message) async {
    try {
      // Mark message as seen
      _markMessageSeen(message.messageId);

      // Serialize message
      final data = message.toBytes();

      // Broadcast to all connected devices
      await _bleService.broadcastMessage(data);

      // Emit to local stream
      _messageController.add(message);

      // If SOS, emit to SOS stream
      if (message.type == MessageType.sos) {
        _sosController.add(message);
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  /// Listen for incoming messages from connected devices
  void _listenForMessages() {
    for (var device in _bleService.connectedDevices) {
      _bleService.listenForMessages(device).listen((data) {
        _handleIncomingMessage(data);
      });
    }
  }

  /// Handle incoming message
  Future<void> _handleIncomingMessage(List<int> data) async {
    try {
      // Deserialize message
      final message = MeshMessage.fromBytes(Uint8List.fromList(data));

      // Check if already seen
      if (_hasSeenMessage(message.messageId)) {
        print('Message ${message.messageId} already seen, ignoring');
        return;
      }

      // Mark as seen
      _markMessageSeen(message.messageId);

      // Emit to local stream
      _messageController.add(message);

      // If SOS, emit to SOS stream
      if (message.type == MessageType.sos) {
        _sosController.add(message);
      }

      print('Received message: ${message.type} from ${message.senderId}');

      // Relay message if TTL > 0
      if (message.shouldRelay) {
        await _relayMessage(message);
      }
    } catch (e) {
      print('Error handling incoming message: $e');
    }
  }

  /// Relay message to other devices
  Future<void> _relayMessage(MeshMessage message) async {
    if (_deviceId == null) {
      return;
    }

    // Create relayed message (decrement TTL)
    final relayedMessage = message.relay(_deviceId!);

    // Send to all connected devices except sender
    final data = relayedMessage.toBytes();
    await _bleService.broadcastMessage(data);

    print('Relayed message ${message.messageId} (TTL: ${relayedMessage.ttl})');
  }

  /// Check if message has been seen
  bool _hasSeenMessage(String messageId) {
    if (!_seenMessages.containsKey(messageId)) {
      return false;
    }

    final seenTime = _seenMessages[messageId]!;
    final age = DateTime.now().difference(seenTime);

    // Remove old entries (older than 5 minutes)
    if (age.inMinutes > 5) {
      _seenMessages.remove(messageId);
      return false;
    }

    return true;
  }

  /// Mark message as seen
  void _markMessageSeen(String messageId) {
    _seenMessages[messageId] = DateTime.now();

    // Cleanup old entries periodically
    if (_seenMessages.length > 100) {
      _cleanupSeenMessages();
    }
  }

  /// Cleanup old seen messages
  void _cleanupSeenMessages() {
    final now = DateTime.now();
    _seenMessages.removeWhere((id, time) {
      return now.difference(time).inMinutes > 5;
    });
  }

  /// Get number of connected devices
  int get deviceCount => _bleService.deviceCount;

  /// Get connected devices
  List<BluetoothDevice> get connectedDevices => _bleService.connectedDevices;

  /// Get device ID
  String? get deviceId => _deviceId;

  /// Connect to a device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    return await _bleService.connectToDevice(device);
  }

  /// Disconnect from a device
  Future<void> disconnectFromDevice(BluetoothDevice device) async {
    await _bleService.disconnectFromDevice(device);
  }

  /// Dispose resources
  void dispose() {
    _bleService.dispose();
    _messageController.close();
    _sosController.close();
  }
}
