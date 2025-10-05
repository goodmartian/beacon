/// Medical information for emergency situations
class MedicalInfo {
  final String? bloodType;
  final List<String> allergies;
  final List<String> medications;
  final List<String> conditions;

  MedicalInfo({
    this.bloodType,
    this.allergies = const [],
    this.medications = const [],
    this.conditions = const [],
  });

  factory MedicalInfo.empty() {
    return MedicalInfo(
      bloodType: null,
      allergies: [],
      medications: [],
      conditions: [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bloodType': bloodType,
      'allergies': allergies,
      'medications': medications,
      'conditions': conditions,
    };
  }

  factory MedicalInfo.fromJson(Map<String, dynamic> json) {
    return MedicalInfo(
      bloodType: json['bloodType'] as String?,
      allergies: (json['allergies'] as List<dynamic>?)?.cast<String>() ?? [],
      medications: (json['medications'] as List<dynamic>?)?.cast<String>() ?? [],
      conditions: (json['conditions'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  MedicalInfo copyWith({
    String? bloodType,
    List<String>? allergies,
    List<String>? medications,
    List<String>? conditions,
  }) {
    return MedicalInfo(
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      conditions: conditions ?? this.conditions,
    );
  }
}
