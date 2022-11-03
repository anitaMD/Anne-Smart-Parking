// ignore_for_file: avoid_unnecessary_containers

import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  NotificationsPageState createState() => NotificationsPageState();
}

class NotificationsPageState extends State<NotificationsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      child: const Center(
        child: Text("Notifications Page"),
      ),
    ));
  }
}
