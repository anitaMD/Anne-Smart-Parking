import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TestDrawerImageUsername extends StatefulWidget {
  final User currentUser;
  const TestDrawerImageUsername({super.key, required this.currentUser});

  @override
  State<TestDrawerImageUsername> createState() =>
      _TestDrawerImageUsernameState();
}

class _TestDrawerImageUsernameState extends State<TestDrawerImageUsername> {
  @override
  Widget build(BuildContext context) {
    // String? profileImageURL = widget.currentUser.photoURL;
    String profileImageURL =
        "https://firebasestorage.googleapis.com/v0/b/smartparking-anne.appspot.com/o/users%2Fprofile%2Fno_profile_picture_grey.png?alt=media&token=8de58b2e-8411-452b-923c-3c23555da303";

    return Container(
      color: Colors.blue[900],
      //color: Colors.green[700],
      width: double.infinity,
      height: 300,
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
              maxRadius: 60,
              backgroundImage: widget.currentUser.photoURL != null
                  ? NetworkImage(widget.currentUser.photoURL!)
                  : NetworkImage(profileImageURL)),
          const SizedBox(height: 20),
          Text(
            widget.currentUser.displayName.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
          Text(
            widget.currentUser.email.toString(),
            style: TextStyle(
              color: Colors.grey[200],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
