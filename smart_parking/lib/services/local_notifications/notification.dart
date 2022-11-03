import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smart_parking/screens/inside_app/for_dashboard/badges_notifications.dart';
import 'package:smart_parking/services/firebase/firebase_service.dart';

var myDB = FirebaseFirestore.instance;

void sendNotification({String? title, String? body}) async {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  print("FROM NOTIF${FirebaseAuth.instance.currentUser?.uid}");

  ////Set the settings for various platform
  // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const LinuxInitializationSettings initializationSettingsLinux = LinuxInitializationSettings(
    defaultActionName: 'hello',
  );
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid, linux: initializationSettingsLinux);
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
  );

  ///
  const AndroidNotificationChannel channel = AndroidNotificationChannel('high_channel', 'High Importance Notification',
      description: "This channel is for important notification", importance: Importance.max);

  flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(channel.id, channel.name, channelDescription: channel.description),
    ),
  );
  myDB.collection('users/${FirebaseAuth.instance.currentUser?.uid}/notifications').add({
    'Received': FieldValue.serverTimestamp(),
    'Notification': {'title': title, 'body': body}
  });

  /* allNotifs.add(
    NotificationDetails(
      android: AndroidNotificationDetails(channel.id, channel.name, channelDescription: channel.description),
    ),
  ); */
}
