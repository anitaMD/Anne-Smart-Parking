// ignore_for_file: avoid_print
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseService {
  //FirebaseService();
  FirebaseAuth auth = FirebaseAuth.instance;
  GoogleSignIn googleSignIn = GoogleSignIn();
  User? currentlySignedInUser;
  /*  static final instance = FirebaseService();
  Completer? _completer;

  Future<void> init() async {
    Completer? completer = _completer;
    if (completer == null) {
      completer = Completer();
      _completer = completer;
      _initInternal();
    }
    return completer.future;
  }

  void _initInternal() async {
    await Firebase.initializeApp();
    _completer!.complete();
  } */

  signInWithGoogleFailed(e) {
    {
      print(e);
    }
  }

  Future<String?> signInWithFacebook() async {
    try {
      googleSignIn.disconnect(); //pour déconnecter le précédent email utilisé to sign in.
      GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
      GoogleSignInAuthentication googleSingInAuthentication = await googleSignInAccount!.authentication;
      AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSingInAuthentication.accessToken, idToken: googleSingInAuthentication.idToken);
      await auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      print(e.message);
    }
    return null;
  }

  Future<void> signOutFromGoogle(User? user) async {
    user = auth.currentUser;
    await googleSignIn.signOut();
    await auth.signOut();
    auth.authStateChanges().listen((user) {
      print('USER IS SIGNED OUT PERFECT!');
    });
  }

  Future<void> signOutUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await auth.signOut().catchError((error) => print(error)).then((value) => {
          prefs.setBool("isLoggedIn", true),
        });
  }
}///closing brackets
