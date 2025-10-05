import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/colors.dart';
import '../providers/settings_provider.dart';
import '../models/user_profile.dart';
import '../models/medical_info.dart';
import '../models/emergency_contact.dart';
import '../models/mesh_settings.dart';
import '../models/nasa_sync_settings.dart';
import '../models/battery_settings.dart';
import '../models/privacy_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>();
      _nameController.text = settings.userProfile.name;
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(
              'Settings',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            bottom: TabBar(
              controller: _tabController!,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 3,
              tabs: const [
                Tab(icon: Icon(Icons.person_outline), text: 'Personal'),
                Tab(icon: Icon(Icons.tune), text: 'Network'),
                Tab(icon: Icon(Icons.security), text: 'Privacy'),
              ],
            ),
          ),
        ],
        body: Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            if (!settings.isLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            return Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController!,
                children: [
                  _buildPersonalTab(settings),
                  _buildNetworkTab(settings),
                  _buildPrivacyTab(settings),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Personal Tab: Profile, Medical, Emergency Contacts
  Widget _buildPersonalTab(SettingsProvider settings) {
    return ListView(
      key: const PageStorageKey<String>('personalTab'),
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader('Profile', Icons.badge),
        const SizedBox(height: 16),
        _buildProfileCard(settings),
        const SizedBox(height: 32),

        _buildSectionHeader('Medical Information', Icons.medical_services),
        const SizedBox(height: 16),
        _buildMedicalCard(settings),
        const SizedBox(height: 32),

        _buildSectionHeader('Emergency Contacts', Icons.contact_phone),
        const SizedBox(height: 16),
        _buildContactsCard(settings),
      ],
    );
  }

  // Network Tab: Mesh, NASA Sync, Battery
  Widget _buildNetworkTab(SettingsProvider settings) {
    return ListView(
      key: const PageStorageKey<String>('networkTab'),
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader('Mesh Network', Icons.hub),
        const SizedBox(height: 16),
        _buildMeshCard(settings),
        const SizedBox(height: 32),

        _buildSectionHeader('NASA Data Sync', Icons.satellite_alt),
        const SizedBox(height: 16),
        _buildNasaSyncCard(settings),
        const SizedBox(height: 32),

        _buildSectionHeader('Battery Optimization', Icons.battery_charging_full),
        const SizedBox(height: 16),
        _buildBatteryCard(settings),
      ],
    );
  }

  // Privacy Tab
  Widget _buildPrivacyTab(SettingsProvider settings) {
    return ListView(
      key: const PageStorageKey<String>('privacyTab'),
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader('Data Sharing', Icons.shield),
        const SizedBox(height: 16),
        _buildPrivacyCard(settings),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(SettingsProvider settings) {
    return Card(
      elevation: 0,
      color: AppColors.bgTertiary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline),
                filled: true,
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
              onChanged: (value) {
                settings.updateUserProfile(settings.userProfile.copyWith(name: value));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalCard(SettingsProvider settings) {
    return Card(
      elevation: 0,
      color: AppColors.bgTertiary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: settings.medicalInfo.bloodType,
              decoration: const InputDecoration(
                labelText: 'Blood Type',
                prefixIcon: Icon(Icons.bloodtype),
                filled: true,
              ),
              items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) {
                settings.updateMedicalInfo(settings.medicalInfo.copyWith(bloodType: value));
              },
            ),
            const SizedBox(height: 20),
            _buildChipSection(
              'Allergies',
              settings.medicalInfo.allergies,
              Icons.warning_amber,
              (items) => settings.updateMedicalInfo(settings.medicalInfo.copyWith(allergies: items)),
            ),
            const SizedBox(height: 20),
            _buildChipSection(
              'Medications',
              settings.medicalInfo.medications,
              Icons.medication,
              (items) => settings.updateMedicalInfo(settings.medicalInfo.copyWith(medications: items)),
            ),
            const SizedBox(height: 20),
            _buildChipSection(
              'Conditions',
              settings.medicalInfo.conditions,
              Icons.favorite,
              (items) => settings.updateMedicalInfo(settings.medicalInfo.copyWith(conditions: items)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipSection(String label, List<String> items, IconData icon, Function(List<String>) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) => Chip(
              label: Text(item, style: const TextStyle(fontSize: 13)),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () {
                final newItems = List<String>.from(items)..remove(item);
                onChanged(newItems);
              },
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              side: BorderSide.none,
            )).toList(),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showAddItemDialog(label, items, onChanged),
            icon: const Icon(Icons.add, size: 18),
            label: Text('Add $label'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactsCard(SettingsProvider settings) {
    return Card(
      elevation: 0,
      color: AppColors.bgTertiary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ...settings.emergencyContacts.map((contact) => ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text(contact.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.relationship,
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                  Text(contact.phone),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Theme.of(context).colorScheme.error,
                onPressed: () => settings.removeEmergencyContact(contact.id),
              ),
            )),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showAddContactDialog(settings),
                icon: const Icon(Icons.add),
                label: const Text('Add Emergency Contact'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeshCard(SettingsProvider settings) {
    return Card(
      elevation: 0,
      color: AppColors.bgTertiary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSliderSetting(
              'Power Level',
              Icons.signal_cellular_alt,
              settings.meshSettings.powerLevel,
              0.0,
              1.0,
              '${(settings.meshSettings.powerLevel * 100).toInt()}%',
              (value) => settings.updateMeshSettings(settings.meshSettings.copyWith(powerLevel: value)),
            ),
            const SizedBox(height: 24),
            _buildSliderSetting(
              'Range',
              Icons.radar,
              settings.meshSettings.range,
              25,
              100,
              '${settings.meshSettings.range.toInt()}m',
              (value) => settings.updateMeshSettings(settings.meshSettings.copyWith(range: value)),
            ),
            const SizedBox(height: 24),
            _buildToggleSetting(
              'Relay Mode',
              'Help extend network range for others',
              Icons.router,
              settings.meshSettings.relayMode,
              (value) => settings.updateMeshSettings(settings.meshSettings.copyWith(relayMode: value)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNasaSyncCard(SettingsProvider settings) {
    return Card(
      elevation: 0,
      color: AppColors.bgTertiary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildToggleSetting(
              'Auto Sync',
              'Automatically sync NASA hazard data',
              Icons.sync,
              settings.nasaSyncSettings.autoSync,
              (value) => settings.updateNasaSyncSettings(settings.nasaSyncSettings.copyWith(autoSync: value)),
            ),
            const SizedBox(height: 24),
            _buildSliderSetting(
              'Update Frequency',
              Icons.schedule,
              settings.nasaSyncSettings.updateFrequencyMinutes.toDouble(),
              15,
              120,
              '${settings.nasaSyncSettings.updateFrequencyMinutes} min',
              (value) => settings.updateNasaSyncSettings(
                settings.nasaSyncSettings.copyWith(updateFrequencyMinutes: value.toInt()),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Data Types', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  _buildCheckboxGroup([
                    ('Fires', 'fires', Icons.local_fire_department),
                    ('Floods', 'floods', Icons.water),
                    ('Earthquakes', 'earthquakes', Icons.waves),
                  ], settings.nasaSyncSettings.dataTypes, (types) {
                    settings.updateNasaSyncSettings(settings.nasaSyncSettings.copyWith(dataTypes: types));
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatteryCard(SettingsProvider settings) {
    return Card(
      elevation: 0,
      color: AppColors.bgTertiary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSliderSetting(
              'Emergency Mode Threshold',
              Icons.battery_alert,
              settings.batterySettings.emergencyModeThreshold.toDouble(),
              10,
              50,
              '${settings.batterySettings.emergencyModeThreshold}%',
              (value) => settings.updateBatterySettings(
                settings.batterySettings.copyWith(emergencyModeThreshold: value.toInt()),
              ),
            ),
            const SizedBox(height: 24),
            _buildToggleSetting(
              'Background Sync',
              'Allow data sync in background',
              Icons.cloud_sync,
              settings.batterySettings.backgroundSync,
              (value) => settings.updateBatterySettings(settings.batterySettings.copyWith(backgroundSync: value)),
            ),
            const SizedBox(height: 16),
            _buildToggleSetting(
              'Adaptive Power',
              'Automatically adjust based on battery',
              Icons.auto_awesome,
              settings.batterySettings.adaptivePower,
              (value) => settings.updateBatterySettings(settings.batterySettings.copyWith(adaptivePower: value)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyCard(SettingsProvider settings) {
    return Card(
      elevation: 0,
      color: AppColors.bgTertiary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildToggleSetting(
              'Share Location',
              'Essential for emergency coordination',
              Icons.location_on,
              settings.privacySettings.shareLocation,
              (value) => settings.updatePrivacySettings(settings.privacySettings.copyWith(shareLocation: value)),
            ),
            const SizedBox(height: 16),
            _buildToggleSetting(
              'Share Medical Info',
              'Share in SOS situations',
              Icons.medical_information,
              settings.privacySettings.shareMedicalInfo,
              (value) => settings.updatePrivacySettings(settings.privacySettings.copyWith(shareMedicalInfo: value)),
            ),
            const SizedBox(height: 16),
            _buildToggleSetting(
              'Anonymous Mode',
              'Hide identity on mesh network',
              Icons.visibility_off,
              settings.privacySettings.anonymousMode,
              (value) => settings.updatePrivacySettings(settings.privacySettings.copyWith(anonymousMode: value)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSetting(
    String title,
    IconData icon,
    double value,
    double min,
    double max,
    String displayValue,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                displayValue,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSetting(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildCheckboxGroup(
    List<(String, String, IconData)> options,
    Set<String> selected,
    Function(Set<String>) onChanged,
  ) {
    return Column(
      children: options.map((option) {
        final (label, value, icon) = option;
        return CheckboxListTile(
          secondary: Icon(icon),
          title: Text(label),
          value: selected.contains(value),
          onChanged: (checked) {
            final newSet = Set<String>.from(selected);
            checked! ? newSet.add(value) : newSet.remove(value);
            onChanged(newSet);
          },
        );
      }).toList(),
    );
  }

  void _showAddItemDialog(String label, List<String> items, Function(List<String>) onChanged) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Add $label'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            filled: true,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final newItems = List<String>.from(items)..add(controller.text);
                onChanged(newItems);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog(SettingsProvider settings) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationshipController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                filled: true,
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                filled: true,
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: relationshipController,
              decoration: const InputDecoration(
                labelText: 'Relationship',
                hintText: 'e.g., Family, Friend',
                filled: true,
                prefixIcon: Icon(Icons.group_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  phoneController.text.isNotEmpty &&
                  relationshipController.text.isNotEmpty) {
                final contact = EmergencyContact(
                  id: const Uuid().v4(),
                  name: nameController.text,
                  phone: phoneController.text,
                  relationship: relationshipController.text,
                );
                settings.addEmergencyContact(contact);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
