import 'package:flutter/foundation.dart';
import '../../../core/services/foreground_service.dart';

/// Emergency mode states
enum EmergencyState {
  normal,     // Normal operation
  emergency,  // Emergency mode activated
}

/// Provider for emergency mode state management
class EmergencyProvider extends ChangeNotifier {
  EmergencyState _state = EmergencyState.normal;
  DateTime? _emergencyActivatedAt;
  bool _autoActivated = false;

  // Getters
  EmergencyState get state => _state;
  bool get isEmergency => _state == EmergencyState.emergency;
  bool get isNormal => _state == EmergencyState.normal;
  DateTime? get emergencyActivatedAt => _emergencyActivatedAt;
  bool get autoActivated => _autoActivated;

  /// Duration since emergency was activated
  Duration? get emergencyDuration {
    if (_emergencyActivatedAt == null) return null;
    return DateTime.now().difference(_emergencyActivatedAt!);
  }

  /// Activate emergency mode
  Future<void> activateEmergency({bool auto = false}) async {
    if (_state == EmergencyState.emergency) {
      debugPrint('Emergency mode already active');
      return;
    }

    _state = EmergencyState.emergency;
    _emergencyActivatedAt = DateTime.now();
    _autoActivated = auto;

    // Start foreground service for background BLE scanning
    await ForegroundService.start();

    debugPrint('Emergency mode activated (auto: $auto)');
    notifyListeners();
  }

  /// Deactivate emergency mode
  Future<void> deactivateEmergency() async {
    if (_state == EmergencyState.normal) {
      debugPrint('Already in normal mode');
      return;
    }

    _state = EmergencyState.normal;
    _emergencyActivatedAt = null;
    _autoActivated = false;

    // Stop foreground service
    await ForegroundService.stop();

    debugPrint('Emergency mode deactivated');
    notifyListeners();
  }

  /// Toggle emergency mode
  void toggleEmergency() {
    if (_state == EmergencyState.emergency) {
      deactivateEmergency();
    } else {
      activateEmergency();
    }
  }
}
