# Emergency Radar Component

A circular radar-style heatmap interface for Beacon's emergency mode, inspired by submarine sonar and emergency services UI.

## Components

### 1. `RadarDevice` Model (`models/radar_device.dart`)
Data model representing a device on the radar:
- **Distance**: meters from user (polar coordinate)
- **Bearing**: degrees from north 0-360° (polar coordinate)
- **Status**: `safe`, `needHelp`, `sos`, `relay`
- **Signal Strength**: 0.0-1.0 (affects dot size)
- **Color Coding**:
  - Green (#00FF88): Safe devices
  - Amber (#FFB800): Need help
  - Red (#FF3366): SOS active (pulsing)
  - Cyan (#00D9FF): Mesh relay nodes

### 2. `EmergencyRadarWidget` (`widgets/emergency_radar.dart`)
Main radar visualization widget with:
- **Concentric rings**: 25m, 50m, 100m, 200m distance markers
- **Sweep animation**: 3-second rotating scan line
- **Heatmap overlay**: Gaussian blur density visualization
- **Device dots**: Colored with glow effects
- **Direction cone**: User's field of view (75°)
- **North indicator**: Compass reference point

#### Features:
- **Tap device**: Shows device details in bottom sheet
- **Pinch zoom**: Cycles through 50m, 100m, 200m, 500m ranges
- **Pan**: Enabled when zoomed (not implemented in v1)
- **Double tap**: Centers on user location

### 3. `RadarDemoScreen` (`screens/radar_demo_screen.dart`)
Demo screen with sample data and interactions:
- 12 sample devices with various statuses
- Simulated compass bearing rotation
- Device detail bottom sheet
- Help dialog explaining controls

## Usage

### Basic Integration
```dart
import 'package:beacon/features/emergency/widgets/emergency_radar.dart';
import 'package:beacon/features/emergency/models/radar_device.dart';

// Create device list from your mesh network data
final devices = meshProvider.discoveredDevices.map((device) {
  return RadarDevice(
    id: device.id,
    distance: calculateDistance(device), // Your distance calculation
    bearing: calculateBearing(device),   // Your bearing calculation
    status: getDeviceStatus(device),      // Map to DeviceStatus enum
    signalStrength: device.rssi / 100.0, // Normalize signal
    lastSeen: device.lastSeen,
    name: device.name,
  );
}).toList();

// Display radar
EmergencyRadarWidget(
  devices: devices,
  userBearing: compassBearing, // From sensors_plus or geolocator
  onDeviceTap: (device) {
    // Handle device selection
    showDeviceDetails(device);
  },
  onCenterTap: () {
    // Handle center tap (user location)
    centerMapOnUser();
  },
)
```

### Navigation
From anywhere in the app:
```dart
Navigator.pushNamed(context, '/radar-demo');
```

Or from the main screen, tap the radar icon in the status bar.

## Design System

### Colors (from `core/constants/colors.dart`)
```dart
AppColors.radarBackground   // #0A0E27 - Dark blue-gray
AppColors.radarSweep        // #00D9FF - Cyan sweep line
AppColors.deviceSafe        // #00FF88 - Safe status
AppColors.deviceNeedHelp    // #FFB800 - Need help
AppColors.deviceSos         // #FF3366 - SOS active
AppColors.deviceRelay       // #00D9FF - Mesh relay
```

### Animations
- **Sweep**: 3s continuous rotation (`RepaintBoundary`)
- **Pulse**: 1s for SOS devices (scale + opacity)
- **Ripple**: 800ms on new device (future feature)
- **Direction cone**: Smooth rotation following compass

### Performance Optimizations
- Heatmap calculated on 50x50 grid (adjustable)
- Gaussian kernel with 3-cell radius
- `shouldRepaint()` checks for minimal redraws
- Separate painters for static/dynamic layers (future)

## Integration with Mesh Network

Connect to your mesh provider:
```dart
// In your provider or service
List<RadarDevice> getRadarDevices() {
  return discoveredDevices.map((bleDevice) {
    return RadarDevice(
      id: bleDevice.id,
      distance: _calculateDistance(
        bleDevice.latitude,
        bleDevice.longitude,
      ),
      bearing: _calculateBearing(
        bleDevice.latitude,
        bleDevice.longitude,
      ),
      status: _mapStatus(bleDevice.emergencyStatus),
      signalStrength: (bleDevice.rssi + 100) / 100, // -100 to 0 → 0 to 1
      lastSeen: bleDevice.lastSeen,
      name: bleDevice.name ?? bleDevice.id.substring(0, 8),
    );
  }).toList();
}

double _calculateDistance(double lat, double lon) {
  // Use geolocator or similar for haversine formula
  return Geolocator.distanceBetween(
    userLocation.latitude,
    userLocation.longitude,
    lat,
    lon,
  );
}

double _calculateBearing(double lat, double lon) {
  // Calculate bearing from user to device
  return Geolocator.bearingBetween(
    userLocation.latitude,
    userLocation.longitude,
    lat,
    lon,
  );
}

DeviceStatus _mapStatus(String? status) {
  switch (status) {
    case 'SOS': return DeviceStatus.sos;
    case 'HELP': return DeviceStatus.needHelp;
    case 'RELAY': return DeviceStatus.relay;
    default: return DeviceStatus.safe;
  }
}
```

## Sensor Integration

### Compass (User Bearing)
```dart
import 'package:sensors_plus/sensors_plus.dart';

double _userBearing = 0.0;

void _startCompass() {
  magnetometerEvents.listen((MagnetometerEvent event) {
    final bearing = atan2(event.y, event.x) * (180 / pi);
    setState(() {
      _userBearing = (bearing + 360) % 360;
    });
  });
}
```

### GPS Location
```dart
import 'package:geolocator/geolocator.dart';

Position? _userLocation;

Future<void> _updateUserLocation() async {
  final position = await Geolocator.getCurrentPosition();
  setState(() {
    _userLocation = position;
  });
}
```

## Future Enhancements

### Planned Features
- [ ] Ripple animation on new device appearance
- [ ] Trail effect behind device movements
- [ ] Range rings that pulse when device enters
- [ ] Directional audio cues for SOS devices
- [ ] AR overlay mode using camera
- [ ] Historical heatmap (device density over time)
- [ ] Safe zone pathfinding visualization
- [ ] Multi-finger zoom and rotation
- [ ] Offline terrain awareness
- [ ] Battery-optimized rendering modes

### Performance Improvements
- [ ] Separate painters for each layer (8 painters)
- [ ] Cache static layers (rings, grid)
- [ ] Throttle heatmap updates (500ms interval)
- [ ] WebGL rendering for web platform
- [ ] Level-of-detail based on zoom

### Accessibility
- [ ] Screen reader descriptions for devices
- [ ] High contrast mode
- [ ] Haptic feedback on device proximity
- [ ] Voice announcements for SOS alerts
- [ ] Reduced motion mode

## Testing

### Manual Testing Checklist
- [ ] Tap device dot shows details
- [ ] Pinch zoom cycles through ranges
- [ ] SOS devices pulse visibly
- [ ] Sweep animation runs smoothly (60fps)
- [ ] Heatmap shows in high-density areas
- [ ] Direction cone follows bearing changes
- [ ] Info cards update with device changes
- [ ] North indicator stays at top

### Performance Targets
- **Frame rate**: 60fps during animations
- **Device count**: Smooth with 50+ devices
- **Zoom transition**: <200ms
- **Tap response**: <100ms
- **Memory usage**: <50MB for radar widget

## Credits

Inspired by:
- Submarine sonar displays
- Apple Find My network
- Emergency services dispatch UI
- Tactical communication systems

Built for NASA Space Apps Challenge 2025 - Beacon project.
