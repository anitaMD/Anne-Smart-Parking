import 'package:flutter/material.dart';

class NotifsPage extends StatefulWidget {
  const NotifsPage({Key? key}) : super(key: key);

  @override
  NotifsPageState createState() => NotifsPageState();
}

class NotifsPageState extends State<NotifsPage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 400,
            width: 100,
          ),
          /*  SizedBox(
            width: 200,
            height: 200,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                  target: LatLng(14.7107395, -17.4784776), zoom: 12.0),
            ),
          ), */
        ],
      ),
    );
  }
}
