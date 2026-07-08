import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'notification.dart';
import 'package:smart_parking/main.dart';

class NotificationListenerProvider {
  final firebaseMessaging = FirebaseMessaging.instance.getInitialMessage();

  // Utiliser un callback au lieu de context directement
  void getMessage(BuildContext context) {
    debugPrint("Get message called while initializing...");

    FirebaseMessaging.onMessage.listen((RemoteMessage event) {
      final notification = event.notification;
      if (notification == null) return;

      debugPrint('New notification: ${notification.title}');

      // Notification locale — pas besoin de context
      sendNotification(
        title: notification.title!,
        body: notification.body,
      );

      // Pour le dialog, utiliser le NavigatorKey global
      // au lieu du context
      _showNotificationDialog(
        title: notification.title!,
        body: notification.body ?? '',
      );
    });
  }

  void _showNotificationDialog({
    required String title,
    required String body,
  }) {
    final navigatorContext =
        navigatorKey.currentContext; // ← clé globale (voir ci-dessous)
    if (navigatorContext == null) return;

    showDialog(
      context: navigatorContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
        );
      },
    );
  }
}
