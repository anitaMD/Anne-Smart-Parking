import 'package:flutter/material.dart';
import 'package:smart_parking/styling/styling.dart';

class ReservationCountdown extends StatefulWidget {
  const ReservationCountdown({Key? key}) : super(key: key);

  @override
  State<ReservationCountdown> createState() => _ReservationCountdownState();
}

class _ReservationCountdownState extends State<ReservationCountdown> {
  var appBarHeight = 95.61904761904762;
  int time = 29;

  @override
  Widget build(BuildContext context) {
    double panelBodyHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).size.height * 0.1 -
        appBarHeight;

    return Container(
      margin: const EdgeInsets.all(8),
      height: panelBodyHeight,
      width: panelBodyHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffb0bec5), width: 40),
        shape: BoxShape.circle,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xffcfd8dc), width: 40),
          shape: BoxShape.circle,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xffeceff1), width: 40),
            shape: BoxShape.circle,
          ),
          child: ListView.builder(
              shrinkWrap: false,
              itemCount: 4,
              itemBuilder: (context, index) {
                final item = Text('$index');
                return item;
              }),
        ),
      ),
    );
  }

  /* Container(
        height: panelBodyHeight,
        color: Colors.red.withAlpha(90),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(child: buildTimeCountainer(time)),
          ],
        )); */
}

buildTimeCountainer(int time) {
  return Text(
    '$time ',
    style: dashPanelTabLabelTextStyle,
  );
}
