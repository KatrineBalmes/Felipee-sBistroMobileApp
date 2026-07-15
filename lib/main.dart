import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/landing/landing_screen.dart';

void main() {
  runApp(const FilipeesBistroApp());
}

class FilipeesBistroApp extends StatelessWidget {
  const FilipeesBistroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Filipee's Bistro",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const LandingScreen(),
    );
  }
}
