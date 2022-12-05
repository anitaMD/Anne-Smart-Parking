import 'package:flutter/material.dart';

class TestProfileInfo extends StatefulWidget {
  const TestProfileInfo({Key? key}) : super(key: key);

  @override
  State<TestProfileInfo> createState() => _TestProfileInfoState();
}

class _TestProfileInfoState extends State<TestProfileInfo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      height: 100,
      width: 100,
      color: Colors.green,
    ));
  }
}
