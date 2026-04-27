import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/waste_management_app.dart';
import 'features/notifications/data/notification_service.dart';
import 'shared/services/theme_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final navigatorKey = GlobalKey<NavigatorState>();
  await ThemeStore.instance.load();

  if (!kIsWeb) {
    try {
      // Start Firebase before the app UI loads.
      await Firebase.initializeApp();
      // Handle notification taps when the app is in the background.
      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
      // Ask the user for notification permission on mobile devices.
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      // Allow notifications to show while the app is open.
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      // Set up local notifications for foreground FCM messages.
      await NotificationService.instance.initialize(navigatorKey: navigatorKey);
    } catch (error) {
      // Keep the app usable even if Firebase setup fails.
      debugPrint('Firebase initialization skipped: $error');
    }
  }

  runApp(WasteManagementApp(navigatorKey: navigatorKey));
}
