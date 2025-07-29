import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Auth App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9A563A), // Primary color from your React Native app
          primary: const Color(0xFF9A563A),
        ),
        useMaterial3: true,
        fontFamily: 'Inter', // You can add this font to pubspec.yaml
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}