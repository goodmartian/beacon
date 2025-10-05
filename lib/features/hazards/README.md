# NASA FIRMS Integration

Интеграция данных NASA FIRMS (Fire Information for Resource Management System) для получения информации об активных пожарах в реальном времени на основе геолокации пользователя.

## Обзор

Модуль предоставляет:
- 🔥 Данные об активных пожарах из спутников NASA (VIIRS, MODIS)
- 📍 Автоматическое обнаружение пожаров рядом с пользователем
- 💾 24-часовое кэширование данных для оффлайн работы
- 🔄 Автоматическое обновление данных каждые 30 минут
- ⚠️ Определение зоны опасности (в радиусе 10км от пожаров)

## Архитектура

```
hazards/
├── models/
│   ├── fire_event.dart       # Модель события пожара
│   └── fire_event.g.dart     # Hive адаптер для кэширования
├── services/
│   ├── nasa_firms_service.dart  # Реальный API сервис
│   ├── mock_nasa_service.dart   # Мок-сервис для демо
│   └── fire_cache_service.dart  # Сервис кэширования
└── providers/
    └── nasa_provider.dart    # State management
```

## Быстрый старт

### 1. Получение API ключа NASA FIRMS

1. Перейдите на https://firms.modaps.eosdis.nasa.gov/api/
2. Зарегистрируйтесь и получите MAP_KEY
3. Лимит: 5000 запросов за 10 минут

### 2. Инициализация в main.dart

```dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'features/hazards/models/fire_event.g.dart';
import 'features/hazards/providers/nasa_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Hive
  await Hive.initFlutter();

  // Регистрация адаптера для FireEvent
  Hive.registerAdapter(FireEventAdapter());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => NasaProvider(
            apiKey: 'YOUR_NASA_FIRMS_API_KEY', // Замените на ваш ключ
            useMockData: false, // true для демо, false для реальных данных
          )..initialize(),
        ),
        // ... другие providers
      ],
      child: MyApp(),
    ),
  );
}
```

### 3. Использование в UI

```dart
import 'package:provider/provider.dart';
import 'features/hazards/providers/nasa_provider.dart';

class FiresMapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final nasaProvider = Provider.of<NasaProvider>(context);

    if (nasaProvider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (nasaProvider.errorMessage != null) {
      return Center(child: Text('Error: ${nasaProvider.errorMessage}'));
    }

    return ListView.builder(
      itemCount: nasaProvider.fires.length,
      itemBuilder: (context, index) {
        final fire = nasaProvider.firesByPriority[index];
        final distance = nasaProvider.hasLocation
            ? fire.distanceFromUser(
                nasaProvider.userLocation!.latitude,
                nasaProvider.userLocation!.longitude,
              )
            : null;

        return ListTile(
          leading: Icon(
            Icons.local_fire_department,
            color: fire.confidence == 'high'
                ? Colors.red
                : Colors.orange,
          ),
          title: Text('Priority: ${fire.priority}/9'),
          subtitle: Text(
            'Confidence: ${fire.confidence} | '
            'FRP: ${fire.frp.toStringAsFixed(1)} MW'
            '${distance != null ? " | ${distance.toStringAsFixed(1)} km" : ""}',
          ),
          trailing: Text(
            '${fire.acquisitionTime.hour}:${fire.acquisitionTime.minute}',
          ),
        );
      },
    );
  }
}
```

### 4. Проверка зоны опасности

```dart
class DangerZoneAlert extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final nasaProvider = Provider.of<NasaProvider>(context);

    if (nasaProvider.isInDangerZone) {
      return Container(
        color: Colors.red,
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'DANGER: Active fire within 10km!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox.shrink();
  }
}
```

## API Reference

### NasaProvider

#### Getters

- `fires: List<FireEvent>` - Все пожары
- `firesByPriority: List<FireEvent>` - Отсортированные по приоритету
- `firesByDistance: List<FireEvent>` - Отсортированные по расстоянию
- `nearestFire: FireEvent?` - Ближайший пожар
- `isInDangerZone: bool` - Пользователь в зоне опасности
- `userLocation: Position?` - Текущая геолокация
- `isLoading: bool` - Идет загрузка
- `errorMessage: String?` - Сообщение об ошибке
- `lastUpdate: DateTime?` - Время последнего обновления

#### Методы

