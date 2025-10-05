import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/emergency_provider.dart';
import '../../mesh/providers/mesh_provider.dart';
import '../widgets/normal_mode.dart';
import '../widgets/emergency_mode.dart';

/// Main screen that switches between Normal and Emergency modes
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    final meshProvider = context.read<MeshProvider>();
    final emergencyProvider = context.read<EmergencyProvider>();

    // Initialize mesh network
    final initialized = await meshProvider.initialize();
    if (!initialized) {
      _showError('Failed to initialize Bluetooth. Please check permissions.');
      return;
    }

    // Start mesh network
    await meshProvider.start(emergencyMode: emergencyProvider.isEmergency);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EmergencyProvider>(
      builder: (context, emergencyProvider, child) {
        // Switch between Normal and Emergency mode
        return emergencyProvider.isEmergency
            ? const EmergencyModeWidget()
            : const NormalModeWidget();
      },
    );
  }
}
