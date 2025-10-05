# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Beacon** is an emergency disaster communication app for NASA Space Apps Challenge 2025. It creates self-organizing Bluetooth mesh networks between smartphones when traditional infrastructure fails, combining local peer-to-peer communication with NASA satellite disaster data to coordinate rescue operations.

**Core Architecture:**
- **Frontend:** Flutter mobile app (Android-first, offline-first)
- **Communication:** Bluetooth Low Energy mesh network (no internet required)
- **Data:** NASA satellite APIs (FIRMS fires, floods, earthquakes) with 24h offline caching
- **State:** Provider for state management, Hive for local persistence

**Key Innovation:** First platform combining crowd-powered mesh networks with space-based hazard intelligence for disaster response.

## Development Commands

### Setup & Dependencies
```bash
# Install dependencies
flutter pub get

# Check for outdated packages
flutter pub outdated

# Upgrade packages
flutter pub upgrade
```

### Running the App
```bash
# Run in debug mode (hot reload enabled)
flutter run

# Run on specific device
flutter devices                    # List available devices
flutter run -d <device-id>         # Run on specific device

# Run in release mode
flutter run --release
```

### Testing
```bash
# Run all tests
flutter test

# Run single test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

### Code Quality
```bash
# Analyze code for issues
flutter analyze

# Format code
dart format .

# Fix auto-fixable issues
dart fix --apply
```

### Building
```bash
# Build APK for Android
flutter build apk

# Build release APK
flutter build apk --release

# Build app bundle (for Play Store)
flutter build appbundle
```

## Architecture & Code Structure

### Planned Directory Structure
```
lib/
├── main.dart                    # App entry point
├── core/
│   ├── theme/                   # Theme definitions (emergency/normal modes)
│   ├── constants/               # Color palette, sizes, durations
│   └── utils/                   # Helper functions
├── features/
│   ├── mesh/                    # Bluetooth mesh networking
│   │   ├── models/              # Message types, device models
│   │   ├── services/            # BLE discovery, message relay
│   │   └── providers/           # Mesh network state
│   ├── emergency/               # Emergency mode UI & logic
│   │   ├── screens/             # Normal/Emergency mode screens
│   │   ├── widgets/             # SOS button, status indicators
│   │   └── providers/           # Emergency state management
│   ├── hazards/                 # NASA data integration
│   │   ├── models/              # Fire, flood, earthquake models
│   │   ├── services/            # NASA API clients
│   │   └── providers/           # Hazard data state
│   └── maps/                    # Map integration
│       ├── widgets/             # Map display, overlays
│       └── services/            # Location services
└── shared/
    ├── widgets/                 # Reusable UI components
    └── models/                  # Shared data models
```

### Key Technical Patterns

**Offline-First Approach:**
- All critical features (mesh communication, SOS broadcasting, basic navigation) work without internet
- NASA data cached for 24 hours with compressed storage
- Message queue with automatic retry and conflict resolution
- Progressive enhancement: better features with internet, graceful degradation without

**Battery Optimization:**
- Emergency mode uses black background for OLED power saving
- Target: 48+ hours battery life in emergency mode
- Bluetooth LE for efficient mesh networking
- Minimal background processing

**Message Types (Priority-Based):**
1. SOS Signal (CRITICAL, 128 bytes): ID + GPS + timestamp
2. Text Message (HIGH, 512 bytes): Short text communication
3. Medical Status (HIGH, 64 bytes): Injured/Safe/Critical
4. Battery Level (MEDIUM, 16 bytes): Percentage
5. GPS Location (HIGH, 64 bytes): Lat/Lon coordinates

**Dual UI Modes:**
- **Normal Mode:** Green theme, map with safety zones, NASA hazard overlays, large SOS button
- **Emergency Mode:** Black background, pulsing red SOS, network status, minimal battery usage

### State Management Philosophy
- Use Provider for app-wide state (mesh network, emergency mode, hazard data)
- Keep state close to where it's used when possible
- Minimize rebuilds through careful provider scope
- Use `ChangeNotifier` for mutable state, `ValueNotifier` for simple values

### Performance Requirements
- Message latency: <3 seconds per hop
- Device discovery: <10 seconds
- Message success rate: >90% within 3 hops
- APK size: <20MB
- Battery life: 48+ hours in emergency mode

## Development Priorities (NASA Space Apps Challenge Timeline)

**Day 1 Focus (October 4):**
1. Bluetooth mesh core + device discovery + message passing
2. Emergency UI screens + Map integration + NASA FIRMS API
3. Mesh network relay + Auto-activation sensors + Data persistence

**Day 2 Focus (October 5):**
1. UI polish & animations + Web dashboard + Battery optimization
2. Demo video + Presentation + Documentation
3. APK build + Deploy + Final testing

## Dependencies from PRD

**Planned Core Dependencies** (not yet in pubspec.yaml):
```yaml
# Bluetooth & Mesh
flutter_blue_plus: ^1.31.0
nearby_connections: ^3.3.0

