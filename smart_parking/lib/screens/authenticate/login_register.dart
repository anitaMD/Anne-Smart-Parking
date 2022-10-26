// ignore_for_file: avoid_print
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:phone_number/phone_number.dart';
import 'package:smart_parking/screens/inside_app/home.dart';
import 'package:smart_parking/screens/inside_app/googgle_si_landingpage.dart';
import 'package:smart_parking/services/firebase/firebase_service.dart';
import 'package:smart_parking/screens/authenticate/reset_password.dart';
import 'package:smart_parking/models/textfield.dart';
import 'package:smart_parking/services/firebase/firestore_service.dart';
import 'package:smart_parking/styling/styling.dart';
import 'package:smart_parking/models/user.dart';

class LoginRegister extends StatefulWidget {
  const LoginRegister({Key? key}) : super(key: key);

  @override
  LoginRegisterState createState() => LoginRegisterState();
}

enum FormType { login, register }
//enum UserType { normalUser, owner }

class LoginRegisterState extends State<LoginRegister> {
  late FocusNode myFocusNode;

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
  final formKey = GlobalKey<FormState>();
  FormType _formType = FormType.login;
  //UserType _userType = UserType.normalUser;
  bool _rememberMe = false;
  bool checkedValidNumber = false;
  bool isParkingOwner = false;
  bool fromLoginForm = false;
  bool isLogView = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();

  final GoogleSignIn _myGoogleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseService service = FirebaseService();
  FirestoreUserService firestoreService = FirestoreUserService();
  User? currentUser;

