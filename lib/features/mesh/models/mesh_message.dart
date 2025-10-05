import 'dart:convert';
import 'dart:typed_data';

/// Types of messages in the mesh network
enum MessageType {
  sos,       // Emergency SOS signal
  medical,   // Medical status update
  text,      // Text message
  location,  // GPS location update
  battery,   // Battery level update
  ping,      // Network discovery
  nasaData,  // NASA disaster data
}

/// Priority levels for message routing
enum MessagePriority {
  low(1),
  medium(5),
  high(8),
  critical(10);

  final int value;
  const MessagePriority(this.value);
}

/// Message for mesh network communication
class MeshMessage {
  final String messageId;
  final String senderId;
  final String? senderName; // Display name of sender
  final MessageType type;
  final MessagePriority priority;
  final int ttl; // Time-to-live (hops remaining)
  final DateTime timestamp;
  final Map<String, dynamic> payload;
  final List<String> seenBy; // Device IDs that relayed this message

  MeshMessage({
    required this.messageId,
    required this.senderId,
    this.senderName,
    required this.type,
    required this.priority,
    required this.ttl,
    required this.timestamp,
    required this.payload,
    this.seenBy = const [],
  });

  /// Create SOS message
  factory MeshMessage.sos({
    required String senderId,
    String? senderName,
    required double latitude,
    required double longitude,
  }) {
    return MeshMessage(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId,
      senderName: senderName,
      type: MessageType.sos,
      priority: MessagePriority.critical,
      ttl: 10,
      timestamp: DateTime.now(),
      payload: {
        'lat': latitude,
        'lon': longitude,
      },
    );
  }

  /// Create text message
  factory MeshMessage.text({
    required String senderId,
    String? senderName,
    required String content,
  }) {
    return MeshMessage(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId,
      senderName: senderName,
      type: MessageType.text,
      priority: MessagePriority.high,
      ttl: 6,
      timestamp: DateTime.now(),
      payload: {'content': content},
    );
  }

  /// Create medical status message
  factory MeshMessage.medical({
    required String senderId,
    String? senderName,
    required String status, // 'safe', 'injured', 'critical'
  }) {
    return MeshMessage(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId,
      senderName: senderName,
      type: MessageType.medical,
      priority: MessagePriority.high,
      ttl: 8,
      timestamp: DateTime.now(),
      payload: {'status': status},
    );
  }

  /// Create location update message
  factory MeshMessage.location({
    required String senderId,
    String? senderName,
    required double latitude,
    required double longitude,
  }) {
    return MeshMessage(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId,
      senderName: senderName,
      type: MessageType.location,
      priority: MessagePriority.high,
      ttl: 5,
      timestamp: DateTime.now(),
      payload: {
        'lat': latitude,
        'lon': longitude,
      },
    );
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() => {
        'id': messageId,
        'sender': senderId,
        'senderName': senderName,
        'type': type.index,
        'priority': priority.value,
        'ttl': ttl,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'payload': payload,
        'seen': seenBy,
      };

  /// Deserialize from JSON
  factory MeshMessage.fromJson(Map<String, dynamic> json) {
    return MeshMessage(
      messageId: json['id'],
      senderId: json['sender'],
      senderName: json['senderName'] as String?,
      type: MessageType.values[json['type']],
      priority: MessagePriority.values.firstWhere(
        (p) => p.value == json['priority'],
        orElse: () => MessagePriority.medium,
      ),
      ttl: json['ttl'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      payload: Map<String, dynamic>.from(json['payload']),
      seenBy: List<String>.from(json['seen'] ?? []),
    );
  }

  /// Serialize to bytes for BLE transmission
  Uint8List toBytes() {
    final jsonString = jsonEncode(toJson());
    return Uint8List.fromList(utf8.encode(jsonString));
  }

  /// Deserialize from bytes
  factory MeshMessage.fromBytes(Uint8List bytes) {
    final jsonString = utf8.decode(bytes);
    final json = jsonDecode(jsonString);
    return MeshMessage.fromJson(json);
  }

  /// Create a copy for relaying (decrement TTL, add to seenBy)
  MeshMessage relay(String relayerId) {
    return MeshMessage(
      messageId: messageId,
      senderId: senderId,
      senderName: senderName,
      type: type,
      priority: priority,
      ttl: ttl - 1,
      timestamp: timestamp,
      payload: payload,
      seenBy: [...seenBy, relayerId],
    );
  }

  /// Check if message should be relayed
  bool get shouldRelay => ttl > 0;

  /// Check if message has been seen by device
  bool hasBeenSeenBy(String deviceId) => seenBy.contains(deviceId);

  @override
  String toString() {
    return 'MeshMessage(id: $messageId, type: $type, sender: $senderId, ttl: $ttl)';
  }
}
