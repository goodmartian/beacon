import 'dart:math' as math;

/// Утилиты для расчета расстояния между GPS координатами
class DistanceCalculator {
  /// Радиус Земли в метрах
  static const double earthRadiusMeters = 6371000;

  /// Рассчитать расстояние между двумя точками по формуле Haversine
  /// Возвращает расстояние в метрах
  static double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    // Конвертируем градусы в радианы
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final lat1Rad = _toRadians(lat1);
    final lat2Rad = _toRadians(lat2);

    // Формула Haversine
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) *
            math.sin(dLon / 2) *
            math.cos(lat1Rad) *
            math.cos(lat2Rad);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    // Расстояние в метрах
    return earthRadiusMeters * c;
  }

  /// Рассчитать азимут (bearing) от точки 1 к точке 2
  /// Возвращает угол в градусах (0-360), где 0 = север
  static double calculateBearing({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final lat1Rad = _toRadians(lat1);
    final lat2Rad = _toRadians(lat2);
    final dLon = _toRadians(lon2 - lon1);

    final y = math.sin(dLon) * math.cos(lat2Rad);
    final x = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLon);

    final bearingRad = math.atan2(y, x);
    final bearingDeg = _toDegrees(bearingRad);

    // Нормализуем к диапазону 0-360
    return (bearingDeg + 360) % 360;
  }

  /// Конвертировать градусы в радианы
  static double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  /// Конвертировать радианы в градусы
  static double _toDegrees(double radians) {
    return radians * 180 / math.pi;
  }

  /// Определить в каком радиусе находится устройство
  /// Возвращает индекс круга (0 = внутренний, 1 = средний, 2 = внешний)
  /// или -1 если за пределами всех кругов
  static int getRadiusRingIndex(
    double distance,
    List<double> radiusRings,
  ) {
    for (int i = 0; i < radiusRings.length; i++) {
      if (distance <= radiusRings[i]) {
        return i;
      }
    }
    return -1; // За пределами последнего круга
  }

  /// Форматировать расстояние для отображения
  /// Возвращает строку типа "25m" или "1.2km"
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toInt()}m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }
}
