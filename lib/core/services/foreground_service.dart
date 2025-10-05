import 'package:flutter/services.dart';

/// Foreground Service for Emergency Mode
/// Keeps BLE mesh network running in background
class ForegroundService {
  static const platform = MethodChannel('beacon/foreground');

  /// Start foreground service with persistent notification
  static Future<void> start() async {
    try {
      await platform.invokeMethod('startForeground');
      print('Foreground service started');
    } catch (e) {
      print('Error starting foreground service: $e');
    }
  }

  /// Stop foreground service
  static Future<void> stop() async {
    try {
      await platform.invokeMethod('stopForeground');
      print('Foreground service stopped');
    } catch (e) {
      print('Error stopping foreground service: $e');
    }
  }
}
