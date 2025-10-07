import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'therapist_dashboard.dart';
import 'api_service.dart';
import 'register_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  runApp(TherapistApp(notificationService: notificationService));
}

class TherapistApp extends StatelessWidget {
  final NotificationService notificationService;
  
  const TherapistApp({super.key, required this.notificationService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Therapist App',
      navigatorKey: notificationService.navigatorKey, 
      theme: ThemeData(
        primarySwatch: MaterialColor(0xFF9A563A, {
          50: const Color(0xFFF5F1EF),
          100: const Color(0xFFE6DBD6),
          200: const Color(0xFFD5C2BA),
          300: const Color(0xFFC4A99E),
          400: const Color(0xFFB7968A),
          500: const Color(0xFF9A563A),
          600: const Color(0xFF926449),
          700: const Color(0xFF874F36),
          800: const Color(0xFF7C3B24),
          900: const Color(0xFF6B200F),
        }),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9A563A)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(), // Add this line
        '/dashboard': (context) => const DashboardWrapper(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Add a small delay for splash effect
    await Future.delayed(const Duration(seconds: 2));

    final isLoggedIn = await ApiService.isLoggedIn();

    if (mounted) {
      if (isLoggedIn) {
        final therapistData = await ApiService.getTherapistData();
        if (therapistData != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TherapistDashboard(therapistData: therapistData),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9A563A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo or Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.medical_services,
                size: 60,
                color: Color(0xFF9A563A),
              ),
            ),
            const SizedBox(height: 32),

            // App Title
            const Text(
              'Therapist App',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Professional Therapy Management',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 48),

            // Loading Indicator
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardWrapper extends StatelessWidget {
  const DashboardWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: ApiService.getTherapistData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF9A563A)),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return TherapistDashboard(therapistData: snapshot.data!);
        }

        // If no data, redirect to login
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/login');
        });

        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF9A563A)),
          ),
        );
      },
    );
  }
}
