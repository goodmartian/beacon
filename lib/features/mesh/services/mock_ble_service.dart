import 'dart:async';
import 'dart:math';

/// Mock BLE service for testing without real Bluetooth hardware
/// Simulates multiple virtual devices and mesh behavior
class MockBleService {
  final List<MockDevice> _virtualDevices = [];
  final _discoveredDevicesController = StreamController<List<MockDevice>>.broadcast();
  final _messagesController = StreamController<Map<String, dynamic>>.broadcast();

  bool _isScanning = false;
  Timer? _discoveryTimer;
  Timer? _messageSimulationTimer;

  Stream<List<MockDevice>> get discoveredDevices => _discoveredDevicesController.stream;
  Stream<Map<String, dynamic>> get incomingMessages => _messagesController.stream;

  /// Initialize mock BLE
  Future<bool> initialize() async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Create 3 virtual devices
    _virtualDevices.addAll([
      MockDevice(id: 'virtual-001', name: 'Mock Device 1', rssi: -45),
      MockDevice(id: 'virtual-002', name: 'Mock Device 2', rssi: -60),
      MockDevice(id: 'virtual-003', name: 'Mock Device 3', rssi: -75),
    ]);

    print('✅ Mock BLE initialized with ${_virtualDevices.length} virtual devices');
    return true;
  }

  /// Start scanning (simulate device discovery)
  Future<void> startScanning() async {
    if (_isScanning) return;

    _isScanning = true;
    print('🔍 Mock BLE scanning started');

    // Simulate gradual device discovery
    _discoveryTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (timer.tick <= _virtualDevices.length) {
        final discovered = _virtualDevices.take(timer.tick).toList();
        _discoveredDevicesController.add(discovered);
        print('📡 Discovered ${discovered.length} virtual devices');
      }
    });

    // Simulate random incoming messages
    _messageSimulationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _simulateIncomingMessage();
    });
  }

  /// Stop scanning
  Future<void> stopScanning() async {
    _isScanning = false;
    _discoveryTimer?.cancel();
    _messageSimulationTimer?.cancel();
    print('🛑 Mock BLE scanning stopped');
  }

  /// Simulate sending a message
  Future<bool> sendMessage(String deviceId, List<int> data) async {
    await Future.delayed(const Duration(milliseconds: 100));
    print('📤 Mock sent message to $deviceId (${data.length} bytes)');

    // Simulate echo back after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      _messagesController.add({
        'from': deviceId,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    });

    return true;
  }

  /// Simulate random incoming message
  void _simulateIncomingMessage() {
    if (_virtualDevices.isEmpty) return;

    final random = Random();
    final device = _virtualDevices[random.nextInt(_virtualDevices.length)];

    final messageTypes = ['text', 'sos', 'medical', 'location'];
    final type = messageTypes[random.nextInt(messageTypes.length)];

    print('📥 Mock received $type message from ${device.name}');

    _messagesController.add({
      'from': device.id,
      'type': type,
      'data': _generateMockMessageData(type),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  List<int> _generateMockMessageData(String type) {
    // Generate realistic mock data
    final random = Random();

    switch (type) {
      case 'sos':
        return List.generate(128, (_) => random.nextInt(256));
      case 'text':
        return List.generate(512, (_) => random.nextInt(256));
      case 'medical':
        return List.generate(64, (_) => random.nextInt(256));
      case 'location':
        return List.generate(64, (_) => random.nextInt(256));
      default:
        return List.generate(32, (_) => random.nextInt(256));
    }
  }

  /// Get virtual device count
  int get deviceCount => _virtualDevices.length;

  /// Dispose resources
  void dispose() {
    stopScanning();
    _discoveredDevicesController.close();
    _messagesController.close();
  }
}

class MockDevice {
  final String id;
  final String name;
  final int rssi; // Signal strength

  MockDevice({
    required this.id,
    required this.name,
    required this.rssi,
  });

  @override
  String toString() => '$name ($id) [RSSI: $rssi]';
}
