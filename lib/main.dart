import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/emergency/providers/emergency_provider.dart';
import 'features/emergency/providers/chat_provider.dart';
import 'features/mesh/providers/mesh_provider.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/emergency/screens/main_screen.dart';
import 'core/constants/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BeaconApp());
}

class BeaconApp extends StatelessWidget {
  const BeaconApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EmergencyProvider()),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..initialize(),
        ),
        ChangeNotifierProxyProvider<SettingsProvider, MeshProvider>(
          create: (context) => MeshProvider(),
          update: (context, settingsProvider, meshProvider) {
            meshProvider?.setUserName(settingsProvider.userProfile.name);
            return meshProvider ?? MeshProvider();
          },
        ),
        ChangeNotifierProxyProvider<MeshProvider, ChatProvider>(
          create: (context) => ChatProvider(context.read<MeshProvider>()),
          update: (context, meshProvider, chatProvider) =>
              chatProvider ?? ChatProvider(meshProvider),
        ),
      ],
      child: MaterialApp(
        title: 'Beacon',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.accentBlue,
            primaryContainer: AppColors.accentBlueDark,
            secondary: AppColors.accentBlueLight,
            surface: AppColors.bgSecondary,
            surfaceContainer: AppColors.bgSecondary,
            surfaceContainerLow: AppColors.bgSecondary,
            background: AppColors.bgPrimary,
            error: AppColors.error,
          ),
          scaffoldBackgroundColor: AppColors.bgPrimary,
          cardColor: AppColors.bgSecondary,
          dividerColor: AppColors.divider,
          useMaterial3: true,
        ),
        darkTheme: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.accentBlue,
            surface: AppColors.bgSecondary,
            background: AppColors.bgPrimary,
          ),
          scaffoldBackgroundColor: AppColors.bgPrimary,
          useMaterial3: true,
        ),
        themeMode: ThemeMode.dark,
        home: const MainScreen(),
      ),
    );
  }
}
