import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment variables configuration
class Env {
  /// NASA FIRMS Map API key
  static String get nasaFirmsMapKey {
    try {
      return dotenv.env['NASA_FIRMS_MAP_KEY'] ?? '';
    } catch (e) {
      // dotenv not initialized - return empty string (will use mock data)
      return '';
    }
  }

  /// Check if all required environment variables are loaded
  static bool get isConfigured => nasaFirmsMapKey.isNotEmpty;
}
