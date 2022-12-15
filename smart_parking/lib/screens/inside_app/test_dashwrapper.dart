import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:smart_parking/screens/inside_app/for_dashboard/booking.dart';
import 'package:smart_parking/screens/inside_app/for_testDash/test_dashhome.dart';
import 'package:smart_parking/screens/inside_app/testhome.dart';
import 'package:smart_parking/styling/faded_indexed_stacked.dart';

import 'for_dashboard/history.dart';
import 'for_dashboard/notifs.dart';

class TestDashboardWrapper extends StatefulWidget {
  final Map<String, dynamic> parkingToNavigateTo;
  final int newIndex;
  final int timeUntilResStartsFromBookingOverview;
  final Map<String, dynamic> newMoreUrgentBooking;
  const TestDashboardWrapper(
      {Key? key,
      required this.parkingToNavigateTo,
      this.newIndex = 0,
      this.timeUntilResStartsFromBookingOverview = 0,
      required this.newMoreUrgentBooking})
      : super(key: key);

  @override
  State<TestDashboardWrapper> createState() => _TestDashboardWrapperState();
}

class _TestDashboardWrapperState extends State<TestDashboardWrapper> {
  int _currentIndex = 0;
  bool goBack = false;
  Color inactivebgColor = Colors.black.withAlpha(20);
  Color activebgColor = Colors.white;
  Color isIconSelected = Colors.red;
  Color isNotIconSelected = Colors.white;
  //
  bool isDropped = false;
  bool isToggleDragStarted = false;
  double dragEndOffsetX = 0.0, dragEndOffsetY = 0.0;
  Velocity initialVelocity = VelocityTracker.withKind(PointerDeviceKind.touch).getVelocity();

  double toggleContainerWidth = 55, toggleContainerHeight = 105, mapTopRightIconBoxHeightDeducted = 50;

  double previousPositionX = 0.0, previousPositionY = 0.0, appBarHeightFinal = 0.0, totalScreenHeightFinal = 0.0;

  Widget getBodyNoEffect() {
    List<Widget> pages = [
      TestDashboardHomePage(
        newMoreUrgentBooking: widget.newMoreUrgentBooking,
        canShowToggle: canShowToggle,
        /*  
          getIndex: (int selectedIndex) {},
           */
      ),
      BookingPage(
        parkingToNavigateTo: widget.parkingToNavigateTo,
      ),
      const HistoryPage(),
      const NotifsPage()
    ];
    return IndexedStack(
      index: _currentIndex,
      children: pages,
    );
  }

  Widget getBodyWFadedEffect() {
    widget.newIndex == 1 && goBack == false
        ? {
            _currentIndex = 0,
            getIndex(0),
            goBack = true,
          }
        : null;
    //_currentIndex = widget.newIndex + 1;
    debugPrint(" currentindex $_currentIndex  __ widgetnewindex ${widget.newIndex} _ goB $goBack");
    List<Widget> pages = [
      TestDashboardHomePage(
        timeUntilResStartsFromBookingOverview: widget.timeUntilResStartsFromBookingOverview,
        newMoreUrgentBooking: widget.newMoreUrgentBooking,
        canShowToggle: canShowToggle,
        /* 
          getIndex: getIndex,
          timeUntilResStartsFromBookingOverview: widget.timeUntilResStartsFromBookingOverview */
      ),
      BookingPage(
        parkingToNavigateTo: widget.parkingToNavigateTo,
      ),
      const HistoryPage(),
      const NotifsPage()
    ];
    return FadeIndexedStack(index: _currentIndex, children: pages);
  }

  canShowToggle(bool canShow) {
    if (mounted) showToggle = canShow;

    //do not remove this as it made the flickering STOP
  }

