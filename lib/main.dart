import 'package:flutter/material.dart';
import 'core/services/app_services.dart';
import 'core/theme/app_theme.dart';
import 'screens/home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  appServices = AppServices();
  appServices.validateCurriculumInDebug(); // fire-and-forget, debug builds only
  runApp(const EnglishKaliyonaApp());
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
