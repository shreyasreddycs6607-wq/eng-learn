import 'package:flutter/material.dart';
import 'core/services/app_services.dart';
import 'core/theme/app_theme.dart';
import 'screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  appServices = AppServices();
  await appServices.audio.loadBundledAssets();
  appServices.validateCurriculumInDebug(); // fire-and-forget, debug builds only
  runApp(const EnglishKaliyonaApp());
  appServices.reminders.restore(); // re-applies a saved daily reminder; never throws
}

class EnglishKaliyonaApp extends StatelessWidget {
  const EnglishKaliyonaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English Kaliyona',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