# Maps & Location
mapbox_gl: ^0.16.0
geolocator: ^10.1.0

# NASA APIs
dio: ^5.3.4
json_serializable: ^6.7.1

# State Management
provider: ^6.1.1

# Storage
hive_flutter: ^1.1.0
shared_preferences: ^2.2.2

# Sensors (for auto-activation)
sensors_plus: ^4.0.2

# Animations
flutter_animate: ^4.3.0
lottie: ^2.7.0
```

## Design System

**Color Palette:**
- Normal Mode: Primary `#2ECC71` (Safety Green), Background `#FFFFFF`, Text `#2C3E50`
- Emergency Mode: Alert `#E74C3C` (SOS Red), Warning `#F39C12`, Background `#000000`, Text `#FFFFFF`

**Typography:**
- Font: Inter or System Default
- Headers: 24sp Bold, Body: 16sp Regular, Emergency: 32sp Black

**Touch Targets:**
- Critical buttons: 64dp minimum (designed for shaking hands, one-thumb operation)
- Normal buttons: 48dp minimum

**Animations:**
- SOS pulse: 1.5s cycle, ease-in-out
- All animations <300ms for responsiveness

## NASA Data Integration

**FIRMS API (Fire Information for Resource Management System):**
- Real-time fire locations from satellite data
- 24-hour offline caching with compression
- Auto-updates when any device has internet
- Display fires on map with proximity warnings

**Data Flow:**
1. Devices create local mesh via Bluetooth
2. Messages hop through network
3. Any device with internet uploads all cached data
4. NASA data propagates through mesh
5. Rescue dashboard aggregates all information

## Testing Strategy

**Priority Testing Focus:**
1. Bluetooth mesh: 2+ devices exchange messages successfully
2. NASA data: FIRMS fire data displays on map correctly
3. Message relay: SOS reaches device 2 hops away
4. Auto-activation: Earthquake detection via accelerometer works
5. Battery: 48-hour battery life achieved in emergency mode

**Manual Testing Required:**
- Multi-device Bluetooth communication (minimum 2 physical devices)
- Location services and GPS accuracy
- Battery drain measurement over extended periods
- Emergency mode activation flows

## Critical Success Metrics

**Technical Demo Requirements:**
- ✅ 2+ devices exchange messages via Bluetooth
- ✅ NASA fire data displays on map
- ✅ SOS reaches device 2 hops away
- ✅ Auto-activation works
- ✅ 48-hour battery life achieved

**MVP Acceptance Criteria:**
- 2 phones exchange SOS via Bluetooth
- NASA fires show on map
- Emergency mode activates in 1 tap
- Interface needs no instructions
- APK installs successfully

## Out of Scope for MVP

- iOS version (Android-first)
- Voice calls or photo/video sharing
- All disaster types (focus on fires, floods, earthquakes)
- Multiple languages (English only for MVP)
- Complex encryption (E2E planned for post-MVP)
- Wearables support
- Offline maps (use online maps with caching)

## Important Context

- **Timeline:** 48-hour hackathon (October 4-5, 2025)
- **Solo Developer:** Prioritize working demo over perfect implementation
- **NASA Requirement:** Must demonstrate NASA data usage
- **Target Platform:** Android (2+ billion devices)
- **Core Innovation:** Mesh networks + NASA satellite data in one app
- **Emotional Hook:** "Find. Survive. Together." - Every phone becomes a rescue node

## Resources

- NASA FIRMS API: https://firms.modaps.eosdis.nasa.gov/
- Flutter Bluetooth: https://pub.dev/packages/flutter_blue_plus
- Mapbox: https://www.mapbox.com/
- NASA Disasters Portal: https://disasters.nasa.gov/
