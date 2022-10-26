import 'package:flutter/material.dart';
import 'package:smart_parking/services/firebase/firebase_service.dart';
import 'package:smart_parking/screens/authenticate/login_register.dart';

class GoogleSignInLandingPage extends StatefulWidget {
  const GoogleSignInLandingPage({Key? key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<GoogleSignInLandingPage> createState() => _GoogleSignInLandingPageState();
}

class _GoogleSignInLandingPageState extends State<GoogleSignInLandingPage> {
  final FirebaseService _service = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: TextButton(
            child: const Text('Log Out now'),
            onPressed: () {
              _service.signOutFromGoogle(_service.auth.currentUser);

              /// à MODIFIER
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return const LoginRegister();
                  },
                ),
              );
            }),
      ),
    );
  }
}
