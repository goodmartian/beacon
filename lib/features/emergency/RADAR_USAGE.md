# Использование радара с настраиваемыми радиусами

## ✅ Готово:

1. **Внешний круг удален** - теперь только концентрические кольца
2. **Настраиваемые радиусы** - каждый круг соответствует определенному расстоянию в метрах
3. **Подписи на кругах** - показывают расстояние (например "25m", "50m", "100m")

## Как использовать:

### 1. Настройка радиусов кругов

В `emergency_mode.dart`:

```dart
CustomPaint(
  painter: CompactRadarPainter(
    deviceCount: deviceCount,
    userBearing: _userBearing,
    radiusRings: const [25, 50, 100], // 🔧 ЗДЕСЬ настраиваешь радиусы!
  ),
)
```

**Примеры конфигураций:**

```dart
// Близкая дистанция (для помещений)
radiusRings: const [10, 25, 50]

// Средняя дистанция (улица)
radiusRings: const [25, 50, 100]

// Дальняя дистанция (открытая местность)
radiusRings: const [50, 100, 200, 500]

// Можно любое количество кругов!
radiusRings: const [10, 20, 30, 40, 50]
```

### 2. Расчет расстояния до устройства

Используй `DistanceCalculator` для расчета расстояния по GPS:

```dart
import 'package:beacon/core/utils/distance_calculator.dart';

// Твоя текущая позиция
final myLat = 55.7558;
final myLon = 37.6173;

// Позиция другого устройства (из BLE сообщения)
final deviceLat = 55.7560;
final deviceLon = 37.6175;

// Рассчитать расстояние в метрах
final distance = DistanceCalculator.calculateDistance(
  lat1: myLat,
  lon1: myLon,
  lat2: deviceLat,
  lon2: deviceLon,
);

print('Расстояние: ${distance.toInt()}m');
// Выведет: Расстояние: 25m
```

### 3. Определить в каком круге находится устройство

```dart
final radiusRings = [25.0, 50.0, 100.0];

// Устройство на расстоянии 30 метров
final distance = 30.0;

final ringIndex = DistanceCalculator.getRadiusRingIndex(
  distance,
  radiusRings,
);

if (ringIndex == 0) {
  print('Устройство во внутреннем круге (0-25m)');
} else if (ringIndex == 1) {
  print('Устройство в среднем круге (25-50m)');
} else if (ringIndex == 2) {
  print('Устройство во внешнем круге (50-100m)');
} else {
  print('Устройство за пределами радара (>100m)');
}
```

### 4. Расчет азимута (направления)

```dart
// Рассчитать в какую сторону находится устройство
final bearing = DistanceCalculator.calculateBearing(
  lat1: myLat,
  lon1: myLon,
  lat2: deviceLat,
  lon2: deviceLon,
);

print('Направление: ${bearing.toInt()}°');
// 0° = север, 90° = восток, 180° = юг, 270° = запад
```

### 5. Форматирование расстояния для UI

```dart
// Красиво отформатировать расстояние
final distance = 1250.0; // метров

final formatted = DistanceCalculator.formatDistance(distance);
print(formatted); // "1.3km"

// Если меньше 1000м:
final close = 350.0;
print(DistanceCalculator.formatDistance(close)); // "350m"
```

## Интеграция с Mesh Network

### Шаг 1: Добавь GPS координаты в сообщения

В `mesh_message.dart` добавь поля:

```dart
class MeshMessage {
  final double? latitude;
  final double? longitude;

  // ... остальные поля
}
```

### Шаг 2: Расчет позиций устройств

В `MeshProvider`:

