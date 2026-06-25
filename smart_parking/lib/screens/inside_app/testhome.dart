import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_parking/screens/authenticate/testlogin.dart';
import 'package:smart_parking/screens/inside_app/drawer/test_drawer_image_username.dart';
import 'package:smart_parking/screens/inside_app/faq.dart';
import 'package:smart_parking/screens/inside_app/notifications.dart';
import 'package:smart_parking/screens/inside_app/settings.dart';
import 'package:smart_parking/screens/inside_app/test_dashwrapper.dart';
import 'package:smart_parking/screens/inside_app/test_profile_inf.dart';
import 'package:smart_parking/screens/inside_app/wallet.dart';
import 'package:smart_parking/services/firebase/firebase_service.dart';
import 'package:smart_parking/l10n/generated/app_localizations.dart';

class TestHome extends StatefulWidget {
  final int timeUntilReservationStarts;
  final Map<String, dynamic> newMoreUrgentBooking;
  const TestHome(
      {Key? key,
      this.timeUntilReservationStarts = 0,
      required this.newMoreUrgentBooking})
      : super(key: key);

  @override
  State<TestHome> createState() => _TestHomeState();
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

class _TestHomeState extends State<TestHome> {
  final double drawerIconSize = 24;
  final double drawerFontSize = 17;
  FirebaseService parkingUserAuthService = FirebaseService();
  var currentPage = DrawerSections.dashboard;
  late User currentUser;

