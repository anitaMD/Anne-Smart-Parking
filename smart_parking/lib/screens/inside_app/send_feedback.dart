// ignore_for_file: avoid_unnecessary_containers

import 'package:flutter/material.dart';

class SendFeedbackPage extends StatefulWidget {
  const SendFeedbackPage({Key? key}) : super(key: key);

  @override
  SendFeedbackPageState createState() => SendFeedbackPageState();
}

class SendFeedbackPageState extends State<SendFeedbackPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: const Center(
        child: Text("Send Feedback Page"),
      ),
    );
  }
}
