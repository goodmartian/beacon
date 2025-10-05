/// NASA data synchronization settings
class NasaSyncSettings {
  final bool autoSync;
  final int updateFrequencyMinutes; // Update frequency in minutes
  final Set<String> dataTypes; // fires, floods, earthquakes

  NasaSyncSettings({
    required this.autoSync,
    required this.updateFrequencyMinutes,
    required this.dataTypes,
  });

  factory NasaSyncSettings.defaults() {
    return NasaSyncSettings(
      autoSync: true,
      updateFrequencyMinutes: 30, // Update every 30 minutes
      dataTypes: {'fires', 'floods', 'earthquakes'}, // All types by default
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoSync': autoSync,
      'updateFrequencyMinutes': updateFrequencyMinutes,
      'dataTypes': dataTypes.toList(),
    };
  }

  factory NasaSyncSettings.fromJson(Map<String, dynamic> json) {
    return NasaSyncSettings(
      autoSync: json['autoSync'] as bool? ?? true,
      updateFrequencyMinutes: json['updateFrequencyMinutes'] as int? ?? 30,
      dataTypes: (json['dataTypes'] as List<dynamic>?)?.cast<String>().toSet() ??
          {'fires', 'floods', 'earthquakes'},
    );
  }

  NasaSyncSettings copyWith({
    bool? autoSync,
    int? updateFrequencyMinutes,
    Set<String>? dataTypes,
  }) {
    return NasaSyncSettings(
      autoSync: autoSync ?? this.autoSync,
      updateFrequencyMinutes: updateFrequencyMinutes ?? this.updateFrequencyMinutes,
      dataTypes: dataTypes ?? this.dataTypes,
    );
  }
}
