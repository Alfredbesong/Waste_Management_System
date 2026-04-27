import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../reports/data/report_service.dart';
import '../../reports/presentation/report_detail_page.dart';
import '../../../shared/models/waste_report.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // Background messages need Firebase ready before they can be handled safely.
  await Firebase.initializeApp();
  debugPrint('Background message received: ${message.data}');
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
    'waste_updates',
    'Waste Updates',
    description: 'Notifications about waste report changes.',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ReportService _reportService = ReportService();
  GlobalKey<NavigatorState>? _navigatorKey;
  bool _initialized = false;
  String? _pendingReportPayload;
  bool _pendingOpenScheduled = false;

  Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    _navigatorKey = navigatorKey;
    if (_initialized) {
      return;
    }

    // Set up the native notification layer used for foreground alerts.
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create the Android notification channel once at startup.
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // Show a local notification when FCM arrives while the app is open.
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationData(message.data);
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationData(initialMessage.data);
    }

    _initialized = true;
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString() ?? 'Waste Update';
    final body =
        notification?.body ?? message.data['body']?.toString() ?? 'You have a new update on your report.';

    await _localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data['report_id']?.toString(),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    _openReportFromPayload(response.payload);
  }

  void _handleNotificationData(Map<String, dynamic> data) {
    _openReportFromPayload(data['report_id']?.toString());
  }

  Future<void> _openReportFromPayload(String? payload) async {
    final reportId = int.tryParse(payload ?? '');
    if (reportId == null) {
      debugPrint('Notification tapped without a usable report id: $payload');
      return;
    }

    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      _pendingReportPayload = payload;
      _schedulePendingOpen();
      return;
    }

    try {
      final WasteReport report = await _reportService.fetchReportById(reportId);
      navigator.pushNamed(
        ReportDetailPage.routeName,
        arguments: report,
      );
    } catch (error) {
      debugPrint('Failed to open report $reportId from notification: $error');
    }
  }

  void _schedulePendingOpen() {
    if (_pendingOpenScheduled) {
      return;
    }

    _pendingOpenScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingOpenScheduled = false;
      final payload = _pendingReportPayload;
      _pendingReportPayload = null;
      if (payload != null) {
        _openReportFromPayload(payload);
      }
    });
  }
}