```dart
import 'package:beacon/core/utils/distance_calculator.dart';
import 'package:geolocator/geolocator.dart';

class MeshProvider extends ChangeNotifier {
  Position? _myPosition;

  // Получить свою позицию
  Future<void> _updateMyPosition() async {
    _myPosition = await Geolocator.getCurrentPosition();
  }

  // Рассчитать расстояние до устройства
  double getDeviceDistance(MeshDevice device) {
    if (_myPosition == null || device.latitude == null) {
      return 0.0;
    }

    return DistanceCalculator.calculateDistance(
      lat1: _myPosition!.latitude,
      lon1: _myPosition!.longitude,
      lat2: device.latitude!,
      lon2: device.longitude!,
    );
  }

  // Рассчитать направление к устройству
  double getDeviceBearing(MeshDevice device) {
    if (_myPosition == null || device.latitude == null) {
      return 0.0;
    }

    return DistanceCalculator.calculateBearing(
      lat1: _myPosition!.latitude,
      lon1: _myPosition!.longitude,
      lat2: device.latitude!,
      lon2: device.longitude!,
    );
  }
}
```

### Шаг 3: Отобразить на радаре

Обнови `CompactRadarPainter` чтобы показывать реальные устройства:

```dart
// В CompactRadarPainter добавь:
final List<DevicePosition> devices;

class DevicePosition {
  final double distance; // в метрах
  final double bearing;  // в градусах (0-360)
  final DeviceStatus status; // safe, help, sos, relay
}

// Затем в paint():
for (final device in devices) {
  // Рассчитать позицию на радаре
  final deviceAngle = (device.bearing * math.pi) / 180 - math.pi / 2;
  final deviceRadius = (device.distance / maxRadiusMeters) * radius;

  final x = center.dx + deviceRadius * math.cos(deviceAngle);
  final y = center.dy + deviceRadius * math.sin(deviceAngle);

  // Нарисовать точку устройства
  final dotColor = _getColorByStatus(device.status);
  _drawDevice(canvas, Offset(x, y), dotColor);
}
```

## Пример полной интеграции

```dart
// В emergency_mode.dart:
Widget _buildPulsingCircle(BuildContext context) {
  return Consumer<MeshProvider>(
    builder: (context, meshProvider, child) {
      // Получить реальные позиции устройств
      final devicePositions = meshProvider.discoveredDevices.map((device) {
        return DevicePosition(
          distance: meshProvider.getDeviceDistance(device),
          bearing: meshProvider.getDeviceBearing(device),
          status: device.emergencyStatus,
        );
      }).toList();

      return SizedBox(
        width: 250,
        height: 250,
        child: CustomPaint(
          painter: CompactRadarPainter(
            devices: devicePositions,
            userBearing: _userBearing,
            radiusRings: const [25, 50, 100], // Настрой под свои нужды
          ),
        ),
      );
    },
  );
}
```

## Формула Haversine

Формула для расчета расстояния между двумя GPS точками:

```
a = sin²(Δφ/2) + cos φ1 ⋅ cos φ2 ⋅ sin²(Δλ/2)
c = 2 ⋅ atan2( √a, √(1−a) )
d = R ⋅ c

где:
φ - широта (latitude)
λ - долгота (longitude)
R - радиус Земли (6371 км)
d - расстояние между точками
```

## FAQ

**Q: Как изменить количество кругов?**
A: Просто измени массив `radiusRings: const [25, 50, 100]`. Можно добавить сколько угодно!

**Q: Могу ли я использовать разные радиусы для разных ситуаций?**
A: Да! Можно динамически менять в зависимости от плотности устройств:
```dart
final rings = deviceCount > 10
    ? [50, 100, 200]  // Много устройств - большие круги
    : [10, 25, 50];   // Мало устройств - маленькие круги
```

**Q: Как точность GPS влияет на радар?**
A: GPS точность ~5-10 метров на открытом воздухе. В помещениях хуже (50+ метров).
Для помещений лучше использовать RSSI (сила сигнала BLE) для оценки расстояния.

**Q: Можно ли комбинировать GPS и RSSI?**
A: Да! На открытом воздухе - GPS, в помещениях - RSSI:
```dart
final distance = hasGoodGpsSignal
    ? DistanceCalculator.calculateDistance(...)
    : estimateDistanceFromRSSI(device.rssi);
```
