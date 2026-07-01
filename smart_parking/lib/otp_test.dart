import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sms_autofill/sms_autofill.dart';

class TestingOTP extends StatefulWidget {
  const TestingOTP({super.key});

  @override
  TestingOTPState createState() => TestingOTPState();
}

class TestingOTPState extends State<TestingOTP> {
  /*  late OTPTextEditController controller;
  late OTPInteractor _otpInteractor; */
  final scaffoldKey = GlobalKey();
  TextEditingController textController = TextEditingController();
  String smsCode = 'xxxx';

  String verID = '';

  void showSnackBarText(String text,
      [TextStyle snackStyle =
          const TextStyle(color: Colors.white, fontSize: 15)]) {
    if (mounted) {
      debugPrint("HERE YOU GO HAHAA $text");
      /*  ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 50,
          behavior: SnackBarBehavior.floating,
          content: Text(
            text,
            style: snackStyle,
          ),
        ),
      ); */
    }
  }

  Future<void> verifyPhone(String number) async {
    //FirebaseAuth.instance.applyActionCode(code)
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: number,
      timeout: const Duration(seconds: 50),
      verificationFailed: (FirebaseAuthException e) {
        showSnackBarText("Auth Failed!");
        if (e.code == 'invalid-phone-number') {
          debugPrint('The provided phone number is not valid.');
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        showSnackBarText("Auth OTP Sent!");

        //textController.text.length == 6 ? print("6 REACHED") : print("NOT REACHED YET");

        // Create a PhoneAuthCredential with the code

        // Sign the user in (or link) with the credential
        // await auth.signInWithCredential(credential);
        setState(() {
          verID = verificationId;
        });
      },
      //codeAutoRetrievalTimeout: (String verificationId) {},

      codeAutoRetrievalTimeout: (String verificationId) {
        showSnackBarText(
            "Auth Timeout!"); // : showSnackBarText("Auth Completed!");
      },
      verificationCompleted: (PhoneAuthCredential phoneAuthCredential) {
        showSnackBarText("AUTHENTICATION WORKED!");
      },
    );
  }

  @override
  void initState() {
    super.initState();
    SmsAutoFill().code.listen((code) {
      if (code.isNotEmpty) {
        debugPrint("THE MESSAGE $code");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP reçu automatiquement : $code'),
          ),
        );
        // Remplir le champ OTP automatiquement
        // si tu as un controller OTP :
        // _otpController.setText(code);
      }
    });
    setState(
      () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: TextField(
                    /*   onChanged: ((value) {
                      print("CONTROLLER TEXT: ${value}");
                      if (value.length == 6) {
                        setState(() {
                          smsCode = value;
                        });
                        PhoneAuthCredential credential =
                            PhoneAuthProvider.credential(verificationId: verID, smsCode: value);
                        print("credential $credential");
                      }
                    }), */
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    controller: textController //controller,
                    ),
              ),
            ),
            ElevatedButton(
                onPressed: () => verifyPhone("+221 77 500 50 43"),
                child: const Text("VERIF"))
          ],
        ),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    SmsAutoFill().unregisterListener();
    super.dispose();
  }
}