```dart
// Обновить геолокацию пользователя
await nasaProvider.updateUserLocation();

// Загрузить пожары (автоматически после updateUserLocation)
await nasaProvider.fetchFires(
  latitude: 37.7749,  // Опционально
  longitude: -122.4194,
  radiusKm: 100,      // По умолчанию 50км
  dayRange: 3,        // Данные за последние 3 дня
);

// Получить статистику
final stats = nasaProvider.getStatistics();
// {
//   'total': 5,
//   'high_confidence': 2,
//   'nominal_confidence': 2,
//   'low_confidence': 1,
//   'average_frp': 45.6,
//   'nearest_distance_km': 12.3,
// }

// Настройки
nasaProvider.updateSettings(
  useMockData: false,
  autoUpdate: true,
  updateIntervalMinutes: 15,
  searchRadiusKm: 75,
);
```

### FireEvent

```dart
class FireEvent {
  String id;                  // Уникальный ID
  double latitude;            // Широта
  double longitude;           // Долгота
  double brightness;          // Яркость (Kelvin)
  String confidence;          // 'low', 'nominal', 'high'
  DateTime acquisitionTime;   // Время обнаружения
  double frp;                 // Fire Radiative Power (MW)
  String satellite;           // 'N' (NOAA-20) или 'S' (Suomi-NPP)
  bool isDayTime;            // Дневное время

  int get priority;          // Приоритет 1-10
  double distanceFromUser(lat, lon); // Расстояние в км
}
```

## Настройки

### Интервал обновления

По умолчанию: 30 минут. Можно изменить:

```dart
nasaProvider.updateSettings(
  updateIntervalMinutes: 15, // Обновлять каждые 15 минут
);
```

### Радиус поиска

По умолчанию: 50 км. Можно изменить:

```dart
nasaProvider.updateSettings(
  searchRadiusKm: 100, // Искать в радиусе 100 км
);
```

### Источник данных

```dart
// Mock данные (для демо)
NasaProvider(useMockData: true);

// Реальные данные NASA
NasaProvider(
  apiKey: 'YOUR_API_KEY',
  useMockData: false,
);
```

## Кэширование

Данные автоматически кэшируются локально с помощью Hive:
- ✅ Срок хранения: 24 часа
- ✅ Загрузка при старте приложения
- ✅ Автоматическое обновление при наличии интернета

## Производительность

- 📡 API запрос: ~1-3 секунды
- 💾 Загрузка из кэша: <100ms
- 🔄 Автообновление: каждые 30 минут (настраивается)
- 📊 Лимит API: 5000 запросов / 10 минут

## Безопасность

⚠️ **Важно**: Не храните API ключ в коде!

Рекомендуется использовать:
- Environment variables
- Firebase Remote Config
- Secure storage

Пример:

```dart
// .env файл
NASA_FIRMS_API_KEY=your_key_here

// main.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

await dotenv.load();
final apiKey = dotenv.env['NASA_FIRMS_API_KEY'];
```

## Ошибки и отладка

### Распространенные ошибки

**"Location not available"**
```dart
// Решение: Проверьте разрешения на геолокацию
await Geolocator.requestPermission();
```

**"Failed to fetch fires: Network error"**
```dart
// Решение: Проверьте интернет соединение
// Данные будут загружены из кэша если доступны
```

**"Invalid API key"**
```dart
// Решение: Проверьте MAP_KEY на сайте NASA FIRMS
```

### Логирование

```dart
// Включить debug логи
import 'package:flutter/foundation.dart';

if (kDebugMode) {
  // Логи автоматически выводятся в консоль
}
```

## Интеграция с картами

Пример отображения пожаров на Google Maps:

```dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

Set<Marker> _buildFireMarkers(NasaProvider provider) {
  return provider.fires.map((fire) {
    return Marker(
      markerId: MarkerId(fire.id),
      position: LatLng(fire.latitude, fire.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        fire.confidence == 'high'
            ? BitmapDescriptor.hueRed
            : BitmapDescriptor.hueOrange,
      ),
      infoWindow: InfoWindow(
        title: 'Fire (${fire.confidence})',
        snippet: 'FRP: ${fire.frp.toStringAsFixed(1)} MW',
      ),
    );
  }).toSet();
}
```

## Roadmap

- [ ] Поддержка других типов катастроф (наводнения, землетрясения)
- [ ] Уведомления при приближении к зоне опасности
- [ ] Исторические данные и аналитика
- [ ] Offline maps с кэшированными пожарами
- [ ] Расширенная фильтрация (по уверенности, FRP, времени)

## Ресурсы

- [NASA FIRMS API Docs](https://firms.modaps.eosdis.nasa.gov/api/)
- [VIIRS Satellite Info](https://www.nasa.gov/mission_pages/NPP/main/)
- [Fire Radiative Power Explained](https://earthdata.nasa.gov/faq/firms-faq)

## Лицензия

Данные NASA FIRMS распространяются свободно для всех пользователей.
