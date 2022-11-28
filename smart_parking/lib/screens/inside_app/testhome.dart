import 'package:flutter/material.dart';

class TestHome extends StatefulWidget {
  const TestHome({Key? key}) : super(key: key);

  @override
  State<TestHome> createState() => _TestHomeState();
}

class _TestHomeState extends State<TestHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      height: 100,
      width: 100,
      color: Colors.red,
    ));
  }
}
