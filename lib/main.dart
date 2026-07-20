import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/landing/landing_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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