import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../providers/chat_provider.dart';
import '../providers/emergency_provider.dart';
import '../widgets/message_card.dart';
import '../models/chat_message.dart';
import '../../mesh/models/mesh_message.dart';

/// Emergency chat screen - specialized message interface for disaster coordination
class EmergencyChatScreen extends StatefulWidget {
  const EmergencyChatScreen({super.key});

  @override
  State<EmergencyChatScreen> createState() => _EmergencyChatScreenState();
}

class _EmergencyChatScreenState extends State<EmergencyChatScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.emergencyBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildMessageList()),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  /// Header section (20% of screen) - Critical information
  Widget _buildHeader() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final sosCount = chatProvider.sosCount;
        final peopleCount = chatProvider.totalPeople;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: sosCount > 0 ? AppColors.sosRed : AppColors.bgTertiary,
            boxShadow: [
              BoxShadow(
                color: sosCount > 0
                    ? AppColors.sosRed.withOpacity(0.3)
                    : Colors.black26,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top bar with back button
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Spacer(),
                  Text(
                    'EMERGENCY CHAT',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), // Balance for back button
                ],
              ),

              const SizedBox(height: 4),

              // SOS count (if any)
              if (sosCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emergency, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '$sosCount ACTIVE SOS ${sosCount > 1 ? "SIGNALS" : "SIGNAL"}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // People count
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$peopleCount',
                    style: const TextStyle(
                      color: AppColors.deviceSafe,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        peopleCount == 1 ? 'PERSON' : 'PEOPLE',
                        style: const TextStyle(
                          color: AppColors.deviceSafe,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const Text(
                        'NEARBY',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Message list section (60% of screen) - Scrollable cards
  Widget _buildMessageList() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final messages = chatProvider.messages;

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.message,
                  size: 64,
                  color: Colors.white.withOpacity(0.2),
                ),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Messages will appear as people join',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return MessageCard(
              message: message,
              onHelpTap: message.meshMessage.type == MessageType.sos
                  ? () => _respondToSOS(chatProvider, message)
                  : null,
              onTap: () => _showMessageDetails(message),
            );
          },
        );
      },
    );
  }

  /// Quick actions section (20% of screen) - Large buttons
  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Text input (always visible)
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgPrimary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.info.withOpacity(0.3),
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        maxLength: 100,
                        maxLines: 1,
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(
                            color: Colors.white38,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          counterText: '',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Send button
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.info, Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.info.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _sendTextMessage,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
            const SizedBox(height: 8),

          // Quick action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickButton(
                icon: Icons.emergency,
                label: 'SOS',
                color: AppColors.sosRed,
                onTap: () => _sendQuickAction('sos'),
              ),
              _buildQuickButton(
                icon: Icons.help,
                label: 'HELP',
                color: AppColors.warning,
                onTap: () => _sendQuickAction('help'),
              ),
              _buildQuickButton(
                icon: Icons.check_circle,
                label: 'SAFE',
                color: AppColors.success,
                onTap: () => _sendQuickAction('safe'),
              ),
              _buildQuickButton(
                icon: Icons.location_on,
                label: 'LOCATION',
                color: AppColors.info,
                onTap: () => _sendQuickAction('location'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: Colors.white),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendQuickAction(String action) async {
    final chatProvider = context.read<ChatProvider>();
    await chatProvider.sendQuickAction(action);

    if (!mounted) return;

    // Show feedback
    String message = '';
    switch (action) {
      case 'sos':
        message = 'SOS broadcast sent';
        break;
      case 'help':
        message = 'Help request sent';
        break;
      case 'safe':
        message = 'Safe status sent';
        break;
      case 'location':
        message = 'Location shared';
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _sendTextMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final chatProvider = context.read<ChatProvider>();
    await chatProvider.sendTextMessage(text);

    _textController.clear();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message sent'),
        duration: Duration(seconds: 1),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _respondToSOS(ChatProvider chatProvider, ChatMessage sosMessage) async {
    await chatProvider.respondToSOS(sosMessage);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Response sent - going to help'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _showMessageDetails(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgTertiary,
        title: Row(
          children: [
            Icon(
              _getMessageIcon(message),
              color: _getMessageColor(message),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Message Details',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Sender', message.meshMessage.senderId.substring(0, 16)),
            _detailRow('Distance', message.formattedDistance),
            _detailRow('Direction', message.bearingArrow),
            _detailRow('Time', message.formattedAge),
            if (message.batteryLevel != null)
              _detailRow('Battery', '${message.batteryLevel}%'),
            if (message.duplicateCount > 1)
              _detailRow('Reports', '${message.duplicateCount} people'),
            const SizedBox(height: 12),
            Text(
              message.contentText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMessageIcon(ChatMessage message) {
    final type = message.meshMessage.type;
    if (type == MessageType.sos) {
      return Icons.emergency;
    } else if (type == MessageType.medical) {
      return Icons.local_hospital;
    } else if (type == MessageType.text) {
      return Icons.message;
    } else if (type == MessageType.location) {
      return Icons.location_on;
    } else {
      return Icons.info;
    }
  }

  Color _getMessageColor(ChatMessage message) {
    final type = message.meshMessage.type;
    if (type == MessageType.sos) {
      return AppColors.sosRed;
    } else if (type == MessageType.medical) {
      return AppColors.warning;
    } else if (type == MessageType.text) {
      return AppColors.info;
    } else {
      return Colors.white70;
    }
  }
}
