// ignore_for_file: avoid_print

import 'package:contained_tab_bar_view/contained_tab_bar_view.dart';
import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:smart_parking/screens/inside_app/for_dashboard/tab_view/my_vehicules.dart';

import 'package:smart_parking/styling/styling.dart';

class DashBoardPanel extends StatefulWidget {
  final ScrollController panelScrollController;
  final PanelController dragHandlePanelController;
  const DashBoardPanel(
      {Key? key,
      required this.panelScrollController,
      required this.dragHandlePanelController})
      : super(key: key);

  @override
  State<DashBoardPanel> createState() => _DashBoardPanelState();
}

class _DashBoardPanelState extends State<DashBoardPanel> {
  // final _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
          //DON'T CHANGE AGAIN
          color: dashPanelTopBarBgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18))),
      //
      child: ContainedTabBarView(
        tabBarProperties: TabBarProperties(
          unselectedLabelColor: dashPanelTabBarUnselectedTextColor,
          labelColor: dashPanelTabBarSelectedTextColor,
          indicator: ContainerTabIndicator(
            padding:
                const EdgeInsets.symmetric(vertical: 11.0, horizontal: 11.0),
            radius: const BorderRadius.all(Radius.circular(18)),
            color: dashPanelTabIndicatorColor,
          ),
        ),
        tabs: [
          panelTabBarDisplay("My Vehicules"),
          panelTabBarDisplay("Favorites"),
          //panelTabBarDisplay("My Wallet"),
        ],
        views: [
          myVehiculesView(),
          /* child: ListView(
              controller: widget.panelScrollController,
              children: [
                // CALL MY VEHICULES INSTEAD
                CarDetail(
                    title: "Testing",
                    price: 34,
                    color: "green",
                    gearbox: "gearbox",
                    fuel: "fuel",
                    brand: "BMW",
                    path: "assets/images/car3.jpg")
              ],
            ), */
          myFavsView(),
          //   myWalletView(),
        ],
        onChange: (index) => print(index),
      ),
    );
  }
}

Align panelTabBarDisplay(String tabLabel) {
  return Align(
    alignment: Alignment.center,
    child: Text(
      tabLabel,
      style: dashPanelTabLabelTextStyle,
    ),
  );
}

Container myVehiculesView() {
  return Container(
    color: dashPanelMyVehiculesViewColor,
    child: const MyVehiculesTab(),
  );
}

Container myFavsView() {
  return Container(
      //color: Colors.indigo,
      color: dashPanelFavoritesViewColor,
      child: ListView());
}

/* myWalletView() {
  return Container(color: dashPanelWalletViewColor);
} */

//
