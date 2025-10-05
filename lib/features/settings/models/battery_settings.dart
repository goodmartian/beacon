/// Battery optimization settings
class BatterySettings {
  final int emergencyModeThreshold; // Battery % to trigger emergency mode (0-100)
  final bool backgroundSync; // Allow background data sync
  final bool adaptivePower; // Automatically adjust power based on battery

  BatterySettings({
    required this.emergencyModeThreshold,
    required this.backgroundSync,
    required this.adaptivePower,
  });

  factory BatterySettings.defaults() {
    return BatterySettings(
      emergencyModeThreshold: 20, // Activate at 20% battery
      backgroundSync: true,
      adaptivePower: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emergencyModeThreshold': emergencyModeThreshold,
      'backgroundSync': backgroundSync,
      'adaptivePower': adaptivePower,
    };
  }

  factory BatterySettings.fromJson(Map<String, dynamic> json) {
    return BatterySettings(
      emergencyModeThreshold: json['emergencyModeThreshold'] as int? ?? 20,
      backgroundSync: json['backgroundSync'] as bool? ?? true,
      adaptivePower: json['adaptivePower'] as bool? ?? true,
    );
  }

  BatterySettings copyWith({
    int? emergencyModeThreshold,
    bool? backgroundSync,
    bool? adaptivePower,
  }) {
    return BatterySettings(
      emergencyModeThreshold: emergencyModeThreshold ?? this.emergencyModeThreshold,
      backgroundSync: backgroundSync ?? this.backgroundSync,
      adaptivePower: adaptivePower ?? this.adaptivePower,
    );
  }
}
