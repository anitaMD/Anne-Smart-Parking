// ignore_for_file: avoid_print
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_parking/models/pages/widgets/header_widget.dart';
import 'package:smart_parking/models/theme_helper.dart';
import 'package:smart_parking/screens/authenticate/test_register.dart';
import 'package:smart_parking/screens/inside_app/home.dart';
import 'package:smart_parking/services/firebase/firebase_service.dart';
import 'package:smart_parking/screens/authenticate/reset_password.dart';
import 'package:smart_parking/services/firebase/firestore_service.dart';
import 'package:smart_parking/models/user.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TestLogin extends StatefulWidget {
  const TestLogin({Key? key}) : super(key: key);

  @override
  TestLoginState createState() => TestLoginState();
}

class TestLoginState extends State<TestLogin> {
  late FocusNode myFocusNode;
  final double _headerHeight = 250;
  bool obscurText = true;

  @override
  void initState() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
    myFocusNode = FocusNode();

    super.initState();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    myFocusNode.dispose();
    super.dispose();
  }

  UserProfile userProfile = UserProfile(
      id: '', fullName: '', email: '', phoneNumber: '', timeStamp: FieldValue.serverTimestamp(), profileImage: '');
  //final formKey = GlobalKey<FormState>();
  final _formKey = GlobalKey<FormState>();

  //UserType _userType = UserType.normalUser;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseService service = FirebaseService();
  FirestoreUserService firestoreService = FirestoreUserService();
  User? currentUser;
  logInWithEmailPassword(AppLocalizations localLnSetting) async {
    try {
      await _auth.signInWithEmailAndPassword(email: _emailController.text, password: _passwordController.text);

      Fluttertoast.showToast(
          msg: 'Successfully logged in',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          fontSize: 16.0);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const Home(
                  fromLoginView: true,
                  parkingToNavigateTo: {},
                  newIndex: 0,
                  timeUntilResStarts: 0,
                )),
      );
      _auth.idTokenChanges().listen((user) async {
        if (user != null) {
          currentUser = FirebaseAuth.instance.currentUser;
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setBool("isLoggedIn", false);
          print('USER IS SIGNED IN PERFECT! LOGIN');

          if (currentUser != null) {
            await currentUser!.reload();
          }
        } else {
          print('USER IS SIGNED OUT PERFECT! FROM LOGIN WITH EMAIL');
        }
      });
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "invalid-email":
          {
            Fluttertoast.showToast(
                msg: localLnSetting.logIncorrectEmailOrPass,
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                fontSize: 16.0);
            print(e.code); //for me to see on the debugging console
          }
          break;
        case "user-not-found":
          {
            Fluttertoast.showToast(
                msg: localLnSetting.logIncorrectEmailOrPass,
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                fontSize: 15.0);
            print(e.code); //for me to see on the debugging console
          }
          break;
        case 'wrong-password':
          {
            Fluttertoast.showToast(
                msg: localLnSetting.logIncorrectEmailOrPass,
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                fontSize: 16.0);
            print(e.code); //for me to see on the debugging console

          }
          break;

        case 'network-request-failed':
          {
            Fluttertoast.showToast(
                msg: localLnSetting.verifyInternetConnection,
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                fontSize: 16.0);
            print(e.code); //for me to see on the debugging console

          }
          break;

        default:
          {
            Fluttertoast.showToast(
                msg: e.message!,
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                fontSize: 16.0);
            print(e.code);
          }
      }
      print('Error: $e');
    }
  } //closing brackets

  @override
  Widget build(BuildContext context) {
    var localLnSetting = AppLocalizations.of(context)!;

    return Scaffold(
        body: GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(FocusNode());
            },
            child: Scaffold(
              backgroundColor: Colors.white,
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      fit: StackFit.passthrough,
                      children: [
                        SizedBox(
                          height: _headerHeight,
                          child: HeaderWidget(
                            height: _headerHeight,
                            icon: Icons.login_rounded,
                            showIcon: false,
                          ), //let's create a common header widget
                        ),
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.5),
                          radius: 60,
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 200,
                          ),
                        ),
                      ],
                    ),
                    SafeArea(
                      child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                          margin: const EdgeInsets.fromLTRB(20, 10, 20, 10), // This will be the login form
                          child: Column(
                            children: [
                              Text(
                                localLnSetting.welcomeToApp,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.visible,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), //fontSize: 60,
                              ),
                              const SizedBox(height: 15),
                              Text(
                                localLnSetting.login,
                                style: const TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 30.0),
                              Form(
                                  key: _formKey,
                                  autovalidateMode: AutovalidateMode.disabled,
                                  child: Column(
                                    children: [
                                      Container(
                                        decoration: ThemeHelper().inputBoxDecorationShaddow(),
                                        child: TextFormField(
                                          validator: FormBuilderValidators.compose([
                                            FormBuilderValidators.required(),
                                            FormBuilderValidators.match(
                                                r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$",
                                                errorText: localLnSetting.logErrorBadEmailFormat)
                                          ]),
                                          controller: _emailController,
                                          keyboardType: TextInputType.emailAddress,
                                          onChanged: (value) {
                                            print("THAT'S THE VALUE $value");
                                          },
                                          decoration: ThemeHelper().textInputDecoration(Icons.mail,
                                              localLnSetting.loginEmailLabel, localLnSetting.loginEmailPlaceholder),
                                        ),
                                      ),
                                      const SizedBox(height: 30.0),
                                      Container(
                                        decoration: ThemeHelper().inputBoxDecorationShaddow(),
                                        child: TextFormField(
                                            autovalidateMode: AutovalidateMode.disabled,
                                            validator: FormBuilderValidators.compose([
                                              FormBuilderValidators.required(),
                                            ]),
                                            controller: _passwordController,
                                            obscureText: obscurText,
                                            decoration: InputDecoration(
                                              prefixIcon: const Icon(
                                                Icons.lock,
                                                size: 25,
                                                //color: Color.fromARGB(173, 0, 0, 0),
                                              ),
                                              suffixIcon: GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    obscurText == true ? obscurText = false : obscurText = true;
                                                  });
                                                },
                                                child: Icon(obscurText
                                                    ? Icons.visibility_off_outlined
                                                    : Icons.visibility_outlined),
                                              ),
                                              labelText: localLnSetting.loginPasswordLabel,
                                              hintText: localLnSetting.loginPasswordPlaceholder,
                                              fillColor: Colors.white,
                                              filled: true,
                                              contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                                              focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(100.0),
                                                  borderSide: const BorderSide(color: Colors.grey)),
                                              enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(100.0),
                                                  borderSide: BorderSide(color: Colors.grey.shade400)),
                                              errorBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(100.0),
                                                  borderSide: const BorderSide(color: Colors.red, width: 2.0)),
                                              focusedErrorBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(100.0),
                                                  borderSide: const BorderSide(color: Colors.red, width: 2.0)),
                                            )),
                                      ),

                                      /*  ThemeHelper().textInputDecoration(
                                              Icons.lock,
                                              localLnSetting.loginPasswordLabel,
                                              localLnSetting.loginPasswordPlaceholder),
                                        ), */

                                      const SizedBox(height: 15.0),
                                      Container(
                                        margin: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                                        alignment: Alignment.topRight,
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(context,
                                                MaterialPageRoute(builder: (context) => const ResetPassword()));
                                            /*   Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                                      ); */
                                          },
                                          child: Text(
                                            localLnSetting.forgotPassword,
                                            style: const TextStyle(
                                                color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        decoration: ThemeHelper().buttonBoxDecoration(context),
                                        child: ElevatedButton(
                                          style: ThemeHelper().buttonStyle(),
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(40, 10, 40, 10),
                                            child: Text(
                                              localLnSetting.signin.toUpperCase(),
                                              style: const TextStyle(
                                                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                          ),
                                          onPressed: () {
                                            submitLoginForm(localLnSetting);
                                            //After successful login we will redirect to profile page. Let's create profile page now
                                            /*  Navigator.pushReplacement(
                                          context, MaterialPageRoute(builder: (context) => const ProfilePage())); */
                                          },
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.fromLTRB(10, 20, 10, 20),
                                        //child: Text('Don\'t have an account? Create'),
                                        child: Text.rich(TextSpan(children: [
                                          TextSpan(text: localLnSetting.noAccount),
                                          TextSpan(
                                            text: localLnSetting.createAccount,
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                Navigator.push(context,
                                                    MaterialPageRoute(builder: (context) => const TestRegister()));
                                              },
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).colorScheme.secondary,
                                                fontSize: 15),
                                          ),
                                        ])),
                                      ),
                                    ],
                                  )),
                            ],
                          )),
                    ),
                  ],
                ),
              ),
            )));
  }

  /*  String? toastValidationMessages(String? value) {
    String theMessage = '';
    if (_passwordController.text.isEmpty) {
      theMessage = 'Password required!';
      /*  Fluttertoast.showToast(
        msg: 'Please enter a password.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        fontSize: 16.0,
      ); */
    } /* else {
      String pattern = r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$';
      RegExp regex = RegExp(pattern);
      if (!regex.hasMatch(_passwordController.text)) {
        theMessage = 'Please check password format.!';

        /*  Fluttertoast.showToast(
            msg: 'Please check password format.',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            fontSize: 16.0); */
      }
    } */
    return theMessage;
  }
 */
  bool savedFormFields() {
    final form = _formKey.currentState;

    if (form!.validate()) {
      form.save();
      print('Form is valid. Email: $_emailController , Password: $_passwordController');
      return true;
    }
    return false;
  }

  void submitLoginForm(AppLocalizations localLnSetting) async {
    if (savedFormFields()) {
      logInWithEmailPassword(localLnSetting);
    }
  }
}

///ending crochet


