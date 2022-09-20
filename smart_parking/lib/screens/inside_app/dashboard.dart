// ignore_for_file: avoid_print, prefer_const_literals_to_create_immutables
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:smart_parking/screens/inside_app/for_dashboard/booking.dart';
import 'package:smart_parking/screens/inside_app/for_dashboard/dashboard_home.dart';
import 'package:smart_parking/screens/inside_app/for_dashboard/history.dart';
import 'package:smart_parking/screens/inside_app/for_dashboard/notifs.dart';
import 'package:smart_parking/styling/faded_indexed_stacked.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

//CHECK THE FILE IN THE ONEDRIVE PROJECT FOLDER TO GET BACK THE ORIGINAL ONE FOR THIS FILE with the hidebottombar option
//filters for debug console !HTTPLog, !Ignoring, !token
class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  Color inactivebgColor = Colors.black.withAlpha(20);
  Color activebgColor = Colors.white;
  Color isIconSelected = Colors.red;
  Color isNotIconSelected = Colors.white;
  //
  bool isDropped = false;
  bool isToggleDragStarted = false;
  double dragEndOffsetX = 0.0, dragEndOffsetY = 0.0;
  Velocity initialVelocity =
      VelocityTracker.withKind(PointerDeviceKind.touch).getVelocity();

  double toggleContainerWidth = 55,
      toggleContainerHeight = 105,
      mapTopRightIconBoxHeightDeducted = 50;

  double previousPositionX = 0.0,
      previousPositionY = 0.0,
      appBarHeightFinal = 0.0,
      totalScreenHeightFinal = 0.0;

  Widget getBodyNoEffect() {
    List<Widget> pages = [
      const DashboardHomePage(),
      const BookingPage(),
      const HistoryPage(),
      const NotifsPage()
    ];
    return IndexedStack(
      index: _currentIndex,
      children: pages,
    );
  }

  Widget getBodyWFadedEffect() {
    List<Widget> pages = [
      const DashboardHomePage(),
      const BookingPage(),
      const HistoryPage(),
      const NotifsPage()
    ];
    return FadeIndexedStack(index: _currentIndex, children: pages);
  }

  List<bool> isSelected = [false, true];
  //

  Widget mapDashboardToggleSwitch() {
    return Material(
      color: Colors.white.withOpacity(0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
      ),
      child: Container(
        width: toggleContainerWidth,
        height: toggleContainerHeight,
        padding: const EdgeInsets.fromLTRB(3, 0, 3, 0),
        decoration: BoxDecoration(
          backgroundBlendMode: BlendMode.difference,
          color: const Color.fromARGB(255, 95, 91, 91).withOpacity(0.4),
          borderRadius: BorderRadius.circular(13),
          // border: Border.all(color: Colors.black.withAlpha(40)),
        ),
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              backgroundBlendMode: BlendMode.xor,
              color: inactivebgColor,
              borderRadius: BorderRadius.circular(13),
            ),
            child: ToggleButtons(
              splashColor: Colors.yellow,
              renderBorder: true,
              selectedBorderColor:
                  const Color.fromARGB(255, 95, 91, 91).withOpacity(0),
              borderColor: const Color.fromARGB(255, 95, 91, 91).withOpacity(0),
              selectedColor: isIconSelected,
              color: Colors.white,
              fillColor: activebgColor,
              borderRadius: BorderRadius.circular(13),
              direction: Axis.vertical,
              isSelected: isSelected,
              onPressed: (int selectedIndex) {
                setState(() {
                  for (int index = 0; index < isSelected.length; index++) {
                    if (index == selectedIndex) {
                      isSelected[index] = true;

                      index == 0 //had to do this to get the right page
                          ? _currentIndex = index + 1
                          : _currentIndex = index - 1;
                    } else {
                      isSelected[index] = false;
                    }
                  }
                });
              },
              children: const [
                Icon(
                  Icons.location_on_outlined,
                  size: 27,
                ),
                Icon(Icons.dashboard_outlined, size: 27),
              ],
            ),
          ),
        ),
      ),
    );
  }

  dragMapDashToggleSwitch() {
    //CHECK THIS LINK FOR THE NEW OFFSET POSITION TO KEEP THE OBJECT THERE AFTER DRAG https://flutteragency.com/draggable-widget/
    return Draggable(
      axis: Axis.vertical,
      data: mapDashboardToggleSwitch(),
      feedback: mapDashboardToggleSwitch(),
      childWhenDragging: Container(),
      onDraggableCanceled: (velocity, offset) {
        setState(() {
          isToggleDragStarted = false;
        });
      },
      onDragStarted: () {
        setState(() {
          isToggleDragStarted = true;
        });
      },
      onDragEnd: (details) {
        setState(() {
          isToggleDragStarted = false;
          /*CAN KEEP THESE TWO IF I WANT THE TOGGLE OBJECT TO BE SENT BACK TO ITS PREVIOUS POSITION  
         previousPositionX = dragEndOffsetX;
          previousPositionY = dragEndOffsetY; */
          dragEndOffsetX = details.offset.dx;
          dragEndOffsetY = details.offset.dy;
          if (dragEndOffsetY <
              appBarHeightFinal + mapTopRightIconBoxHeightDeducted) {
            print("YOU WENT TOO FAR UP!");
            dragEndOffsetY = appBarHeightFinal +
                15 +
                mapTopRightIconBoxHeightDeducted; //15 to not touch the appbar and see it clearly
          }
          if (dragEndOffsetY >
              totalScreenHeightFinal -
                  appBarHeightFinal -
                  toggleContainerHeight) {
            print("YOU WENT TOO FAR DOWN!");
            dragEndOffsetY = totalScreenHeightFinal -
                appBarHeightFinal -
                toggleContainerHeight;
          }
        });
      },
      child: mapDashboardToggleSwitch(),
    );
  }

  @override
  Widget build(BuildContext context) {
    double? fetchedAppBarHeight = Scaffold.of(context).appBarMaxHeight;
    appBarHeightFinal = fetchedAppBarHeight!;
    //
    double totalScreenHeightFetched = MediaQuery.of(context).size.height;
    totalScreenHeightFinal = totalScreenHeightFetched;
    //
    double dragTargetContainerHeight = totalScreenHeightFinal -
        totalScreenHeightFinal * 0.25 -
        mapTopRightIconBoxHeightDeducted;

    print(
        "CURRENT OFFSETS :  dragEndOffsetX $dragEndOffsetX ____  dragEndOffsetY $dragEndOffsetY ____  previousOffset $previousPositionX ________TESTING ${totalScreenHeightFinal - appBarHeightFinal - toggleContainerHeight}");
    print(
        "MediaQuery.of(context).size.height ${MediaQuery.of(context).size.height}");
    print(
        "APPBAR.height $fetchedAppBarHeight ___________ test : $appBarHeightFinal");
    return Scaffold(
      body: Stack(
          //
          alignment: const Alignment(1.00, 0.70),
          children: [
            getBodyWFadedEffect(),
            //Positioned(left: 30, child: mapDashboardToggleSwitch()),
            isDropped == true ? Container() : dragMapDashToggleSwitch(),
            Positioned(
              top:
                  mapTopRightIconBoxHeightDeducted, //to not hide the map location icon en haut à droite
              child: DragTarget(
                builder: ((context, data, rejectedData) {
                  return DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    color: isToggleDragStarted
                        ? Colors.blueGrey
                        : Colors.white.withOpacity(0),
                    strokeWidth: 2,
                    dashPattern: [6],
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      child: Container(
                        height: isDropped == true
                            ? dragTargetContainerHeight
                            : dragTargetContainerHeight -
                                toggleContainerHeight +
                                10,
                        /* dragTargetContainerHeight +
                            toggleContainerHeight -
                             -
                            2, // */ //deduct stroke width
                        width: toggleContainerWidth - 2,
                        color: isDropped ? null : null,
                        child: Stack(
                          children: [
                            Positioned(
                              top: dragEndOffsetY -
                                  toggleContainerHeight -
                                  toggleContainerHeight / 2,
                              child: isDropped == true
                                  ? dragMapDashToggleSwitch()
                                  : Container(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                onWillAccept: (data) => true,
                onAccept: (data) {
                  /* ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dropped successfully'),
                    ),
                  ); */
                  setState(() {
                    isDropped = true;
                  });
                },
              ),
            ),
            /*  /* WOULD WORK IF I DIDNT WANT TO MAKE IT ALIGN TO THE VERTICAL CONTAINER ON THE LEFT SO KEEP THIS */
            isDropped == true 
                ? Positioned(
                    left: dragEndOffsetX,
                    top: dragEndOffsetY - toggleContainerHeight,
                    child: dragMapDashToggleSwitch(),
                  )
                : Container(), */
          ]),
    );
  }
}
