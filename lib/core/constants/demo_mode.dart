/// Demo mode configuration
/// Set to true for presentations, false for real usage
class DemoMode {
  // Master switch for demo mode
  static const bool enabled = true; // TODO: Set to false for production

  // Mock data settings
  static const bool useMockMesh = enabled;
  static const bool useMockNASA = enabled;
  static const bool useMockGPS = enabled;

  // Demo scenario settings
  static const int mockDeviceCount = 4;
  static const int mockSOSCount = 2;
  static const int mockFireCount = 5;

  // Animation speeds (faster for demo)
  static const Duration messageDelay = Duration(milliseconds: 500);
  static const Duration discoveryDelay = Duration(seconds: 2);
  static const Duration sosDelay = Duration(milliseconds: 800);
}
