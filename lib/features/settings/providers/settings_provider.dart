import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/medical_info.dart';
import '../models/emergency_contact.dart';
import '../models/mesh_settings.dart';
import '../models/nasa_sync_settings.dart';
import '../models/battery_settings.dart';
import '../models/privacy_settings.dart';

/// Settings provider for managing all app settings
class SettingsProvider extends ChangeNotifier {
  // Settings state
  UserProfile _userProfile = UserProfile.defaultProfile();
  MedicalInfo _medicalInfo = MedicalInfo.empty();
  List<EmergencyContact> _emergencyContacts = [];
  MeshSettings _meshSettings = MeshSettings.defaults();
  NasaSyncSettings _nasaSyncSettings = NasaSyncSettings.defaults();
  BatterySettings _batterySettings = BatterySettings.defaults();
  PrivacySettings _privacySettings = PrivacySettings.defaults();

  bool _isLoaded = false;

  // Getters
  UserProfile get userProfile => _userProfile;
  MedicalInfo get medicalInfo => _medicalInfo;
  List<EmergencyContact> get emergencyContacts => List.unmodifiable(_emergencyContacts);
  MeshSettings get meshSettings => _meshSettings;
  NasaSyncSettings get nasaSyncSettings => _nasaSyncSettings;
  BatterySettings get batterySettings => _batterySettings;
  PrivacySettings get privacySettings => _privacySettings;
  bool get isLoaded => _isLoaded;

  // Storage keys
  static const String _keyUserProfile = 'user_profile';
  static const String _keyMedicalInfo = 'medical_info';
  static const String _keyEmergencyContacts = 'emergency_contacts';
  static const String _keyMeshSettings = 'mesh_settings';
  static const String _keyNasaSyncSettings = 'nasa_sync_settings';
  static const String _keyBatterySettings = 'battery_settings';
  static const String _keyPrivacySettings = 'privacy_settings';

  /// Initialize and load settings from storage
  Future<void> initialize() async {
    if (_isLoaded) return;

    await loadSettings();
    _isLoaded = true;
    debugPrint('Settings loaded successfully');
  }

  /// Load all settings from shared preferences
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load user profile
    final userProfileJson = prefs.getString(_keyUserProfile);
    if (userProfileJson != null) {
      _userProfile = UserProfile.fromJson(jsonDecode(userProfileJson));
    }

    // Load medical info
    final medicalInfoJson = prefs.getString(_keyMedicalInfo);
    if (medicalInfoJson != null) {
      _medicalInfo = MedicalInfo.fromJson(jsonDecode(medicalInfoJson));
    }

    // Load emergency contacts
    final contactsJson = prefs.getString(_keyEmergencyContacts);
    if (contactsJson != null) {
      final contactsList = jsonDecode(contactsJson) as List<dynamic>;
      _emergencyContacts = contactsList
          .map((json) => EmergencyContact.fromJson(json))
          .toList();
    }

    // Load mesh settings
    final meshJson = prefs.getString(_keyMeshSettings);
    if (meshJson != null) {
      _meshSettings = MeshSettings.fromJson(jsonDecode(meshJson));
    }

    // Load NASA sync settings
    final nasaJson = prefs.getString(_keyNasaSyncSettings);
    if (nasaJson != null) {
      _nasaSyncSettings = NasaSyncSettings.fromJson(jsonDecode(nasaJson));
    }

    // Load battery settings
    final batteryJson = prefs.getString(_keyBatterySettings);
    if (batteryJson != null) {
      _batterySettings = BatterySettings.fromJson(jsonDecode(batteryJson));
    }

    // Load privacy settings
    final privacyJson = prefs.getString(_keyPrivacySettings);
    if (privacyJson != null) {
      _privacySettings = PrivacySettings.fromJson(jsonDecode(privacyJson));
    }

    notifyListeners();
  }

  /// Update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    _userProfile = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserProfile, jsonEncode(profile.toJson()));
    debugPrint('User profile updated: ${profile.name}');
    notifyListeners();
  }

  /// Update medical info
  Future<void> updateMedicalInfo(MedicalInfo info) async {
    _medicalInfo = info;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMedicalInfo, jsonEncode(info.toJson()));
    debugPrint('Medical info updated');
    notifyListeners();
  }

  /// Add emergency contact
  Future<void> addEmergencyContact(EmergencyContact contact) async {
    _emergencyContacts.add(contact);
    await _saveEmergencyContacts();
    debugPrint('Emergency contact added: ${contact.name}');
    notifyListeners();
  }

  /// Update emergency contact
  Future<void> updateEmergencyContact(String id, EmergencyContact contact) async {
    final index = _emergencyContacts.indexWhere((c) => c.id == id);
    if (index != -1) {
      _emergencyContacts[index] = contact;
      await _saveEmergencyContacts();
      debugPrint('Emergency contact updated: ${contact.name}');
      notifyListeners();
    }
  }

  /// Remove emergency contact
  Future<void> removeEmergencyContact(String id) async {
    _emergencyContacts.removeWhere((c) => c.id == id);
    await _saveEmergencyContacts();
    debugPrint('Emergency contact removed: $id');
    notifyListeners();
  }

  /// Save emergency contacts to storage
  Future<void> _saveEmergencyContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = _emergencyContacts.map((c) => c.toJson()).toList();
    await prefs.setString(_keyEmergencyContacts, jsonEncode(contactsJson));
  }

  /// Update mesh settings
  Future<void> updateMeshSettings(MeshSettings settings) async {
    _meshSettings = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMeshSettings, jsonEncode(settings.toJson()));
    debugPrint('Mesh settings updated: power=${settings.powerLevel}, range=${settings.range}');
    notifyListeners();
  }

  /// Update NASA sync settings
  Future<void> updateNasaSyncSettings(NasaSyncSettings settings) async {
    _nasaSyncSettings = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNasaSyncSettings, jsonEncode(settings.toJson()));
    debugPrint('NASA sync settings updated: autoSync=${settings.autoSync}');
    notifyListeners();
  }

  /// Update battery settings
  Future<void> updateBatterySettings(BatterySettings settings) async {
    _batterySettings = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBatterySettings, jsonEncode(settings.toJson()));
    debugPrint('Battery settings updated: threshold=${settings.emergencyModeThreshold}%');
    notifyListeners();
  }

  /// Update privacy settings
  Future<void> updatePrivacySettings(PrivacySettings settings) async {
    _privacySettings = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPrivacySettings, jsonEncode(settings.toJson()));
    debugPrint('Privacy settings updated: anonymous=${settings.anonymousMode}');
    notifyListeners();
  }

  /// Clear all settings (reset to defaults)
  Future<void> clearAllSettings() async {
    _userProfile = UserProfile.defaultProfile();
    _medicalInfo = MedicalInfo.empty();
    _emergencyContacts = [];
    _meshSettings = MeshSettings.defaults();
    _nasaSyncSettings = NasaSyncSettings.defaults();
    _batterySettings = BatterySettings.defaults();
    _privacySettings = PrivacySettings.defaults();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    debugPrint('All settings cleared');
    notifyListeners();
  }
}
