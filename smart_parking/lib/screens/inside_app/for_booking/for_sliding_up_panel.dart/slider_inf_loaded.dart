import 'package:flutter/material.dart';

class Testons extends StatelessWidget {
  final ScrollController controller;
  const Testons({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      //MUST RETURN THE SLIDING UP HANDLE
      padding: EdgeInsets.zero,
      children: [
        Container(
          width: 20,
          height: 20,
          color: Colors.black,
        ),
      ],
    );
  }
}
