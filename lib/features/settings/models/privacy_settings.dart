/// Privacy and data sharing settings
class PrivacySettings {
  final bool shareLocation; // Share location with mesh network
  final bool shareMedicalInfo; // Share medical info in emergency
  final bool anonymousMode; // Hide identity, show only as anonymous device

  PrivacySettings({
    required this.shareLocation,
    required this.shareMedicalInfo,
    required this.anonymousMode,
  });

  factory PrivacySettings.defaults() {
    return PrivacySettings(
      shareLocation: true, // Essential for emergency coordination
      shareMedicalInfo: true, // Share medical info in SOS situations
      anonymousMode: false, // Show identity by default
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shareLocation': shareLocation,
      'shareMedicalInfo': shareMedicalInfo,
      'anonymousMode': anonymousMode,
    };
  }

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      shareLocation: json['shareLocation'] as bool? ?? true,
      shareMedicalInfo: json['shareMedicalInfo'] as bool? ?? true,
      anonymousMode: json['anonymousMode'] as bool? ?? false,
    );
  }

  PrivacySettings copyWith({
    bool? shareLocation,
    bool? shareMedicalInfo,
    bool? anonymousMode,
  }) {
    return PrivacySettings(
      shareLocation: shareLocation ?? this.shareLocation,
      shareMedicalInfo: shareMedicalInfo ?? this.shareMedicalInfo,
      anonymousMode: anonymousMode ?? this.anonymousMode,
    );
  }
}
