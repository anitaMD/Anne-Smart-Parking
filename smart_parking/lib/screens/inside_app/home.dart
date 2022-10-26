// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_parking/models/user.dart';
import 'package:smart_parking/screens/inside_app/dashboard_wrapper.dart';
import 'package:smart_parking/screens/inside_app/settings.dart';
import 'package:smart_parking/services/firebase/firebase_service.dart';
import 'package:smart_parking/screens/authenticate/login_register.dart';
import 'package:smart_parking/services/firebase/firestore_service.dart';
import 'profile_info.dart';
import 'wallet.dart';
import 'drawer/my_drawer_header.dart';
import 'faq.dart';
import 'notifications.dart';

class Home extends StatefulWidget {
  final bool fromLoginView;
  final UserProfile? theUserProfile;
  final Map<String, dynamic> parkingToNavigateTo;
  final int newIndex;
  const Home({
    Key? key,
    required this.fromLoginView,
    this.theUserProfile,
    required this.parkingToNavigateTo,
    required this.newIndex,
    required int timeUntilResStarts,
  }) : super(key: key);

  @override
  HomeState createState() => HomeState();
}

enum DrawerSections {
  dashboard,
  profileInfo,
  wallet,
  faq,
  settings,
  notifications,
  /*  privacyPolicy,
  sendFeedback, */
}

