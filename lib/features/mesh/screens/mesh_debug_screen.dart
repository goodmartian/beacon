import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mesh_provider.dart';
import '../../../core/constants/colors.dart';

/// Debug screen for testing BLE mesh network
class MeshDebugScreen extends StatelessWidget {
  const MeshDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesh Network Debug'),
        backgroundColor: AppColors.safetyGreen,
      ),
      body: Consumer<MeshProvider>(
        builder: (context, meshProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusCard(meshProvider),
                const SizedBox(height: 16),
                _buildDevicesCard(context, meshProvider),
                const SizedBox(height: 16),
                _buildActionsCard(context, meshProvider),
                const SizedBox(height: 16),
                _buildMessagesCard(meshProvider),
                const SizedBox(height: 16),
                _buildSOSCard(meshProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(MeshProvider meshProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Network Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStatusRow('Initialized', meshProvider.isInitialized),
            _buildStatusRow('Running', meshProvider.isRunning),
            const Divider(height: 24),
            _buildInfoRow('Device ID', meshProvider.shortDeviceId),
            _buildInfoRow('Connected Devices', '${meshProvider.deviceCount}'),
            _buildInfoRow('Messages Received', '${meshProvider.messages.length}'),
            _buildInfoRow('SOS Signals', '${meshProvider.sosMessages.length}'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: value ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value ? 'YES' : 'NO',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesCard(BuildContext context, MeshProvider meshProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Discovered Beacon Devices',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (meshProvider.discoveredDevices.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No Beacon devices found.\nMake sure ESP32 is powered on.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ...meshProvider.discoveredDevices.map((result) {
              final device = result.device;
              final rssi = result.rssi;
              final name = device.platformName.isEmpty
                  ? 'Unknown Device'
                  : device.platformName;
              final isConnected = meshProvider.connectedDevices.contains(device);

              return Card(
                color: isConnected ? AppColors.safetyGreen.withOpacity(0.1) : null,
                child: ListTile(
                  leading: Icon(
                    isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                    color: isConnected ? AppColors.safetyGreen : AppColors.info,
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'MAC: ${device.remoteId}\n'
                    'RSSI: $rssi dBm\n'
                    'Services: ${result.advertisementData.serviceUuids.join(", ")}',
                  ),
                  trailing: Builder(
                    builder: (btnContext) => ElevatedButton(
                      onPressed: () async {
                        if (isConnected) {
                          await meshProvider.disconnectFromDevice(device);
                          if (!btnContext.mounted) return;
                          ScaffoldMessenger.of(btnContext).showSnackBar(
                            SnackBar(content: Text('Disconnected from $name')),
                          );
                        } else {
                          final success = await meshProvider.connectToDevice(device);
                          if (!btnContext.mounted) return;
                          ScaffoldMessenger.of(btnContext).showSnackBar(
                            SnackBar(
                              content: Text(success
                                ? 'Connected to $name'
                                : 'Failed to connect to $name'),
                              backgroundColor: success ? Colors.green : Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isConnected ? AppColors.warning : AppColors.safetyGreen,
                      ),
                      child: Text(isConnected ? 'Disconnect' : 'Connect'),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, MeshProvider meshProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (!meshProvider.isInitialized)
              ElevatedButton.icon(
                onPressed: () async {
                  final success = await meshProvider.initialize();
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Mesh network initialized'
                            : 'Failed to initialize. Check Bluetooth permissions.',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                },
                icon: const Icon(Icons.power_settings_new),
                label: const Text('Initialize Mesh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.safetyGreen,
                ),
              ),
            if (meshProvider.isInitialized && !meshProvider.isRunning)
              ElevatedButton.icon(
                onPressed: () => meshProvider.start(),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Scanning'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.info,
                ),
              ),
            if (meshProvider.isRunning)
              ElevatedButton.icon(
                onPressed: () => meshProvider.stop(),
                icon: const Icon(Icons.stop),
                label: const Text('Stop Scanning'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                ),
              ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                await meshProvider.broadcastSOS(
                  latitude: 37.7749,
                  longitude: -122.4194,
                );
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('SOS broadcasted to mesh network'),
                    backgroundColor: AppColors.sosRed,
                  ),
                );
              },
              icon: const Icon(Icons.emergency),
              label: const Text('Send Test SOS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sosRed,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showTextMessageDialog(context, meshProvider),
              icon: const Icon(Icons.message),
              label: const Text('Send Test Message'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                meshProvider.clearMessages();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Messages cleared')),
                );
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Messages'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesCard(MeshProvider meshProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Received Messages',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (meshProvider.messages.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No messages yet.\nSend a test message to see it here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ...meshProvider.messages.reversed.take(5).map((message) {
              return ListTile(
                leading: Icon(
                  _getMessageIcon(message.type.name),
                  color: _getMessageColor(message.type.name),
                ),
                title: Text(
                  message.type.name.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'From: ${message.senderId.substring(0, 8)}\n'
                  'TTL: ${message.ttl} | Priority: ${message.priority.value}',
                ),
                trailing: Text(
                  _formatTime(message.timestamp),
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }),
            if (meshProvider.messages.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    '+${meshProvider.messages.length - 5} more messages',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSCard(MeshProvider meshProvider) {
    return Card(
      color: AppColors.sosRed.withAlpha(30),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.emergency, color: AppColors.sosRed),
                SizedBox(width: 8),
                Text(
                  'SOS Signals',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sosRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (meshProvider.sosMessages.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No SOS signals received',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ...meshProvider.sosMessages.reversed.take(3).map((sos) {
              final payload = sos.payload;
              return ListTile(
                leading: const Icon(Icons.error, color: AppColors.sosRed),
                title: Text(
                  'SOS from ${sos.senderId.substring(0, 8)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Location: ${payload['lat']}, ${payload['lon']}\n'
                  'Time: ${_formatTime(sos.timestamp)}',
                ),
                trailing: Text(
                  'TTL: ${sos.ttl}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.sosRed,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showTextMessageDialog(BuildContext context, MeshProvider meshProvider) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Test Message'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Type your message...',
            border: OutlineInputBorder(),
          ),
          maxLength: 100,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final message = textController.text.trim();
              if (message.isNotEmpty) {
                meshProvider.sendTextMessage(message);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message sent to mesh network')),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  IconData _getMessageIcon(String type) {
    switch (type) {
      case 'sos':
        return Icons.emergency;
      case 'medical':
        return Icons.medical_services;
      case 'text':
        return Icons.message;
      case 'location':
        return Icons.location_on;
      case 'battery':
        return Icons.battery_std;
      default:
        return Icons.info;
    }
  }

  Color _getMessageColor(String type) {
    switch (type) {
      case 'sos':
        return AppColors.sosRed;
      case 'medical':
        return AppColors.hazardAmber;
      case 'text':
        return AppColors.info;
      case 'location':
        return AppColors.safetyGreen;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
    }
  }
}
