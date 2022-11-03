import 'package:badges/badges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_parking/screens/inside_app/home.dart';

import '../for_notifications/display_notifs.dart';

class BadgesNotifications extends StatefulWidget {
  const BadgesNotifications({Key? key}) : super(key: key);

  @override
  State<BadgesNotifications> createState() => _BadgesNotificationsState();
}

class _BadgesNotificationsState extends State<BadgesNotifications> {
  var myDB = FirebaseFirestore.instance;
  Map<String, dynamic> allNotifications = {};
  int notificationsBadgeCounter = 10, pressedOnce = 0;
  bool pressedOnNotifIcon = false;

  @override
  void initState() {
    super.initState();
    /*m yDB.collection('users/${FirebaseAuth.instance.currentUser?.uid}/notifications').get().then((value) {
      value.docChanges.isEmpty
          ? setState(() => notificationsBadgeCounter = 0)
          : value.docChanges.forEach((element) {
              allNotifications.addAll(value.docChanges);
            });
    }); */
  }

  @override
  Widget build(BuildContext context) {
    /*  myDB.collection('users/${FirebaseAuth.instance.currentUser?.uid}/notifications').get().then((value) {
      value.docChanges.isEmpty
          ? notificationsBadgeCounter = 0
          : value.docChanges.forEach((element) {
              allNotifications.addAll(element.doc.data()!);
            });
    }); */
    print("ALL NOTIFS :${allNotifications.length}");
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection("users/${FirebaseAuth.instance.currentUser?.uid}/notifications")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Text('');
          } else {
            var notificationsFetched = snapshot.data!.docs;
            debugPrint(
                "THE NOTIFICATION ITSELF :${notificationsFetched.length} _ cganges ! ${snapshot.data!.docChanges.length}");
            notificationsBadgeCounter = pressedOnNotifIcon == false ? notificationsFetched.length : 0;

            return Badge(
                toAnimate: false,
                // borderSide: BorderSide(color: Colors.black),
                position: BadgePosition.topEnd(),
                elevation: 3,
                badgeColor: Colors.red.shade500,
                showBadge: notificationsBadgeCounter == 0 ? false : true,
                padding: EdgeInsets.all(7),
                badgeContent: Text(
                  '$notificationsBadgeCounter',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                child: IconButton(
                    icon: const Icon(Icons.notifications_none_outlined),
                    iconSize: 30,
                    color: Colors.white,
                    onPressed: () {
                      setState(() {
                        pressedOnNotifIcon = true;
                        notificationsBadgeCounter = 0;
                        //pressedOnNotifIcon = false;
                      });
                      pressedOnce ~/ 2 == 0
                          ? Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Home(
                                      fromLoginView: true,
                                      parkingToNavigateTo: {},
                                      newIndex: 6,
                                      timeUntilResStarts: -1)))
                          : Navigator.of(context).pop();

                      setState(() {
                        pressedOnce += 1;
                      });
                    }));
          }
        });
  }
}
