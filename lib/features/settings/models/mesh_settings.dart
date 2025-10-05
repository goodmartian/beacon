/// Mesh network configuration
class MeshSettings {
  final double powerLevel; // 0.0 to 1.0
  final double range; // in meters (25-100m)
  final bool relayMode; // Act as relay node

  MeshSettings({
    required this.powerLevel,
    required this.range,
    required this.relayMode,
  });

  factory MeshSettings.defaults() {
    return MeshSettings(
      powerLevel: 0.8, // 80% power
      range: 50.0, // 50m default range
      relayMode: true, // Enable relay by default for better network
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'powerLevel': powerLevel,
      'range': range,
      'relayMode': relayMode,
    };
  }

  factory MeshSettings.fromJson(Map<String, dynamic> json) {
    return MeshSettings(
      powerLevel: (json['powerLevel'] as num?)?.toDouble() ?? 0.8,
      range: (json['range'] as num?)?.toDouble() ?? 50.0,
      relayMode: json['relayMode'] as bool? ?? true,
    );
  }

  MeshSettings copyWith({
    double? powerLevel,
    double? range,
    bool? relayMode,
  }) {
    return MeshSettings(
      powerLevel: powerLevel ?? this.powerLevel,
      range: range ?? this.range,
      relayMode: relayMode ?? this.relayMode,
    );
  }
}
