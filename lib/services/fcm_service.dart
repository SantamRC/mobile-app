import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:mobile_app/locator.dart';
import 'package:mobile_app/services/API/fcm_api.dart';
import 'package:mobile_app/services/local_storage_service.dart';
import 'package:mobile_app/ui/views/cv_landing_view.dart';

const String _notificationsChannelId = 'cv_notifications';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final LocalStorageService _storage = locator<LocalStorageService>();
  final FCMApi _fcmApi = locator<FCMApi>();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await _initLocalNotifications();
      await _requestNotificationPermissions();
      await _setupMessageListeners();

      _isInitialized = true;
    } catch (e) {
      debugPrint('FCM init failed: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('launcher_icon');
    const iosSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) {
          _openNotificationsLanding();
          return;
        }

        try {
          final decoded = jsonDecode(payload) as Map<String, dynamic>;
          _handleNavigationFromPayload(decoded);
        } catch (_) {
          _openNotificationsLanding();
        }
      },
    );

    const channel = AndroidNotificationChannel(
      _notificationsChannelId,
      'CircuitVerse Notifications',
      description: 'Notifications for app activity and updates',
      importance: Importance.high,
    );

    final androidPlugin =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidPlugin?.createNotificationChannel(channel);
  }

  Future<void> _requestNotificationPermissions() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    final androidPlugin =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> _setupMessageListeners() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await _showForegroundNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNavigationFromPayload(message.data);
    });

    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNavigationFromPayload(initialMessage.data);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((_) async {
      await syncTokenWithBackend(force: true);
    });
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      _notificationsChannelId,
      'CircuitVerse Notifications',
      channelDescription: 'Notifications for app activity and updates',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  Future<void> syncTokenWithBackend({bool force = false}) async {
    if (!_storage.isLoggedIn || _storage.token == null) return;

    try {
      final fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      final lastSentToken = _storage.lastSentFCMToken;
      if (!force && lastSentToken == fcmToken) return;

      await _fcmApi.sendToken(fcmToken);
      _storage.lastSentFCMToken = fcmToken;
    } catch (e) {
      debugPrint('FCM token sync failed: $e');
    }
  }

  Future<void> clearTokenCache() async {
    _storage.lastSentFCMToken = null;

    try {
      await _firebaseMessaging.deleteToken();
    } catch (e) {
      debugPrint('FCM delete token failed: $e');
    }
  }

  void _handleNavigationFromPayload(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString().toLowerCase();

    switch (type) {
      case 'star':
      case 'fork':
        _openNotificationsLanding();
        break;
      default:
        _openNotificationsLanding();
    }
  }

  void _openNotificationsLanding() {
    Get.offAllNamed(CVLandingView.id, arguments: 8);
  }
}
