import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../../mesh/models/mesh_message.dart';
import '../../mesh/providers/mesh_provider.dart';

/// Provider for emergency chat state and message management
class ChatProvider extends ChangeNotifier {
  final MeshProvider _meshProvider;

  // User location for distance calculations
  double? _userLatitude;
  double? _userLongitude;
  double? _userBearing;
  int? _userBattery;

  // Processed chat messages
  final List<ChatMessage> _chatMessages = [];

  // Message grouping for deduplication
  final Map<String, List<ChatMessage>> _messageGroups = {};

  // Filters
  bool _showOnlySOS = false;
  bool _showOnlyNearby = false;
  double _nearbyRadiusMeters = 500;

  // Statistics
  int _sosCount = 0;
  int _medicalCount = 0;

  ChatProvider(this._meshProvider) {
    _init();
  }

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_chatMessages);
  int get sosCount => _sosCount;
  int get medicalCount => _medicalCount;
  int get totalPeople => _meshProvider.deviceCount;
  bool get showOnlySOS => _showOnlySOS;
  bool get showOnlyNearby => _showOnlyNearby;

  void _init() {
    // Listen to mesh provider for new messages
    _meshProvider.addListener(_onMeshUpdate);
    _refreshMessages();
  }

  /// Update user location for distance calculations
  void updateUserLocation({
    required double latitude,
    required double longitude,
    double? bearing,
    int? battery,
  }) {
    _userLatitude = latitude;
    _userLongitude = longitude;
    _userBearing = bearing;
    _userBattery = battery;

    // Recalculate distances for all messages
    _refreshMessages();
  }

  /// Refresh messages from mesh provider
  void _onMeshUpdate() {
    _refreshMessages();
  }

  /// Rebuild chat messages from mesh messages
  void _refreshMessages() {
    _chatMessages.clear();
    _messageGroups.clear();

    // Get all messages from mesh provider
    final allMeshMessages = [
      ..._meshProvider.messages,
      ..._meshProvider.sosMessages,
    ];

    // Convert to chat messages with metadata
    for (final meshMsg in allMeshMessages) {
      final chatMsg = ChatMessage.fromMeshMessage(
        meshMsg,
        userLatitude: _userLatitude,
        userLongitude: _userLongitude,
        userBearing: _userBearing,
        batteryLevel: _userBattery,
      );

      _chatMessages.add(chatMsg);
    }

    // Add presence notifications for devices without messages
    final radarDevices = _meshProvider.getRadarDevices();
    final devicesWithMessages = allMeshMessages.map((m) => m.senderId).toSet();

    for (final device in radarDevices) {
      if (!devicesWithMessages.contains(device.id)) {
        // Create system message for device presence
        final presenceMsg = MeshMessage.text(
          senderId: 'SYSTEM',
          content: 'Device ${device.name ?? device.id.substring(0, 8)} is nearby (${device.distance.round()}m)',
        );

        final chatMsg = ChatMessage(
          meshMessage: presenceMsg,
          role: SenderRole.system,
          distanceMeters: device.distance,
          bearingDegrees: device.bearing,
        );

        _chatMessages.add(chatMsg);
      }
    }

    // Group duplicate messages
    _groupDuplicateMessages();

    // Sort by priority and distance
    _sortMessages();

    // Apply filters
    _applyFilters();

    // Update statistics
    _updateStatistics();

    notifyListeners();
  }

  /// Group messages with identical content
  void _groupDuplicateMessages() {
    _messageGroups.clear();

    for (final msg in _chatMessages) {
      final key = '${msg.meshMessage.type}_${msg.contentText}';

      if (!_messageGroups.containsKey(key)) {
        _messageGroups[key] = [];
      }

      _messageGroups[key]!.add(msg);
    }

    // Replace duplicates with single message showing count
    final deduplicatedMessages = <ChatMessage>[];

    for (final group in _messageGroups.values) {
      if (group.isEmpty) continue;

      // Keep the closest/most recent message
      final primary = group.reduce((a, b) {
        // Prefer closer messages
        if (a.distanceMeters != null && b.distanceMeters != null) {
          return a.distanceMeters! < b.distanceMeters! ? a : b;
        }
        // Otherwise prefer more recent
        return a.age < b.age ? a : b;
      });

      // Create grouped message
      final grouped = ChatMessage(
        meshMessage: primary.meshMessage,
        role: primary.role,
        distanceMeters: primary.distanceMeters,
        bearingDegrees: primary.bearingDegrees,
        batteryLevel: primary.batteryLevel,
        duplicateCount: group.length,
        groupId: group.map((m) => m.meshMessage.senderId).join(','),
      );

      deduplicatedMessages.add(grouped);
    }

    _chatMessages.clear();
    _chatMessages.addAll(deduplicatedMessages);
  }

  /// Sort messages by priority and distance
  void _sortMessages() {
    _chatMessages.sort((a, b) {
      // First by priority (descending)
      final priorityDiff = b.displayPriority - a.displayPriority;
      if (priorityDiff != 0) return priorityDiff;

      // Then by distance (ascending - closer first)
      if (a.distanceMeters != null && b.distanceMeters != null) {
        return a.distanceMeters!.compareTo(b.distanceMeters!);
      }

      // Then by age (ascending - newer first)
      return a.age.compareTo(b.age);
    });
  }

  /// Apply active filters
  void _applyFilters() {
    if (_showOnlySOS) {
      _chatMessages.removeWhere(
        (msg) => msg.meshMessage.type != MessageType.sos,
      );
    }

    if (_showOnlyNearby) {
      _chatMessages.removeWhere((msg) {
        if (msg.distanceMeters == null) return true;
        return msg.distanceMeters! > _nearbyRadiusMeters;
      });
    }

    // Remove messages older than 24 hours
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    _chatMessages.removeWhere(
      (msg) => msg.meshMessage.timestamp.isBefore(cutoff),
    );
  }

  /// Update statistics
  void _updateStatistics() {
    _sosCount = _chatMessages.where(
      (msg) => msg.meshMessage.type == MessageType.sos,
    ).length;

    _medicalCount = _chatMessages.where(
      (msg) => msg.meshMessage.type == MessageType.medical,
    ).length;
  }

  /// Toggle SOS filter
  void toggleSOSFilter() {
    _showOnlySOS = !_showOnlySOS;
    _refreshMessages();
  }

  /// Toggle nearby filter
  void toggleNearbyFilter() {
    _showOnlyNearby = !_showOnlyNearby;
    _refreshMessages();
  }

  /// Set nearby radius
  void setNearbyRadius(double meters) {
    _nearbyRadiusMeters = meters;
    if (_showOnlyNearby) {
      _refreshMessages();
    }
  }

  /// Send quick action message
  Future<void> sendQuickAction(String action) async {
    switch (action) {
      case 'sos':
        if (_userLatitude != null && _userLongitude != null) {
          await _meshProvider.broadcastSOS(
            latitude: _userLatitude!,
            longitude: _userLongitude!,
          );
        }
        break;
      case 'help':
        await _meshProvider.sendTextMessage('Need help');
        break;
      case 'safe':
        await _meshProvider.sendMedicalStatus('safe');
        break;
      case 'location':
        if (_userLatitude != null && _userLongitude != null) {
          await _meshProvider.sendLocationUpdate(
            latitude: _userLatitude!,
            longitude: _userLongitude!,
          );
        }
        break;
    }
  }

  /// Send custom text message
  Future<void> sendTextMessage(String content) async {
    await _meshProvider.sendTextMessage(content);
  }

  /// Mark as going to help for SOS
  Future<void> respondToSOS(ChatMessage sosMessage) async {
    await _meshProvider.sendTextMessage(
      'Heading to your location (${sosMessage.formattedDistance})',
    );
  }

  /// Get SOS messages in range
  List<ChatMessage> getSOSInRange(double radiusMeters) {
    return _chatMessages
        .where((msg) =>
            msg.meshMessage.type == MessageType.sos &&
            msg.distanceMeters != null &&
            msg.distanceMeters! <= radiusMeters)
        .toList();
  }

  /// Add system message
  void addSystemMessage(String content) {
    final systemMsg = MeshMessage.text(
      senderId: 'SYSTEM',
      content: content,
    );

    final chatMsg = ChatMessage(
      meshMessage: systemMsg,
      role: SenderRole.system,
    );

    _chatMessages.insert(0, chatMsg);
    notifyListeners();
  }

  @override
  void dispose() {
    _meshProvider.removeListener(_onMeshUpdate);
    super.dispose();
  }
}