  logInWithEmailPassword() async {
    isLogView = true;

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
        if (user != null && isLogView == true) {
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
        case "user-not-found":
          {
            Fluttertoast.showToast(
                msg: e.message!,
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                fontSize: 16.0);
            print(e.code); //for me to see on the debugging console
          }
          break;

        default:
          {}
      }
      print('Error: $e');
    }
  } //closing brackets

  myValidateNumber() async {
    bool validSnPhoneNumber = false;
    String fetchedNumber = _numberController.text;
    RegionInfo region = const RegionInfo(name: 'Senegal', code: 'SN', prefix: 221);

    try {
      validSnPhoneNumber = await PhoneNumberUtil().validate(fetchedNumber, regionCode: region.code);
      if (!validSnPhoneNumber) {
        Fluttertoast.showToast(
            msg: 'Please check number format.',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            fontSize: 16.0);

        return validSnPhoneNumber;
      }
    } catch (e) {
      Fluttertoast.showToast(
          msg: 'Please enter a phone number.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          fontSize: 16.0);
    }
    if (validSnPhoneNumber) {
      checkedValidNumber = true;
    } else {
      checkedValidNumber = false;
    }
    print(' CHECKED VALID NUMBER IS $checkedValidNumber');
  }

  registerWithEmailPassword() async {
    isLogView = false;

    //UserProfile fetchedUP = userProfile;
    try {
      UserCredential user =
          await _auth.createUserWithEmailAndPassword(email: _emailController.text, password: _passwordController.text);

      await firestoreService.createUser(UserProfile(
        id: user.user!.uid,
        fullName: _fullNameController.text,
        email: _emailController.text,
        phoneNumber: _numberController.text,
        /*userRole: _userType.toString()*/
        timeStamp: FieldValue.serverTimestamp(),
        profileImage: "assets/images/no_profile_picture_grey.png",
      ));

      userProfile = UserProfile(
        id: user.user!.uid,
        fullName: _fullNameController.text,
        email: _emailController.text,
        phoneNumber: _numberController.text,
        /* userRole: _userType.toString()*/
        timeStamp: FieldValue.serverTimestamp(),
        profileImage: "assets/images/no_profile_picture_grey.png",
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Home(
            fromLoginView: false,
            theUserProfile: userProfile,
            parkingToNavigateTo: const {},
            newIndex: 0,
            timeUntilResStarts: 0,
          ),
        ),
      );
      Fluttertoast.showToast(
          msg: 'Sucessfully registered. Welcome.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          fontSize: 16.0);

      _auth.authStateChanges().listen((user) async {
        if (user != null && isLogView == false) {
/*           user.reload();
 */
          currentUser = user;
          User? thisCurrently = FirebaseAuth.instance.currentUser;
          //displayname and photoURL will be null at first because we are signing in with password and email and because we are not signing in with google or a known provider.
          print(
              'USER IS REGISTERED PERFECT! ------------- USER ID :${user.uid} '); //this is for me to view on the debugging console};
          print(
              'CURRENT USERS DISPLAYNAME : ${currentUser!.displayName} ---- Users DN ${user.displayName}----- EMAIL: ${currentUser!.email}------  ID ${currentUser!.uid} ');

          thisCurrently?.updateDisplayName(userProfile.fullName);
          thisCurrently?.updatePhotoURL(userProfile.profileImage);
          print(
              'CURRENT USERS DISPLAYNAME AFTER UPDATE: ${thisCurrently?.displayName} ____ DISPLAYNAME ${userProfile.fullName}  ____ ProfileIMAGE ${thisCurrently?.photoURL} ');
        } else {
          print('USER IS SIGNED OUT PERFECT! FROM SIGN UP WITH EMAIL');
        }
      });
    } //
    on FirebaseAuthException catch (e) {
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
            print(e.code); //for me to see on the debugging console
          }
          break;

        default:
          {}
      }
      print('Error: $e');
    }
  } //closing brackets

  /* ------------- FETCH AND SAVE FIELDS DATA -------------*/
  bool savedFormFields() {
    final form = formKey.currentState;

    if (_formType == FormType.login) {
      if (form!.validate()) {
        form.save();
        print('Form is valid. Email: $_emailController , Password: $_passwordController');
        return true;
      }
      return false;
    } else {
      myValidateNumber();
      if (form!.validate() && checkedValidNumber && _passwordController.text == _confirmPasswordController.text) {
        form.save();
        print(
            'Form is valid. Full Name : $_fullNameController, Email: $_emailController , Password: $_passwordController, Phone number: $_numberController');
        return true;
      } else if (_passwordController.text != _confirmPasswordController.text) {
        Fluttertoast.showToast(
            msg: 'The passwords do not match!',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            fontSize: 16.0);
        return false;
      }
      return false;
    }
  }
  /* ------------- FETCH AND SAVE FIELDS DATA - END -------------*/

  /* ------------- FORM VALIDATION & SUBMIT -------------*/
  void submitForm() async {
    if (savedFormFields()) {
      //In the newest version of firebase_auth, the class FirebaseUser was changed to User, and the class AuthResult was changed to UserCredential.
      if (_formType == FormType.login) /* if the login for is valid*/ {
        logInWithEmailPassword();
      } else {
        registerWithEmailPassword();
      }
    }
  }
  /* ------------- FORM VALIDATION & SUBMIT - END -------------*/

  /* ------------- SET FORM LOGIC TO REGISTER  -------------*/
  void moveToRegister() {
    formKey.currentState!.reset();
    setState(() {
      _formType = FormType.register;
    });

    super.deactivate();
  }
  /* ------------- SET FORM LOGIC TO REGISTER - END -------------*/

  /* ------------- SET FORM LOGIC TO LOGIN -------------*/
  void moveToLogIn() {
    formKey.currentState!.reset();

    setState(() {
      _formType = FormType.login;
    });
    super.deactivate();
  }
  /* ------------- SET FORM LOGIC TO REGISTER - END -------------*/

  /* ------------- SIGNIN WITH GOOGLE -------------*/
  Future<String?> mysignInWithGoogle() async {
    // to deal with the PlatformException error, I had to  edit the method invokeMethod in C:\flutter\packages\flutter\lib\src\services\platform_channel.dart and add a try catch block. Follow this link:
    // link : https://github.com/flutter/flutter/issues/44431
    try {
      GoogleSignInAccount? googleSignInAccount = await _myGoogleSignIn.signIn();
      GoogleSignInAuthentication googleSingInAuthentication = await googleSignInAccount!.authentication;
      AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSingInAuthentication.accessToken, idToken: googleSingInAuthentication.idToken);
      await FirebaseAuth.instance.signInWithCredential(credential);
      _auth.authStateChanges().listen((user) {
        currentUser = FirebaseAuth.instance.currentUser;
        print(
            'USER IS REGISTERED AND SIGNED IN PERFECT!     ${currentUser!.uid}'); //this is for me to view on the debugging console};
        currentUser!.updateDisplayName(_fullNameController.text);
        //currentUser!.reload();
        print('INFO RELOADED');
      });
      if (mounted) {
        return Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const GoogleSignInLandingPage()),
        );
      }
    } catch (e) {
      service.signInWithGoogleFailed(e);
    }
    return null;
  }
  /* ------------- SIGNIN WITH GOOGLE - END -------------*/

  /* ------------- BUILD LOGIN FORM -------------*/
  logInFormView() {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 5),
            child: Text(
              'Email',
              style: customlabelStyle,
            ),
          ),
          const SizedBox(height: 5.0),
          MyTextField(
            icon: const Icon(
              Icons.email,
              color: Colors.white,
            ),
            viewBgColor: const Color(0xFF6CA8F1),
            hint: "Enter your E-mail",
            controller: _emailController,
            inputType: TextInputType.emailAddress,
            isPassword: false,
            focusNode: myFocusNode,
            isNumber: false,
            isFullName: false,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Padding(
                padding: EdgeInsets.only(left: 5),
                child: Text(
                  'Password',
                  style: customlabelStyle,
                ),
              ),
              Text(
                '* At least 8 [uppercase, number, symbol]',
                style: TextStyle(
                  color: Colors.yellow,
                  fontFamily: 'OpenSans',
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5.0),
          MyTextField(
            icon: const Icon(
              Icons.lock,
              color: Colors.white,
            ),
            viewBgColor: const Color(0xFF6CA8F1),
            hint: "Enter your password",
            controller: _passwordController,
            inputType: TextInputType.text,
            isPassword: true,
            focusNode: myFocusNode,
            isNumber: false,
            isFullName: false,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Theme(
                    data: ThemeData(unselectedWidgetColor: Colors.white),
                    child: Checkbox(
                      value: _rememberMe,
                      checkColor: Colors.green,
                      activeColor: Colors.white,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value!;
                        });
                      },
                    ),
                  ),
                  const Text(
                    'Remember me',
                    style: customlabelStyle,
                  ),
                ],
              ),
              TextButton(
                onPressed: () =>
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ResetPassword())),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.white12),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                ),
                child: const Text(
                  'Forgot Password?',
                  style: customlabelStyle,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 15.0,
          ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              autofocus: true,
              onPressed: submitForm,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.white),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              child: const Text(
                "LOGIN",
                style:
                    TextStyle(color: Colors.black, fontSize: 18, fontFamily: 'OpenSans', fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
  /* ------------- BUILD LOGIN FORM - END -------------*/

  /* ------------- GOOGLE & FACEBOOK SIGN IN OPTIONS -------------*/
  signInButtonsInLoginView() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 35.0),
          child: Text(
            "--OR SIGN IN WITH---",
            style: TextStyle(
              fontFamily: 'OpenSans',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Material(
              elevation: 2.0,
              shape: const CircleBorder(),
              color: Colors.white,
              child: TextButton(
                onPressed: mysignInWithGoogle,
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Image.asset(
                    'assets/images/gmail.png',
                    height: 30.0,
                  ),
                ),
              ),
            ),
            /*  Material(
              elevation: 2.0,
              shape: const CircleBorder(),
              color: Colors.white,
              child: TextButton(
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Image.asset(
                    'assets/images/facebook.png',
                    height: 30.0,
                  ),
                ),

                // icon: Image.asset('assets/images/gmail.png'),
                onPressed: service.signInWithFacebook,
              ),
            ), */
          ],
        ),
      ],
    );
  }
  /* ------------- GOOGLE & FACEBOOK SIGN IN OPTIONS - END -------------*/

  /* ------------- BACK TO LOGIN SCREEN BUTTON -------------*/
  signInButtonInRegisterView() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Already have an account? ",
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'OpenSans',
          ),
        ),
        TextButton(
          onPressed: moveToLogIn,
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.black),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
          ),
          child: const Text(
            "LOGIN",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
  /* ------------- BACK TO LOGIN SCREEN BUTTON - END -------------*/

  /* ------------- GO TO REGISTER SCREEN BUTTON -------------*/
  signUpButtonInLoginView() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Don't have an account yet? ",
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'OpenSans',
          ),
        ),
        TextButton(
          onPressed: moveToRegister,
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.black),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
          ),
          child: const Text(
            "Sign Up",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
  /* ------------- GO TO REGISTER SCREEN BUTTON - END -------------*/

  /* ------------- BUILD REGISTER FORM -------------*/
  signuPFormView() {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 5),
            child: Text(
              'Full Name',
              style: customlabelStyle,
            ),
          ),
          const SizedBox(height: 1.5),
          MyTextField(
            icon: const Icon(
              Icons.email,
              color: Colors.white,
            ),
            hint: "Enter your full name",
            controller: _fullNameController,
            inputType: TextInputType.text,
            isPassword: false,
            focusNode: myFocusNode,
            viewBgColor: const Color(0xffde5d84),
            isNumber: false,
            isFullName: true,
          ),
          const Padding(
            padding: EdgeInsets.only(left: 5),
            child: Text(
              'Email',
              style: customlabelStyle,
            ),
          ),
          const SizedBox(height: 1.5),
          MyTextField(
            icon: const Icon(
              Icons.email,
              color: Colors.white,
            ),
            hint: "Enter your E-mail",
            controller: _emailController,
            inputType: TextInputType.emailAddress,
            isPassword: false,
            focusNode: myFocusNode,
            viewBgColor: const Color(0xffde5d84),
            isNumber: false,
            isFullName: false,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Padding(
                padding: EdgeInsets.only(left: 5),
                child: Text(
                  'Password',
                  style: customlabelStyle,
                ),
              ),
              Text(
                '*At least 8 [uppercase, number, symbol]',
                style: TextStyle(
                  color: Colors.yellow,
                  fontFamily: 'OpenSans',
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1.5),
          MyTextField(
            icon: const Icon(
              Icons.lock,
              color: Colors.white,
            ),
            hint: "Enter your password",
            controller: _passwordController,
            inputType: TextInputType.text,
            isPassword: true,
            focusNode: myFocusNode,
            viewBgColor: const Color(0xffde5d84),
            isNumber: false,
            isFullName: false,
          ),
          const SizedBox(height: 1.5),
          const Padding(
            padding: EdgeInsets.only(left: 5),
            child: Text(
              'Confirm Password',
              style: customlabelStyle,
            ),
          ),
          const SizedBox(height: 1.5),
          MyTextField(
            icon: const Icon(
              Icons.lock,
              color: Colors.white,
            ),
            hint: "Re-enter your password",
            controller: _confirmPasswordController,
            inputType: TextInputType.text,
            isPassword: true,
            focusNode: myFocusNode,
            viewBgColor: const Color(0xffde5d84),
            isNumber: false,
            isFullName: false,
          ),
          const SizedBox(height: 1.5),
          const Padding(
            padding: EdgeInsets.only(left: 5),
            child: Text(
              'Phone number',
              style: customlabelStyle,
            ),
          ),
          const SizedBox(height: 1.5),
          MyTextField(
            icon: const Icon(
              Icons.phone_android,
              color: Colors.white,
            ),
            hint: "Enter your phone number",
            controller: _numberController,
            inputType: TextInputType.phone,
            isPassword: false,
            focusNode: myFocusNode,
            viewBgColor: const Color(0xffde5d84),
            isNumber: true,
            isFullName: false,
          ),
          const SizedBox(height: 1.5),
          const SizedBox(
            height: 15.0,
          ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              autofocus: true,
              onPressed: submitForm,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.white),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              child: const Text(
                "SIGN UP",
                style:
                    TextStyle(color: Colors.black, fontSize: 18, fontFamily: 'OpenSans', fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 25.0),
        ],
      ),
    );
  }
  /* ------------- BUILD REGISTER FORM - END -------------*/

  /* ------------- BUILD SCREEN -------------*/
  buildView() {
    if (_formType == FormType.login) {
      return Column(
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 220,
          ),
          logInFormView(),
          signInButtonsInLoginView(),
          const SizedBox(
            height: 20,
          ),
          signUpButtonInLoginView(),
        ],
      );
    } else {
      return Column(
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 220,
          ),
          const Padding(
            padding: EdgeInsets.only(top: 10),
          ),
          signuPFormView(),
          signInButtonInRegisterView(),
        ],
      );
    }
  }
  /* ------------- BUILD SCREEN - END -------------*/

  /* ------------- SET VIEW LOGIC -------------*/
  viewSet() {
    if (_formType == FormType.login) {
      return Container(
        decoration: logDecoration,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(30, 0, 30, 0.0),
            child: buildView(),
          ),
        ),
      );
    } else {
      return Container(
        decoration: regisDecoration,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(30, 0, 30, 0.0),
            child: buildView(),
          ),
        ),
      );
    }
  }
  /* ------------- SET VIEW LOGIC - END -------------*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: viewSet(),
      ),
    );
  }
}

///ending crochet


