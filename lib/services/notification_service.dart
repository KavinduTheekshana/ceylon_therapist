import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message received: ${message.messageId}');
  print('Notification: ${message.notification?.title}');
  print('Data: ${message.data}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _fcmToken;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Initialize notification service
  Future<bool> initialize() async {
    try {
      // Request permissions
      final granted = await requestPermission();
      if (!granted) {
        print('Notification permission denied');
        return false;
      }

      // Get FCM token
      _fcmToken = await getFCMToken();
      if (_fcmToken != null) {
        print('FCM Token: $_fcmToken');
        await registerTokenWithBackend(_fcmToken!);
      }

      // Setup background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Setup notification listeners
      _setupNotificationListeners();

      // Handle notification that opened the app
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        print('App opened from notification: ${initialMessage.messageId}');
        _handleNotification(initialMessage);
      }

      return true;
    } catch (e) {
      print('Error initializing notifications: $e');
      return false;
    }
  }

  // Request notification permissions
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
           settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  // Get FCM token
  Future<String?> getFCMToken() async {
    try {
      final token = await _messaging.getToken();
      print('FCM Token obtained: ${token?.substring(0, 20)}...');
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  // Register token with backend
  Future<void> registerTokenWithBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken == null) {
        print('No access token found, skipping token registration');
        return;
      }

      // REPLACE WITH YOUR ACTUAL BACKEND URL
      const String backendUrl = 'http://10.0.2.2:8000';
      
      final response = await http.post(
        Uri.parse('$backendUrl/api/therapist/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'fcm_token': token,
          'device_type': 'android',
          'device_id': 'device_${DateTime.now().millisecondsSinceEpoch}',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          print('FCM token registered successfully');
          await prefs.setBool('fcm_token_registered', true);
        }
      } else {
        print('Failed to register FCM token: ${response.statusCode}');
      }
    } catch (e) {
      print('Error registering token with backend: $e');
    }
  }

  // Setup notification listeners
  void _setupNotificationListeners() {
    // Foreground messages - show snackbar instead of notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');

      _showForegroundNotification(message);
    });

    // Background message opened (user tapped notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Background message opened');
      _handleNotification(message);
    });
  }

  // Show notification when app is in foreground (using snackbar)
  void _showForegroundNotification(RemoteMessage message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final notification = message.notification;
    if (notification == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title ?? 'New Notification',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(notification.body ?? ''),
          ],
        ),
        backgroundColor: const Color(0xFF9A563A),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () => _handleNotification(message),
        ),
      ),
    );
  }

  // Handle notification tap/open
  void _handleNotification(RemoteMessage message) {
    final data = message.data;
    print('Handling notification: $data');

    final type = data['type'];
    
    if (type == 'booking_created' || type == 'booking_cancelled') {
      final bookingId = data['booking_id'];
      if (bookingId != null) {
        _navigateToBooking(bookingId);
      }
    }
  }

  // Navigate to booking details
  void _navigateToBooking(String bookingId) {
    print('Navigating to booking: $bookingId');
    
    // UPDATE THIS WITH YOUR ACTUAL ROUTE NAME
    navigatorKey.currentState?.pushNamed(
      '/booking-details',
      arguments: {'bookingId': bookingId},
    );
  }

  // Unregister token (on logout)
  Future<void> unregisterToken() async {
    try {
      if (_fcmToken == null) return;

      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken == null) return;

      // REPLACE WITH YOUR ACTUAL BACKEND URL
      const String backendUrl = 'http://10.0.2.2:8000';

      await http.delete(
        Uri.parse('$backendUrl/api/therapist/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'fcm_token': _fcmToken,
        }),
      );

      await prefs.remove('fcm_token_registered');
      print('FCM token unregistered');
    } catch (e) {
      print('Error unregistering token: $e');
    }
  }
}