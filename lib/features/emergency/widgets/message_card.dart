import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../models/chat_message.dart';
import '../../mesh/models/mesh_message.dart';

/// Message card with priority-based visual styling
class MessageCard extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onTap;
  final VoidCallback? onHelpTap;

  const MessageCard({
    super.key,
    required this.message,
    this.onTap,
    this.onHelpTap,
  });

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Pulsing animation for SOS messages
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.message.meshMessage.type == MessageType.sos) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Get sender display name (name if available, otherwise truncated ID)
  String _getSenderDisplay() {
    // For system messages, show "SYSTEM"
    if (widget.message.role == SenderRole.system) {
      return 'SYSTEM';
    }

    // Use sender name if available
    final senderName = widget.message.meshMessage.senderName;
    if (senderName != null && senderName.isNotEmpty) {
      return senderName;
    }

    // Fallback to truncated ID
    final senderId = widget.message.meshMessage.senderId;
    if (senderId.length < 16 && !senderId.contains('-')) {
      return senderId;
    }

    return senderId.substring(0, senderId.length > 12 ? 12 : senderId.length);
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;

    // System messages have different layout
    if (msg.meshMessage.type == MessageType.nasaData ||
        msg.role == SenderRole.system) {
      return _buildSystemMessage();
    }

    // SOS messages get special treatment
    if (msg.meshMessage.type == MessageType.sos) {
      return _buildSOSCard();
    }

    // Medical messages
    if (msg.meshMessage.type == MessageType.medical) {
      return _buildMedicalCard();
    }

    // Rescuer messages
    if (msg.role == SenderRole.rescuer) {
      return _buildRescuerCard();
    }

    // Regular text messages
    return _buildTextCard();
  }

  Widget _buildSOSCard() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.sosRed,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.sosRed.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.emergency, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SOS - EMERGENCY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'From: ${_getSenderDisplay()}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.message.contentText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildMetadataRow(),
              if (widget.onHelpTap != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onHelpTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.sosRed,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'GOING TO HELP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRescuerCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.info,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RESCUER - ${widget.message.meshMessage.senderId.substring(0, 8)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.message.contentText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildMetadataRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_hospital, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.message.contentText.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'From: ${_getSenderDisplay()}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildMetadataRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender ID/Name
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.deviceSafe,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _getSenderDisplay(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Message content
            Text(
              widget.message.contentText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _buildMetadataRow(compact: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.message.contentText,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow({bool compact = false}) {
    final msg = widget.message;
    final fontSize = compact ? 11.0 : 13.0;

    return Row(
      children: [
        // Distance and bearing
        if (msg.distanceMeters != null) ...[
          Text(
            msg.formattedDistance,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 16.0 : 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            msg.bearingArrow,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 16.0 : 20.0,
            ),
          ),
          const Spacer(),
        ],

        // Time ago
        Text(
          msg.formattedAge,
          style: TextStyle(
            color: Colors.white70,
            fontSize: fontSize,
          ),
        ),

        // Low battery indicator
        if (msg.isLowBattery) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.battery_alert,
            color: Colors.white,
            size: compact ? 14 : 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${msg.batteryLevel}%',
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
            ),
          ),
        ],

        // Duplicate count
        if (msg.duplicateCount > 1) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'x${msg.duplicateCount}',
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize - 1,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