  List<bool> isSelected = [false, true];
  bool showToggle = false;
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
              selectedBorderColor: const Color.fromARGB(255, 95, 91, 91).withOpacity(0),
              borderColor: const Color.fromARGB(255, 95, 91, 91).withOpacity(0),
              selectedColor: isIconSelected,
              color: Colors.white,
              fillColor: activebgColor,
              borderRadius: BorderRadius.circular(13),
              direction: Axis.vertical,
              isSelected: isSelected,
              onPressed: (int selectedIndex) {
                goBack == true && widget.newIndex == 1
                    ? {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const TestHome(
                                      newMoreUrgentBooking: {},
                                      /*   fromLoginView: true,
                                      parkingToNavigateTo: {},
                                      newIndex: 0,
                                      timeUntilResStarts: 0, */
                                    ))),
                      }
                    : getIndex(selectedIndex);
                /*   setState(() {
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
              */
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
          if (dragEndOffsetY < appBarHeightFinal + mapTopRightIconBoxHeightDeducted) {
            debugPrint("YOU WENT TOO FAR UP!");
            dragEndOffsetY = appBarHeightFinal +
                15 +
                mapTopRightIconBoxHeightDeducted; //15 to not touch the appbar and see it clearly
          }
          if (dragEndOffsetY > totalScreenHeightFinal - appBarHeightFinal - toggleContainerHeight) {
            debugPrint("YOU WENT TOO FAR DOWN!");
            dragEndOffsetY = totalScreenHeightFinal - appBarHeightFinal - toggleContainerHeight;
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
    double dragTargetContainerHeight =
        totalScreenHeightFinal - totalScreenHeightFinal * 0.25 - mapTopRightIconBoxHeightDeducted;

    debugPrint(
        "CURRENT OFFSETS :  dragEndOffsetX $dragEndOffsetX ____  dragEndOffsetY $dragEndOffsetY ____  previousOffset $previousPositionX ________TESTING ${totalScreenHeightFinal - appBarHeightFinal - toggleContainerHeight}");
    debugPrint("MediaQuery.of(context).size.height ${MediaQuery.of(context).size.height}");
    debugPrint("APPBAR.height $fetchedAppBarHeight ___________ test : $appBarHeightFinal");
    debugPrint("CAN SHOW TOGGLE: $showToggle ____ isDropped $isDropped");
    return Scaffold(
      body: GestureDetector(
        onTapUp: (details) {
          setState(() {
            showToggle = true;
          });
          /*   LocalPushNotificationsService.sendNotification(); */
        },
        onVerticalDragStart: (details) {
          setState(() {
            showToggle = true;
          });
        },
        child: Stack(
            //
            alignment: const Alignment(1.00, 0.70),
            children: [
              getBodyWFadedEffect(),
              //Positioned(left: 30, child: mapDashboardToggleSwitch()),
              /* showToggle == false ||  */ isDropped == true ? Container() : dragMapDashToggleSwitch(),
              Positioned(
                top: mapTopRightIconBoxHeightDeducted, //to not hide the map location icon en haut à droite
                child: DragTarget(
                  builder: ((context, data, rejectedData) {
                    return DottedBorder(
                      borderType: BorderType.RRect,
                      radius: const Radius.circular(12),
                      color: isToggleDragStarted ? Colors.blueGrey : Colors.white.withOpacity(0),
                      strokeWidth: 2,
                      dashPattern: const [6],
                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(12)),
                        child: Container(
                          height: isDropped == true
                              ? dragTargetContainerHeight
                              : dragTargetContainerHeight - toggleContainerHeight + 10,
                          /* dragTargetContainerHeight +
                              toggleContainerHeight -
                               -
                              2, // */ //deduct stroke width
                          width: toggleContainerWidth - 2,
                          color: isDropped ? null : null,
                          child: Stack(
                            children: [
                              Positioned(
                                top: dragEndOffsetY - toggleContainerHeight - toggleContainerHeight / 2,
                                child: isDropped == true ? dragMapDashToggleSwitch() : Container(),
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
      ),
    );
  }

  void getIndex(int selectedIndex) {
    debugPrint('ISLENGTHSELECETD __ $selectedIndex _ goBack $goBack');

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
  }
}
