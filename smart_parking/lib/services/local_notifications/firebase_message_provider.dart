import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'notification.dart';

class NotificationListenerProvider {
  final firebaseMessaging = FirebaseMessaging.instance.getInitialMessage();

  void getMessage(BuildContext context) {
    debugPrint("Get message called while initializing. No notification received so far... ");

    FirebaseMessaging.onMessage.listen((RemoteMessage event) {
      RemoteNotification notification = event.notification!;
      debugPrint('Yay, new notification FROM FIREBASE TEST foreground: ${notification.title}');

      // ignore: unused_local_variable
      AndroidNotification androidNotification = event.notification!.android!;

      ///Show local notification
      sendNotification(title: notification.title!, body: notification.body);

      ///Show Alert dialog
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(notification.title!),
              content: Text(notification.body!),
            );
          });
    });
  }
}
