import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/providers.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable edge-to-edge transparent system UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Purge any stale local development IP so the app always uses the 24/7 Render cloud backend
  final savedBaseUrl = sharedPreferences.getString('sb_api_base_url');
  if (savedBaseUrl != null &&
      (!savedBaseUrl.startsWith('https://') ||
          savedBaseUrl.contains('192.168.') ||
          savedBaseUrl.contains('10.') ||
          savedBaseUrl.contains('172.') ||
          savedBaseUrl.contains('localhost') ||
          savedBaseUrl.contains('127.0.0.1') ||
          savedBaseUrl.contains('10.0.2.2'))) {
    await sharedPreferences.remove('sb_api_base_url');
  }

  // Initialize local notifications service
  try {
    final notificationService = NotificationService();
    await notificationService.init();
  } catch (e) {
    debugPrint('NotificationService init error (graceful fallback): $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const StudentBrainApp(),
    ),
  );
}

class StudentBrainApp extends ConsumerWidget {
  const StudentBrainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'StudentBrain',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
