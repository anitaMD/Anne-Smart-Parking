import 'package:flutter/material.dart';
//import 'package:google_fonts/google_fonts.dart';

//import 'griddashboard.dart';

class TestDash extends StatefulWidget {
  const TestDash({Key? key}) : super(key: key);

  @override
  TestDashState createState() => TestDashState();
}

class TestDashState extends State<TestDash> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff392850),
      body: Column(
        children: const <Widget>[
          SizedBox(
            height: 100,
          ),
          // GridDashboardE(),
        ],
      ),
    );
  }

  // GridDashboardE() {}
}
