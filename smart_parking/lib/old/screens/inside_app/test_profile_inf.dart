import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_parking/old/models/pages/widgets/header_widget.dart';
import 'package:smart_parking/old/services/local_notifications/notification.dart';

class TestProfileInfo extends StatefulWidget {
  const TestProfileInfo({super.key});

  @override
  State<TestProfileInfo> createState() => _TestProfileInfoState();
}

class _TestProfileInfoState extends State<TestProfileInfo> {
  double drawerIconSize = 24;
  double drawerFontSize = 17;
  Map<String, dynamic> allUserInfo = {};
  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    /*  var ok = FirebaseAuth.instance.currentUser;
    setState(() {
      ok != null ? currentUser = ok : currentUser = null;
    }); */
    debugPrint("CURRENT USER $currentUser");
    currentUser != null ? getUserInfo(currentUser!) : null;

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> getUserInfo(User currentUser) async {
    await myDB.collection("users").doc(currentUser.uid).get().then((value) {
      setState(() {
        allUserInfo = value.data()!;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            HeaderWidget(
              height: 100,
              icon: Icons.keyboard_backspace_rounded,
              showIcon: false,
              fromLoginVerif: false,
            ),
            Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.fromLTRB(25, 10, 25, 10),
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Column(
                children: [
                  Stack(
                    fit: StackFit.passthrough,
                    children: [
                      Container(
                        width: 135.0,
                        height: 135.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(width: 5, color: Colors.white),
                          color: Colors.white,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 20,
                              offset: Offset(5, 5),
                            ),
                          ],
                        ),
                        child: Positioned.fill(
                          bottom: 2,
                          right: 2,
                          child: currentUser?.photoURL != null
                              ? CircleAvatar(
                                  // backgroundColor: Colors.grey,
                                  radius: 70,
                                  backgroundImage:
                                      NetworkImage(currentUser!.photoURL!),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Colors.grey.shade300,
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const Text(
                    'Mr. Donald Trump',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const Text(
                    'Former President',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: <Widget>[
                        Container(
                          padding:
                              const EdgeInsets.only(left: 8.0, bottom: 4.0),
                          alignment: Alignment.topLeft,
                          child: const Text(
                            "User Information",
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                        Card(
                          child: Container(
                            alignment: Alignment.topLeft,
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              children: <Widget>[
                                Column(
                                  children: <Widget>[
                                    ...ListTile.divideTiles(
                                      color: Colors.grey,
                                      tiles: [
                                        const ListTile(
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 4),
                                          leading: Icon(Icons.my_location),
                                          title: Text("Location"),
                                          subtitle: Text("USA"),
                                        ),
                                        const ListTile(
                                          leading: Icon(Icons.email),
                                          title: Text("Email"),
                                          subtitle:
                                              Text("donaldtrump@gmail.com"),
                                        ),
                                        const ListTile(
                                          leading: Icon(Icons.phone),
                                          title: Text("Phone"),
                                          subtitle: Text("99--99876-56"),
                                        ),
                                        const ListTile(
                                          leading: Icon(Icons.person),
                                          title: Text("About Me"),
                                          subtitle: Text(
                                              "This is a about me link and you can khow about me in this section."),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
