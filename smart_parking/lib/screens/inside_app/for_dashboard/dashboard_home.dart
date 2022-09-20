// ignore_for_file: avoid_print, prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:smart_parking/screens/inside_app/for_dashboard/dashb_panel.dart';
import 'package:smart_parking/screens/inside_app/for_dashboard/reservation_countdown.dart';

class DashboardHomePage extends StatefulWidget {
  const DashboardHomePage({
    Key? key,
  }) : super(key: key);

  @override
  DashboardHomePageState createState() => DashboardHomePageState();
}

class DashboardHomePageState extends State<DashboardHomePage> {
  final panelScrollController = ScrollController();
  final dragHandlePanelController = PanelController();

  @override
  void initState() {
    FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    FocusNode().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double panelHeightClosed = MediaQuery.of(context).size.height * 0.1;
    double panelHeightOpened = MediaQuery.of(context).size.height * 0.55;

    return Scaffold(
        //backgroundColor: const Color(0xff392850),
        //backgroundColor: Colors.white,
        body: dashBSlidingUpPanel(panelHeightClosed, panelHeightOpened));
  }

  SlidingUpPanel dashBSlidingUpPanel(
      double panelHeightClosed, double panelHeightOpened) {
    return SlidingUpPanel(
      renderPanelSheet: true,
      margin: EdgeInsets.zero,
      panel: DashBoardPanel(
          panelScrollController: panelScrollController,
          dragHandlePanelController: dragHandlePanelController),
      minHeight: panelHeightClosed,
      maxHeight: panelHeightOpened,
      parallaxEnabled: true,
      parallaxOffset: .5,
      panelBuilder: (panelScrollController) => DashBoardPanel(
        panelScrollController: panelScrollController,
        dragHandlePanelController: dragHandlePanelController,
      ),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      /*   panelBuilder: (panelScrollController) => RefreshAndSlideUp(
                    notifyParent: refresh,
                    mappedMarkers: myMapMarkers,
                    panelScrollController: panelScrollController,
                    dragHandlePanelController: drangHandlePanelController,
                  ), */ //MAKE THE BLACK CONTAINER The draggable tiroir hand icon
      body: Column(
        children: const [
          ReservationCountdown(),
        ],
      ),
    );
  }
}


/* ////CHECK THESE COMMENTS...............................------------------------
  //LOOK ,!BAR, !Ignor, !notif, !exc!update, !Connectiv, !ViewR , !Toas, !DecorV, !LocalM, !Dialog, !IMM, !InputMe, !IInput, !InsetsC, !Surface, !W/Sys,

  /*  const Text(
                  'hello. THIS IS WHERE IT IS DISPLAYED A SEARCH BAR (maybe above a long height map) FOR nearby parkings (that) THE USERs CURRENT WALLET FUNDS, HIS VEHICLES (whenc clicked on "my vehicles", he can add, delete, edit vehicle info check this video link [https://www.youtube.com/watch?v=pBoyJpliZvQ] ), TIME LEFT BEFORE RESERVATION ENDS LIVE DECOMPTE'), */

/* 

// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_parking/screens/inside_app/testdash/griddashboard.dart';
import 'package:smart_parking/services/firestore_service.dart';

class DashboardHomePage extends StatefulWidget {
  final ScrollController scrollController;
  const DashboardHomePage({Key? key, required this.scrollController})
      : super(key: key);

  @override
  DashboardHomePageState createState() => DashboardHomePageState();
}

class DashboardHomePageState extends State<DashboardHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff392850),
      body: SingleChildScrollView(
        controller: widget.scrollController,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(
                height: 50,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(30, 2, 30, 2),
                child: Container(
                  color: Colors.white,
                  child: Row(
                    children: [
                      IconButton(
                        splashColor: Colors.grey,
                        icon: Icon(Icons.menu),
                        onPressed: () {},
                      ),
                      const Expanded(
                        child: TextField(
                          cursorColor: Colors.black,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.go,
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 15),
                              hintText: "Search parkings..."),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 50,
              ),
              const SizedBox(
                height: 140,
              ),
              const GridDashboard(),
            ],
          ),
        ),
      ),
    );
  }

  /*  const Text(
                  'hello. THIS IS WHERE IT IS DISPLAYED A SEARCH BAR (maybe above a long height map) FOR nearby parkings (that) THE USERs CURRENT WALLET FUNDS, HIS VEHICLES (whenc clicked on "my vehicles", he can add, delete, edit vehicle info check this video link [https://www.youtube.com/watch?v=pBoyJpliZvQ] ), TIME LEFT BEFORE RESERVATION ENDS LIVE DECOMPTE'), */

}
 */
*/
