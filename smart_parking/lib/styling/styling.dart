import 'package:flutter/material.dart';

const splashDecoration = BoxDecoration(
    gradient: LinearGradient(
        begin: Alignment(-1.0, -1),
        end: Alignment(-1.0, 1),
        // ignore: prefer_const_literals_to_create_immutables
        colors: [
      /*  Color(0xff000046),
      Color(0xff1cb5e0), */ //à retenir
      /* Color(0xff4568dc), // à retenir
      Color(0xff2f80ed), */
      Color(0xff5924e5),
      Color(0xff48fefc),
    ]));

const logDecoration = BoxDecoration(
    gradient: LinearGradient(
        begin: Alignment(-1.0, -1),
        end: Alignment(-1.0, 1),
        // ignore: prefer_const_literals_to_create_immutables
        colors: [
      /*  Color(0xff000046),
      Color(0xff1cb5e0), */ //à retenir
      /* Color(0xff4568dc), // à retenir
      Color(0xff2f80ed), */
      Color(0xff5924e5),
      Color(0xff48fefc),
    ]));

const regisDecoration = BoxDecoration(
    gradient: LinearGradient(
        begin: Alignment(-1.0, -1),
        end: Alignment(-1.0, 1),
        // ignore: prefer_const_literals_to_create_immutables
        colors: [
      /*  Color(0xff000046),
      Color(0xff1cb5e0), */ //à retenir
      /* Color(0xff4568dc), // à retenir
      Color(0xff2f80ed), */
      Color(0xffde5d84),
      Color(0xffc7c3d0),
    ]));

const descTextStyle = TextStyle(
  color: Colors.white,
  fontSize: 16,
  height: 1.8,
);

Color bgcSlide1 = Colors.amber;
Color bgcSlide2 = Colors.purpleAccent;
Color bgcSlide3 = Colors.brown;
Color bgcSlide4 = Colors.blueAccent;

const hintTextStyle = TextStyle(
  color: Colors.white54,
  fontFamily: 'OpenSans',
);

BoxDecoration boxDecorationStyle = BoxDecoration(
  color: const Color(0xFF6CA8F1),
  borderRadius: BorderRadius.circular(10.0),
  boxShadow: const [
    BoxShadow(
      color: Colors.green,
      blurRadius: 6.0,
      offset: Offset(0, 2),
    ),
  ],
);

const customlabelStyle = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.bold,
  fontFamily: 'OpenSans',
);

const customlabelStyleAddCar = TextStyle(
  color: Colors.blue,
  // fontWeight: FontWeight.w600,
  //fontFamily: 'OpenSans',
);

const resetPassBoxDeco = BoxDecoration(
    gradient: LinearGradient(
        begin: Alignment(-1.0, -1),
        end: Alignment(-1.0, 1),
        // ignore: prefer_const_literals_to_create_immutables
        colors: [
      /*  Color(0xff000046),
      Color(0xff1cb5e0), */ //à retenir
      /* Color(0xff4568dc), // à retenir
      Color(0xff2f80ed), */
      Color(0xffffb347),
      Color(0xffffcc33),
    ]));

const resetPasswordStyle = TextStyle(
  color: Colors.transparent,
  fontSize: 30,
  fontFamily: 'OpenSans',
  fontWeight: FontWeight.bold,
);

/// PROFILE INFO
const Color primaryColor = Color(0xFFDB3620);
const Color primaryColorOpacity = Colors.black; //Color(0xFFFF7F50);
const Color hintTextColor = Color(0xFFE4E0E8);
const Color primaryTextColor = Color(0xFF1A1316);
const Color secondaryTextColor = Color(0xFF8391A0);
const Color tertiaryTextColor = Color(0xFFB5ADAC);
final Color greenColor = Colors.green.shade400;
const Color blueColor = Colors.lightBlueAccent;

const headingTextStyle = TextStyle(
  fontSize: 26.0,
  color: Colors.white,
  fontWeight: FontWeight.w700,
  fontFamily: 'OpenSans',
  letterSpacing: 1.1,
);
const whiteNameTextStyle = TextStyle(
  fontSize: 24.0,
  color: Colors.white,
  fontWeight: FontWeight.w600,
);
const whiteSubHeadingTextStyle = TextStyle(
  fontSize: 18.0,
  color: Colors.white,
  fontWeight: FontWeight.w400,
);
const titleStyle = TextStyle(
  fontSize: 22.0,
  color: primaryTextColor,
  fontWeight: FontWeight.w600,
);
const subTitleStyle = TextStyle(
  fontSize: 18.0,
  color: secondaryTextColor,
  fontWeight: FontWeight.w200,
);
const actionMenuStyle = TextStyle(
  fontSize: 16.0,
  color: primaryColor,
  fontWeight: FontWeight.w600,
  letterSpacing: 5,
);

const mainHeading = TextStyle(fontWeight: FontWeight.bold, fontSize: 30);

const subHeading = TextStyle(fontWeight: FontWeight.bold, fontSize: 20);

const basicHeading = TextStyle(fontSize: 15);

const slidingUpPanelWhiteStyle = TextStyle(
    color: Colors.white,
    fontSize: 17,
    fontWeight: FontWeight.bold,
    fontFamily: 'OpenSans');

///DASHBOARD PANEL SLIDER
Color dashPanelTopBarBgColor =
    const Color.fromARGB(255, 174, 183, 235).withValues(alpha: 0.4);
const Color dashPanelTabBarUnselectedTextColor = Colors.black;
const Color dashPanelTabBarSelectedTextColor = Colors.black;
Color dashPanelTabIndicatorColor =
    const Color.fromARGB(255, 174, 183, 235).withValues(alpha: 0.4);
const Color dashPanelMyVehiculesViewColor = Colors.white;
const Color dashPanelFavoritesViewColor = Colors.white;
const Color dashPanelWalletViewColor = Colors.orange;
const dashPanelTabLabelTextStyle = TextStyle(
    fontSize: 15.0, fontWeight: FontWeight.w900, fontFamily: 'OpenSans');
