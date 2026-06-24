// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:smart_parking/screens/authenticate/login_register.dart';
import 'package:smart_parking/styling/styling.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({Key? key}) : super(key: key);

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final auth = FirebaseAuth.instance;

  @override
  void initState() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
    FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    FocusNode().dispose();
    super.dispose();
  }

  final formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Container(
          decoration: resetPassBoxDeco,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 50,
              ),
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 220,
                ),
              ),
              const SizedBox(
                height: 100,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 3, bottom: 5.0),
                child: Text(
                  'Please enter your e-mail.',
                  style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'OpenSans',
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ),
              Material(
                borderRadius: BorderRadius.circular(10.0),
                color: Colors.white,
                elevation: 2.0,
                shadowColor: Colors.black45, //const Color(0xFF6CA8F1),
                child: TextFormField(
                  controller: _emailController,
                  onTap: () => FocusNode().requestFocus(),
                  decoration: const InputDecoration(
                    errorStyle: TextStyle(color: Colors.white30),
                    prefixIcon: Icon(
                      Icons.email,
                      color: Colors.black,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(14.0),
                    hintStyle: TextStyle(color: Colors.black54),
                    hintText: 'eg: email@you.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onSaved: (value) => _emailController.text = value.toString(),
                ),
              ),
              const SizedBox(
                height: 15.0,
              ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  autofocus: true,
                  onPressed: resetPassFormSubmit,
                  style: ButtonStyle(
                    overlayColor: WidgetStateProperty.all(Colors.brown),
                    backgroundColor: WidgetStateProperty.all(Colors.white),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                  child: const Text(
                    "RESET PASSWORD",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: 'OpenSans',
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ], //closing children
          ),
        ),
      ),
    );
  }

  void resetPassFormSubmit() async {
    try {
      await auth.sendPasswordResetEmail(email: _emailController.text);
      if (!mounted) return;
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const LoginRegister()));
    } on FirebaseAuthException catch (e) {
      switchEmailAuthErrorCode(e);
    }
  }

  void switchEmailAuthErrorCode(FirebaseAuthException e) {
    switch (e.code) {
      case "invalid-email":
      case "user-not-found":
        {
          Fluttertoast.showToast(
              msg: e.message!,
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              fontSize: 16.0);
          print(e.code);
        }
        break;

      default:
        {
          Fluttertoast.showToast(
              msg: 'Please enter your email address.',
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              fontSize: 16.0);
          print(e.code);
        }
    }
  }
}//closing bracks

