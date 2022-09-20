import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_parking/screens/inside_app/home.dart';

class MyHeaderDrawer extends StatefulWidget {
  final String headerProfilePic;
  const MyHeaderDrawer({
    Key? key,
    required this.headerProfilePic,
  }) : super(key: key);

  @override
  MyHeaderDrawerState createState() => MyHeaderDrawerState();
}

class MyHeaderDrawerState extends State<MyHeaderDrawer> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  String headerProfilePic2 = '';

  assetOrNetworkImageDrawerHeader(String headerPic) {
    if (headerPic.contains('assets/images')) {
      return DecorationImage(image: AssetImage(headerPic), fit: BoxFit.cover);
    } else {
      return DecorationImage(image: NetworkImage(headerPic), fit: BoxFit.cover);
    }
  }

  @override
  Widget build(BuildContext context) {
    headerProfilePic2 = widget.headerProfilePic;

    return Container(
      color: Colors.blue[900],
      //color: Colors.green[700],
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            child: Container(
              margin: const EdgeInsets.only(bottom: 3),
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: assetOrNetworkImageDrawerHeader(headerProfilePic2),
              ),
            ),
            onPressed: () {},
          ),
          /* Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 70,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage('assets/images/profile_picture.png'),
                fit: BoxFit.contain,
              ),
            ),
          ), */
          Text(
            HomeState().currentUser!.displayName.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
          Text(
            HomeState().currentUser!.email.toString(),
            style: TextStyle(
              color: Colors.grey[200],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}//closing bracks