  @override
  void initState() {
    super.initState();
    var potentialCurrentUser = parkingUserAuthService.auth.currentUser;
    potentialCurrentUser != null
        ? setState(() => currentUser = potentialCurrentUser)
        : debugPrint("NO USER SIGNED IN");
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var localLnSetting = AppLocalizations.of(context)!;
    int ok = widget.timeUntilReservationStarts;
    Map<String, dynamic> okUrgent = widget.newMoreUrgentBooking;
    currentPage != DrawerSections.dashboard ? {ok = 0, okUrgent = {}} : null;
    debugPrint("okUrgent $okUrgent");

    return Scaffold(
      appBar: AppBar(
        title: getCurrentDrawerSectionName(localLnSetting,
            currentPage: currentPage),
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                Theme.of(context).primaryColor,
                Theme.of(context).colorScheme.secondary,
              ])),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(
              top: 16,
              right: 16,
            ),
            child: Stack(
              children: <Widget>[
                const Icon(Icons.notifications),
                Positioned(
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: const Text(
                      '5',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
      drawer: Drawer(
        child: SingleChildScrollView(
          child: Column(
            children: [
              TestDrawerImageUsername(currentUser: currentUser),
              /* MyHeaderDrawer(
                headerProfilePic: barProfilePic, //barProfilePic already checked whether this is the login or signupview
              ), */
              /*  Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, stops: const [
                  0.0,
                  1.0
                ], colors: [
                  Theme.of(context).primaryColor.withValues(alpha:0.2),
                  Theme.of(context).colorScheme.secondary.withValues(alpha:0.5),
                ])),
                height: 200,
              ), */
              myDrawerList(),
              Material(
                child: InkWell(
                  onTap: () async {
                    final nav = Navigator.of(context);

                    parkingUserAuthService.signOutUser();
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    prefs.setBool("isLoggedIn", true);
                    nav.push(MaterialPageRoute(
                        builder: (context) => const TestLogin()));
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(15.0),
                    child: Row(
                      children: [
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
      body: getBodyContent(currentUser, ok, okUrgent),
    );
  }

  Widget myDrawerList() {
    debugPrint("CURRENTUSER IS: $currentUser");

    return Container(
      padding: const EdgeInsets.only(
        top: 15,
      ),
      child: Column(
        children: [
          menuItem(1, "Dashboard", Icons.dashboard_outlined,
              currentPage == DrawerSections.dashboard ? true : false),
          menuItem(2, "Profile", Icons.person,
              currentPage == DrawerSections.profileInfo ? true : false),
          menuItem(3, "Wallet", Icons.account_balance_wallet_outlined,
              currentPage == DrawerSections.wallet ? true : false),
          menuItem(4, "FAQs", Icons.question_answer_outlined,
              currentPage == DrawerSections.faq ? true : false),
          const Divider(),
          menuItem(5, "Settings", Icons.settings_outlined,
              currentPage == DrawerSections.settings ? true : false),
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
              /*  widget.newIndex == 6
                  ? {currentPage = DrawerSections.profileInfo, }
                  :  */
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

  Text getCurrentDrawerSectionName(AppLocalizations localLnSetting,
      {required DrawerSections currentPage}) {
    String textToDisplay = '';
    currentPage == DrawerSections.dashboard
        ? textToDisplay = 'Dashboard'
        : currentPage == DrawerSections.profileInfo
            ? textToDisplay = 'Profile'
            : currentPage == DrawerSections.wallet
                ? textToDisplay = 'Wallet'
                : currentPage == DrawerSections.faq
                    ? textToDisplay = 'History'
                    : currentPage == DrawerSections.settings
                        ? textToDisplay = 'Settings'
                        : textToDisplay = 'Notifications';

    return Text(
      textToDisplay,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    );
  }

  Widget getBodyContent(
      User currentUser, int ok, Map<String, dynamic> okUrgent) {
    Widget bodyContainer = Container();
    if (currentPage == DrawerSections.dashboard) {
      setState(() {
        bodyContainer = TestDashboardWrapper(
            timeUntilResStartsFromBookingOverview: ok,
            parkingToNavigateTo: const {},
            newMoreUrgentBooking: okUrgent);
      });
    } else if (currentPage == DrawerSections.profileInfo) {
      bodyContainer = const TestProfileInfo();
    } else if (currentPage == DrawerSections.wallet) {
      bodyContainer = const Wallet(
        takescreenshot: false,
      );
    } else if (currentPage == DrawerSections.faq) {
      bodyContainer = const NotesPage();
    } else if (currentPage == DrawerSections.settings) {
      bodyContainer = const SettingsPage();
    } else if (currentPage == DrawerSections.notifications) {
      bodyContainer = const NotificationsPage();
    }
    return bodyContainer;
  }

  //closingbracks
}

  
/* final double _drawerIconSize = 24;
  final double _drawerFontSize = 17;
/*  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      height: 100,
      width: 100,
      color: Colors.red,
    ));
  } */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profile Page",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: <Color>[
            Theme.of(context).primaryColor,
            Theme.of(context).colorScheme.secondary,
          ])),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(
              top: 16,
              right: 16,
            ),
            child: Stack(
              children: <Widget>[
                const Icon(Icons.notifications),
                Positioned(
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: const Text(
                      '5',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, stops: const [
            0.0,
            1.0
          ], colors: [
            Theme.of(context).primaryColor.withValues(alpha:0.2),
            Theme.of(context).colorScheme.secondary.withValues(alpha:0.5),
          ])),
          child: ListView(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0.0, 1.0],
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
                child: Container(
                  alignment: Alignment.bottomLeft,
                  child: const Text(
                    "FlutterTutorial.Net",
                    style: TextStyle(fontSize: 25, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              ListTile(
                  leading: Icon(
                    Icons.screen_lock_landscape_rounded,
                    size: _drawerIconSize,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  title: Text(
                    'Splash Screen',
                    style: TextStyle(fontSize: 17, color: Theme.of(context).colorScheme.secondary),
                  ),
                  onTap: () {}),
              ListTile(
                leading:
                    Icon(Icons.login_rounded, size: _drawerIconSize, color: Theme.of(context).colorScheme.secondary),
                title: Text(
                  'Login Page',
                  style: TextStyle(fontSize: _drawerFontSize, color: Theme.of(context).colorScheme.secondary),
                ),
                onTap: () {},
              ),
              Divider(
                color: Theme.of(context).primaryColor,
                height: 1,
              ),
              ListTile(
                leading:
                    Icon(Icons.person_add_alt_1, size: _drawerIconSize, color: Theme.of(context).colorScheme.secondary),
                title: Text(
                  'Registration Page',
                  style: TextStyle(fontSize: _drawerFontSize, color: Theme.of(context).colorScheme.secondary),
                ),
                onTap: () {},
              ),
              Divider(
                color: Theme.of(context).primaryColor,
                height: 1,
              ),
              ListTile(
                leading: Icon(
                  Icons.password_rounded,
                  size: _drawerIconSize,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                title: Text(
                  'Forgot Password Page',
                  style: TextStyle(fontSize: _drawerFontSize, color: Theme.of(context).colorScheme.secondary),
                ),
                onTap: () {},
              ),
              Divider(
                color: Theme.of(context).primaryColor,
                height: 1,
              ),
              ListTile(
                leading: Icon(
                  Icons.verified_user_sharp,
                  size: _drawerIconSize,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                title: Text(
                  'Verification Page',
                  style: TextStyle(fontSize: _drawerFontSize, color: Theme.of(context).colorScheme.secondary),
                ),
                onTap: () {},
              ),
              Divider(
                color: Theme.of(context).primaryColor,
                height: 1,
              ),
              ListTile(
                leading: Icon(
                  Icons.logout_rounded,
                  size: _drawerIconSize,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                title: Text(
                  'Logout',
                  style: TextStyle(fontSize: _drawerFontSize, color: Theme.of(context).colorScheme.secondary),
                ),
                onTap: () {
                  //SystemNavigator.pop();
                },
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            SizedBox(
              height: 100,
              child: HeaderWidget(
                height: 100,
                icon: Icons.house_rounded,
                showIcon: false,
              ),
            ),
            Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.fromLTRB(25, 10, 25, 10),
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
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
                    child: Icon(
                      Icons.person,
                      size: 80,
                      color: Colors.grey.shade300,
                    ),
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
                          padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
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
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          leading: Icon(Icons.my_location),
                                          title: Text("Location"),
                                          subtitle: Text("USA"),
                                        ),
                                        const ListTile(
                                          leading: Icon(Icons.email),
                                          title: Text("Email"),
                                          subtitle: Text("donaldtrump@gmail.com"),
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
    ); */