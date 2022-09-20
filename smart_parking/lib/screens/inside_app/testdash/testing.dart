/* // ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:smart_parking/screens/inside_app/for_booking/for_sliding_up_panel.dart/stepper_booking_process.dart';

class WeAreTesting extends StatefulWidget {
  final PanelController controller;
  const WeAreTesting({Key? key, required this.controller}) : super(key: key);

  @override
  State<WeAreTesting> createState() => _WeAreTestingState();
}

class _WeAreTestingState extends State<WeAreTesting> {
  final singleChildScrollController = ScrollController();
  bool isScrollingFromBottomToTop = false;
  bool isOnTop = true;

  @override
  void initState() {
    stopScrollling();
    super.initState();
  }

  stopScrollling() async {
    singleChildScrollController.addListener(() {
      if (singleChildScrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (!isScrollingFromBottomToTop) {
          print('SCROLLING DOWN FROM TOP TO BOTTOM   ==>   ');
          isScrollingFromBottomToTop = true;
          isOnTop = false;
          print(
              'isScrollingFromBottomToTop = true, $isScrollingFromBottomToTop and   isOnTop = false; $isOnTop  ');
          //widget.dragHandlePanelController.show;
        }
      }
      if (singleChildScrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (isScrollingFromBottomToTop) {
          print('SCROLLING UP FROM BOTTOM TO TOP   ==>   ');

          isScrollingFromBottomToTop = false;
          isOnTop = true;
          print(
              'isScrollingFromBottomToTop = false, $isScrollingFromBottomToTop and   isOnTop = true; $isOnTop  ');

          //widget.dragHandlePanelController.animatePanelToPosition(1.0);

          //showBottomBar();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Expanded(
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 13.0),
            buildDragHandle(),
            const SizedBox(height: 18.0),
            const Center(
              child: Text(
                'BOOKINGS', //'CHOOSE YOUR SMART PARKING'
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontFamily: 'OpenSans'),
              ),
            ),
            const SizedBox(height: 16.0),
            NotificationListener(
              onNotification: (notification) {
                if (notification is UserScrollNotification) {
                  if (notification.direction == ScrollDirection.idle) {
                    print("IDLE PAGE SCROLLING");
                    print("PANEL POSITION ${widget.controller.panelPosition}");
                  }
                  if (notification.direction == ScrollDirection.reverse) {
                    print("REVERSE PAGE SCROLLING");
                    print("PANEL POSITION ${widget.controller.panelPosition}");
                    //singleChildScrollController.jumpTo(1.0);
                    print(
                        "OFFSET ON BEGINNING: ${singleChildScrollController.offset.toDouble()}");
                    print(
                        "PANELSCROLL POSITION ${singleChildScrollController.position}");
                    widget.controller.open();
                  }
                  if (notification.direction == ScrollDirection.forward) {
                    print("FORWARD PAGE SCROLLING");
                    print("PANEL POSITION ${widget.controller.panelPosition}");

                    singleChildScrollController.jumpTo(1.0);
                    print(
                        "PANELSCROLL POSITION ${singleChildScrollController.position}");
                    if (widget.controller.panelPosition < 1.0) {
                      widget.controller.open();
                    }

                    if (widget.controller.panelPosition ==
                        1.0 /* singleChildScrollController.offset.toDouble() == 1.0 */) {
                      print(
                          "OFFSET ON TOP: ${singleChildScrollController.offset.toDouble()}");
                      //widget.controller.close();
                    }
                    //  widget.controller.close();
                  }
                }
                return false;
              },
              child: SingleChildScrollView(
                controller: singleChildScrollController,
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.3,
                  child: const MapsBookingProcess(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  buildDragHandle() => GestureDetector(
        child: Center(
            child: Container(
          width: 30,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12.0),
          ),
        )),
        onTap: togglePanel,
      );

  buildImages() {}

  void togglePanel() {
    widget.controller.isPanelOpen
        ? widget.controller.close()
        : widget.controller.open();
  }
}
 */