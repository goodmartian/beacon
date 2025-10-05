# 📱 Beacon

**Find. Survive. Together.**

Emergency disaster communication app that creates self-organizing Bluetooth mesh networks when traditional infrastructure fails. Built for NASA Space Apps Challenge 2025.

![Platform](https://img.shields.io/badge/platform-Android-green)
![Framework](https://img.shields.io/badge/framework-Flutter-blue)
![License](https://img.shields.io/badge/license-TBD-orange)

---

## 🚨 The Problem

Every year, 500,000+ people are trapped in disaster zones without communication:
- Cell towers fail or become overloaded
- Internet infrastructure is destroyed
- People cannot call for help or find safety
- Rescuers cannot locate survivors efficiently
- **Every minute of delay costs lives**

---

## 💡 The Solution

Beacon creates a **hybrid communication system** combining:
1. **Bluetooth Mesh Network** - Phone-to-phone communication (no infrastructure needed)
2. **NASA Satellite Data** - Real-time fire, flood, and earthquake information
3. **Intelligent Routing** - AI prioritization for rescue operations

**Unique Innovation:** First platform combining crowd-powered mesh networks with space-based hazard intelligence.

---

## ✨ Key Features

### Core Functionality
- ✅ **Bluetooth Mesh Networking** - Messages relay through intermediate devices (30-100m per hop)
- ✅ **SOS Broadcasting** - One-tap emergency activation with automatic location sharing
- ✅ **NASA Data Integration** - Real-time disaster data from FIRMS, floods, earthquakes
- ✅ **Dual UI Modes** - Normal (green/maps) vs Emergency (black/battery-save)
- ✅ **Offline-First** - All critical features work without internet
- ✅ **Auto-Activation** - Earthquake detection via accelerometer

### Message Types
| Type | Priority | Size | Function |
|------|----------|------|----------|
| SOS Signal | CRITICAL | 128 bytes | Emergency broadcast + GPS |
| Medical Status | HIGH | 64 bytes | Injured/Safe/Critical |
| Text Message | HIGH | 512 bytes | Communication |
| GPS Location | HIGH | 64 bytes | Position updates |
| Battery Level | MEDIUM | 16 bytes | Power status |

---

## 🏗️ Technology Stack

**Frontend:**
- Flutter 3.9.2
- Provider (state management)
- Hive (offline storage)

**Bluetooth:**
- flutter_blue_plus 1.31.0
- BLE mesh networking

**Maps & Location:**
- google_maps_flutter 2.5.0
- geolocator 10.1.0

**NASA Data:**
- dio 5.3.4 (HTTP client)
- FIRMS API integration

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.9.2+
- Android Studio / VS Code
- Physical Android device (BLE testing requires hardware)
- NASA FIRMS API key ([get here](https://firms.modaps.eosdis.nasa.gov/api/))

### Installation

1. **Clone repository:**
```bash
git clone git@github.com:goodmartian/beacon.git
cd beacon
```

2. **Install dependencies:**
```bash
flutter pub get
```

3. **Configure NASA API:**
```dart
// lib/core/constants/api_keys.dart
const String nasaFirmsApiKey = 'YOUR_API_KEY_HERE';
```

4. **Run on device:**
```bash
flutter run
```

### Building APK
```bash
# Debug build
flutter build apk

# Release build
flutter build apk --release
```

---

## 📖 Documentation

**In-App:**
- **[CLAUDE.md](CLAUDE.md)** - AI development guidance
- **[NASA FIRMS Integration](lib/features/hazards/README.md)** - Complete integration guide

**Related Projects:**
- **[ESP32 Testing Firmware](https://github.com/goodmartian/beacon-esp32-testing)** - Hardware mesh node emulator
- **[Landing Page](https://goodmartian.github.io/beacon-site/)** - Project website

---

## 🧪 Testing

### Multi-Device Testing (Required)
Bluetooth mesh requires **minimum 2 physical Android devices:**

```bash
# Install on both devices
flutter install

# Device A: Activate SOS
# Device B: Should receive alert within 3 seconds
```

**Test Scenarios:**
1. Direct communication (2 devices)
2. Multi-hop relay (3+ devices)
3. NASA data display
4. Auto-activation (shake device)
5. Battery drain (30 min test)

### Unit Tests
```bash
flutter test
```

---

## 📱 How It Works

### 1. Mesh Network Formation
```
Device A ←→ Device B ←→ Device C
    ↕           ↕           ↕
Device D ←→ Device E ←→ Device F
```
- Automatic BLE discovery
- Self-organizing topology
- 30-100 meter range per hop
- Supports unlimited devices

### 2. Message Relay
```
[Alice activates SOS]
    ↓
[Message hops through Bob]
    ↓
[Reaches rescue team at Charlie]
```
- Priority-based transmission
- Deduplication (no loops)
- TTL-based hop limits
- <3 second latency per hop

### 3. NASA Data Sync
```
[Device with internet] → Fetches NASA data
    ↓
[Broadcasts to mesh]
    ↓
[All devices cache for 24 hours]
```
- Real-time fire locations (FIRMS)
- Flood zones
- Earthquake epicenters
- Offline caching

---

## 🎨 UI Modes

### Normal Mode
- **Color:** Safety Green (#2ECC71)
- **Display:** Map with NASA hazard overlays
- **Status:** Device count, battery, network
- **Action:** Large SOS activation button

### Emergency Mode
- **Color:** Black background (OLED battery save)
- **Display:** Pulsing red SOS circle
- **Status:** "X people hear you" + direction to safety
- **Actions:** Safe / Medical / Message buttons

---

## 🔋 Battery Optimization

**Target:** 48+ hours in emergency mode

**Strategies:**
- Black OLED background (-30% display power)
- Reduced BLE scan frequency
- Low-power location updates
- Message batching
- Sleep mode when idle

---

## 🌍 NASA Data Sources

**FIRMS (Fire Information for Resource Management System):**
- MODIS and VIIRS satellites
- Near real-time fire detection
- 375m spatial resolution
- 3-6 hour update frequency

**Integration:**
- API endpoint with geographic bounds
- 24-hour offline caching
- Mesh network propagation
- Priority scoring for rescue

---

## 🎯 Project Status

**Phase:** Active Development (Day 1)
**Target:** NASA Space Apps Challenge Submission (October 5, 2025)
**Platform:** Android MVP

### Completed ✅
- [x] Project setup and structure
- [x] Bluetooth mesh implementation
- [x] NASA FIRMS API integration
- [x] Emergency UI modes (Normal/Emergency)
- [x] 24-hour offline caching with Hive
- [x] Auto-updates every 30 minutes
- [x] Danger zone detection (10km radius)
- [x] Fire prioritization system
- [x] Geolocation integration
- [x] ESP32 firmware for testing

### In Progress 🔄
- [ ] Google Maps integration with fire overlays
- [ ] Message relay optimization
- [ ] Battery usage optimization
- [ ] Demo video production

---

## 🏆 Why Beacon Wins

| Feature | Beacon | Bridgefy | goTenna | NASA Tools |
|---------|---------|----------|---------|------------|
| Works on existing phones | ✅ | ✅ | ❌ ($500 hardware) | ✅ |
| Mesh networking | ✅ | ✅ | ✅ | ❌ |
| NASA satellite data | ✅ | ❌ | ❌ | ✅ |
| Auto-activation | ✅ | ❌ | ❌ | ❌ |
| Free forever | ✅ | ✅ | ❌ | ✅ |

---

## 🤝 Contributing

This is a solo hackathon project for NASA Space Apps Challenge 2025.

**Post-hackathon contributions welcome:**
- iOS version
- Additional disaster types
- Encryption improvements
- Mesh optimization
- Accessibility enhancements

---

## 📄 License

To be determined after hackathon completion.

---

## 🔗 Resources

**Project:**
- GitHub App: https://github.com/goodmartian/beacon
- ESP32 Firmware: https://github.com/goodmartian/beacon-esp32-testing
- Landing Page: https://goodmartian.github.io/beacon-site/

**NASA:**
- FIRMS API: https://firms.modaps.eosdis.nasa.gov/
- Disasters Portal: https://disasters.nasa.gov/

**Flutter:**
- flutter_blue_plus: https://pub.dev/packages/flutter_blue_plus
- Provider: https://pub.dev/packages/provider
- Geolocator: https://pub.dev/packages/geolocator

---

## 📞 Contact

**Challenge:** Data Pathways to Healthy Cities and Human Settlements
**Event:** NASA Space Apps Challenge 2025
**Date:** October 4-5, 2025

---

## 💪 Project Motivation

> "Every line of code matters. Every pixel counts. Every second saved is a life saved."

When disaster strikes, we're all we have. Beacon ensures **you're never alone**.

---

**Built with ❤️ for NASA Space Apps Challenge 2025**
