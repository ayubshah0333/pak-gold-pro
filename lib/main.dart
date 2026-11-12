import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'services/ad_service.dart';
import 'services/preferences_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Mobile Ads SDK safely
  await AdService.initialize();
  AdService.loadInterstitialAd();

  // Initialize persistent preferences
  final prefs = await PreferencesService.init();

  runApp(GoldCalculatorApp(prefs: prefs));
}

class GoldCalculatorApp extends StatelessWidget {
  final PreferencesService prefs;

  const GoldCalculatorApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pak Gold Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: SplashScreen(prefs: prefs),
    );
  }
}