class HomeState extends State<Home> {
  int counter = 0;
  @override
  void initState() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));

    if (widget.fromLoginView) {
      //will be false if not from signup view
      print("INITSTATE IS FROM LOGVIEW ${widget.fromLoginView}");
      firestoreService.getUserFullName(currentUser!).then((value) => setState(() => logInDispName = value.toString()));

      firestoreService
          .getUserProfileImage(currentUser!)
          .then((value) => setState(() => profilePicture = value.toString()));

      currentUser!.updateDisplayName(logInDispName);
      currentUser!.updatePhotoURL(profilePicture);

      print('INIT STATE CURRENT USER NO PROFILE PIC GREY : ${currentUser!.photoURL} ');
    } else {
      print("INITSTATE IS NOT FROM LOG VIEW ${widget.fromLoginView}");
      firestoreService
          .getUserProfileImage(currentUser!)
          .then((value) => setState(() => profilePicture = value.toString()));
      currentUser!.updatePhotoURL(profilePicture);
    }

    super.initState();
  }

  User? currentUser = FirebaseAuth.instance.currentUser;
  FirestoreUserService firestoreService = FirestoreUserService();
  String appBarText = '';
  String logInDispName = '';
  var currentPage = DrawerSections.dashboard;
  String profilePicture = '';
  String barProfilePic = '';
  String test = '';

  Widget menuItem(int id, String title, IconData icon, bool selected) {
    return Material(
      color: selected ? Colors.grey[300] : Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          setState(() {
            if (id == 1) {
              currentPage = DrawerSections.dashboard;
            } else if (id == 2) {
              currentPage = DrawerSections.profileInfo;
            } else if (id == 3) {
              currentPage = DrawerSections.wallet;
            } else if (id == 4) {
              currentPage = DrawerSections.faq;
            } else if (id == 5) {
              currentPage = DrawerSections.settings;
            } else if (id == 6) {
              currentPage = DrawerSections.notifications;
            } /*  else if (id == 7) {
              currentPage = DrawerSections.privacyPolicy;
            } else if (id == 8) {
              currentPage = DrawerSections.sendFeedback;
            } */
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: [
              Expanded(
                child: Icon(
                  icon,
                  size: 20,
                  color: Colors.black,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //
  Widget myDrawerList() {
    return Container(
      padding: const EdgeInsets.only(
        top: 15,
      ),
      child: Column(
        // shows the list of menu drawer
        children: [
          menuItem(1, "Dashboard", Icons.dashboard_outlined, currentPage == DrawerSections.dashboard ? true : false),
          menuItem(2, "Profile", Icons.person, currentPage == DrawerSections.profileInfo ? true : false),
          menuItem(
              3, "Wallet", Icons.account_balance_wallet_outlined, currentPage == DrawerSections.wallet ? true : false),
          menuItem(4, "FAQs", Icons.question_answer_outlined, currentPage == DrawerSections.faq ? true : false),
          const Divider(),
          menuItem(5, "Settings", Icons.settings_outlined, currentPage == DrawerSections.settings ? true : false),
          menuItem(6, "Notifications", Icons.notifications_outlined,
              currentPage == DrawerSections.notifications ? true : false),
          const Divider(),
          /* menuItem(7, "Privacy policy", Icons.privacy_tip_outlined,
              currentPage == DrawerSections.privacyPolicy ? true : false),
          menuItem(8, "Send feedback", Icons.feedback_outlined,
              currentPage == DrawerSections.sendFeedback ? true : false), */
        ],
      ),
    );
  }

  ///
  String appBarTextDisplay() {
    if (!widget.fromLoginView) {
      print('THIS RESULT IS FROM SIGNUP VIEW ${widget.fromLoginView}');
      appBarText = '${widget.theUserProfile!.fullName}REG';
    } else {
      firestoreService.getUserFullName(currentUser!).then((value) => logInDispName = value.toString());

      currentUser?.updateDisplayName(logInDispName);
      if (currentUser != null) {
        currentUser!.reload();
      }

      print(
          'THIS IS RESULT IS FROM LOGIN VIEW ${widget.fromLoginView} and the user ${currentUser!.displayName}___ ${currentUser!.email} _______ ${currentUser!.uid} _______ ${currentUser!.photoURL}');

      currentUser != null ? appBarText = currentUser!.displayName.toString() : appBarText = "Feed";
    }
    return appBarText;
  }

  getProfilePic(String imagePath) {
    if (imagePath == '') {
      if (!widget.fromLoginView) {
        test = widget.theUserProfile!.profileImage.toString();
        setState(() {
          barProfilePic = test;
          print("BAR PROFILE REGISTER PIC from setstate : $barProfilePic");
        });
      } else {
        setState(() {
          barProfilePic = currentUser!.photoURL.toString();
          print("BAR PROFILE PIC from setstate : $barProfilePic");
        });
      }
    } else {
      if (!widget.fromLoginView) {
        setState(() {
          widget.theUserProfile!.profileImage = imagePath; //PROBLEM HERE
          currentUser!.updatePhotoURL(imagePath);
          print("SET STATE FROM GETPROFILEPIC FUNC ELSE : ${widget.theUserProfile!.profileImage}");
          barProfilePic = imagePath;
          MyHeaderDrawerState().headerProfilePic2 = barProfilePic;
        });
      } else {
        currentUser = FirebaseAuth.instance.currentUser;
        currentUser?.updatePhotoURL(imagePath); //PROBLEM HERE
        setState(() {
          barProfilePic = imagePath;
          MyHeaderDrawerState().headerProfilePic2 = barProfilePic;
        });
      }
    }
  }

  /*TEST
  
  getProfilePic(String imagePath) {
    if (imagePath == '') {
      if (!widget.fromLoginView) {
        setState(() {
          barProfilePic = widget.theUserProfile!.profileImage.toString();
          print("BAR PROFILE REGISTER PIC from setstate : $barProfilePic");
          status = widget.fromLoginView;
        });
      } else {
        setState(() {
          barProfilePic = currentUser!.photoURL.toString();
          print("BAR PROFILE PIC from setstate : $barProfilePic");
          status = widget.fromLoginView;
        });
      }
    } else {
      setState(() {
        barProfilePic = imagePath;
        MyHeaderDrawerState().headerProfilePic2 = barProfilePic;
      });
    }
  } */

  assetOrNetworkImageBar(String barProfilePic) {
    if (barProfilePic.contains('assets/images')) {
      return DecorationImage(image: AssetImage(barProfilePic), fit: BoxFit.cover);
    } else {
      return DecorationImage(image: NetworkImage(barProfilePic), fit: BoxFit.cover);
    }
  }

  showAppBar() {
    if (currentPage != DrawerSections.profileInfo && currentPage != DrawerSections.notifications) {
      Color notificationColor;
      String countNumberFormatDisplay;
      counter != 0 ? notificationColor = Colors.red : notificationColor = Colors.red.withOpacity(0.0);
      counter > 9 ? countNumberFormatDisplay = '9+' : countNumberFormatDisplay = '$counter';
      return AppBar(
        elevation: 1,
        toolbarHeight: kToolbarHeight,
        backgroundColor: currentPage == DrawerSections.wallet ? Colors.white : Colors.blueGrey,
        /* shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(40),
          ),
        ), */
        title: Text(
          appBarText,
          style: currentPage != DrawerSections.wallet
              ? const TextStyle(color: Colors.white)
              : const TextStyle(color: Colors.black),
        ),
        //flexibleSpace: currentPage != DrawerSections.wallet ? null : Wallet(),
        actions: <Widget>[
          // Using Stack to show Notification Badge

          Stack(
            children: <Widget>[
              InkWell(
                onTap: () {
                  setState(() {
                    counter = 0;
                  });
                },
                child: SizedBox(
                  width: 96,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Stack(
                        children: [
                          IconButton(
                              icon: const Icon(Icons.notifications_none_outlined),
                              iconSize: 30,
                              color: Colors.white,
                              onPressed: () {
                                setState(() {
                                  counter = 0;
                                });
                              }),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              constraints: const BoxConstraints(
                                minHeight: 26,
                                minWidth: 26,
                              ),
                              decoration: BoxDecoration(shape: BoxShape.circle, color: notificationColor),
                              alignment: Alignment.center,
                              child: Text(
                                countNumberFormatDisplay,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'OpenSans'),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
        leading: Builder(builder: (BuildContext context1) {
          return Padding(
            padding: const EdgeInsets.all(3.0),
            child: TextButton(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: assetOrNetworkImageBar(barProfilePic),
                ),
              ),
              onPressed: () => Scaffold.of(context1).openDrawer(),
            ),
          );
        }),
        leadingWidth: 55,
      );
    } else {
      return null;
    }
  }

  buildNormalUserView() {
    FirebaseService parkingUserAuthService = FirebaseService();
    //FirestoreService parkingUserFirestoreService = FirestoreService();
    Widget container;
    container = Container();
    if (currentPage == DrawerSections.dashboard) {
      container = DashboardWrapperPage(
        parkingToNavigateTo: widget.parkingToNavigateTo,
        newIndex: widget.newIndex,
      );
    } else if (currentPage == DrawerSections.profileInfo) {
      container = ProfileInfo(profilePic: barProfilePic, customFunction: getProfilePic, status: widget.fromLoginView);
    } else if (currentPage == DrawerSections.wallet) {
      container = const Wallet();
    } else if (currentPage == DrawerSections.faq) {
      container = const NotesPage();
    } else if (currentPage == DrawerSections.settings) {
      container = const SettingsPage();
    } else if (currentPage == DrawerSections.notifications) {
      container = const NotificationsPage();
    } /*  else if (currentPage == DrawerSections.privacyPolicy) {
      container = const PrivacyPolicyPage();
    } else if (currentPage == DrawerSections.sendFeedback) {
      container = const SendFeedbackPage();
    } */

    appBarTextDisplay();
    getProfilePic('');

    return Scaffold(
      appBar: showAppBar(),
      /* floatingActionButton: Center(
        child: FloatingActionButton(
          onPressed: () {
            print("Increment Counter");
            setState(() {
              counter++;
            });
          },
          child: const Icon(Icons.add),
        ),
      ), */
      backgroundColor: Colors.white,
      body: container,
      drawer: Drawer(
        child: SingleChildScrollView(
          child: Column(
            children: [
              MyHeaderDrawer(
                headerProfilePic: barProfilePic, //barProfilePic already checked whether this is the login or signupview
              ),
              myDrawerList(),
              Material(
                child: InkWell(
                  onTap: () async {
                    parkingUserAuthService.signOutUser();
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    prefs.setBool("isLoggedIn", true);
                    if (!mounted) return;
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginRegister()));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      children: const [
                        Expanded(
                          child: Icon(
                            Icons.logout,
                            size: 20,
                            color: Colors.black,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildNormalUserView();
  }
}




 /* buildNormalUserView() {
    FirebaseService parkingUserAuthService = FirebaseService();
    //FirestoreService parkingUserFirestoreService = FirestoreService();

    appBarTextDisplay();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appBarText,
        ),
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.red),
                ),
                child: const Text('click to log out'),
                onPressed: () {
                  parkingUserAuthService.signOutUser();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginRegister()));
                }),
          ],
        ),
      ),
    );
  } */
