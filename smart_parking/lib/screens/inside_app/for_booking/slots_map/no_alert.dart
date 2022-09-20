// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:smart_parking/screens/inside_app/for_booking/slots_map/select_vehicule.dart';
import 'package:smart_parking/services/firebase/firebase_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_parking/notifiers/state_management.dart';
import 'package:im_stepper/stepper.dart';
import 'package:time_range_picker/time_range_picker.dart';

class BookingThroughSlotsMapNoAlertDialog extends StatefulWidget {
  final String receivedID;
  final Map<String, dynamic> mappedParkingsGeneralInfo;
  final bool slotBooked;
  const BookingThroughSlotsMapNoAlertDialog(
      {Key? key,
      required this.receivedID,
      required this.mappedParkingsGeneralInfo,
      required this.slotBooked})
      : super(key: key);

  @override
  State<BookingThroughSlotsMapNoAlertDialog> createState() =>
      _BookingThroughSlotsMapNoAlertDialogState();
}

class _BookingThroughSlotsMapNoAlertDialogState
    extends State<BookingThroughSlotsMapNoAlertDialog> {
  //AUTHENTICATION
  var firebaseService = FirebaseService();
  User? currentlySignedInUser;

  //
  int parkingSlotsTotal = 10;
  double alleyHeight = 200,
      singleSpotHeight = 50,
      singleSpotWidth = 120,
      spaceBetweenSlots = 35.0,
      alleySpotWidthRatio = 1 / 4;
  bool isSelected = false;
  Color slotHighlithgColor = Colors.green;
  Color finalSelectedColorSlot = Colors.transparent;

  //LISTS AND MAPS
  final alleyA = <String>{}, alleyB = <String>{};
  var mappedAlleyASelectedCheck = {}, mappedAlleyBSelectedCheck = {};
  Map<String, dynamic> insideParkingInfoFetched = {};
  List<Map<String, dynamic>> mappedSelectedSlotAlley = [];
  Map<String, dynamic> linkedParkingNameAndInsideInfo = {};
  Map<String, Set> mappedAlleysAndSlotIds = {};

//RESERVATION VARS
  bool isReservationDayPicked = false,
      isReservationStartTimePicked = false,
      isReservationDurationPicked = false,
      firstTimeAskingForDateSelect = true;

//BOOKER
  Set<TimeOfDay> fetchedTimes = {};
  CalendarFormat format = CalendarFormat.week;
  Duration interval = const Duration(minutes: 30);
  DateTime selectedDay = DateTime.now(), focusedDay = DateTime.now();
  Color selectedTimeSlotColor = Colors.orange;
  ScrollController singleChildController = ScrollController(),
      gridController = ScrollController(),
      infoListViewController = ScrollController();
  int activeStep = 0, upperBound = 2;

  @override
  void dispose() {
    infoListViewController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    //getAlleySlotsId(parkingSlotsTotal);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    currentlySignedInUser = firebaseService.auth.currentUser;
    print(
        "SIGNED IN CURRENTLY ${firebaseService.auth.currentUser?.uid.toString()}");
    double alleyListViewMinHeightToDisplay = alleyHeight +
        (spaceBetweenSlots * parkingSlotsTotal ~/ (parkingSlotsTotal ~/ 2));
    //TIMESLOTSELECTION
    TimeOfDay startTime = TimeOfDay(
            hour: int.parse(
                context.watch<StateManagement>().openingHour.split(":")[0]),
            minute: int.parse(
                context.watch<StateManagement>().openingHour.split(":")[1])),
        endTime = TimeOfDay(
            hour: int.parse(
                context.watch<StateManagement>().closingHour.split(":")[0]),
            minute: int.parse(
                context.watch<StateManagement>().closingHour.split(":")[1]));
    //

    context
        .watch<StateManagement>()
        .getTimeSlotsIntervals(startTime, endTime, interval)
        .toList()
        .then((value) {
      for (var timeOfDay in value) {
        context.read<StateManagement>().updateTimeSlotList(timeOfDay, value);
      }
    });
/* print(
    "OUTSIDE FETCHED ${context.read<StateManagement>().timeSlotsParsed.length}"); */
    fetchedTimes = context.read<StateManagement>().timeSlotsParsed;
    print("TESTING THIS $fetchedTimes");
    return Scaffold(
      //backgroundColor: Colors.white60,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        toolbarHeight: 70,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(40),
          ),
        ),
        /* flexibleSpace: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment(0.0, -1.0),
                    end: Alignment(0.0, 0.6),
                    colors: <Color>[
                  Colors.white,
                  Colors.blueGrey,
                ])), */

        actions: [
          Flexible(
              child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  previousButton(),
                  bookingStepper(),
                  nextButton(),
                ],
              )
            ],
          )),
        ],
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          controller: singleChildController,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection(
                      "locations/${widget.receivedID}/insideParkingInfo")
                  .snapshots()
              /* .map((snapshot) => snapshot.docs
                      .map((doc) => InsideInfo.fromFirestore(
                          doc.data() as Map<String, dynamic>))
                      .toList())*/
              ,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Text('');
                } else {
                  String source = snapshot.data!.metadata.hasPendingWrites
                      ? "Local"
                      : "Server";
                  // insideParkingInfoFetched.clear();
                  insideParkingInfoFetched = snapshot.data!.docs[0].data();
                  for (var element
                      in widget.mappedParkingsGeneralInfo.entries) {
                    if (element.key == widget.receivedID) {
                      String currentlySelectedParkingsName = element.value
                          .toString()
                          .split(',')
                          .toList()
                          .elementAt(element.value
                              .toString()
                              .split(',')
                              .toList()
                              .indexWhere(
                                  (element) => element.contains("Parking")))
                          .split(':')
                          .toList()
                          .last
                          .split('}')
                          .first;

                      linkedParkingNameAndInsideInfo.addAll({
                        'Parking Name': currentlySelectedParkingsName,
                        'Info': insideParkingInfoFetched
                      });
                      snapshot.data!.docs[0]
                          .data()
                          .update('Occupied Slots', (value) => 2);
                    }
                  }
                  parkingSlotsTotal =
                      insideParkingInfoFetched["Total Slots Number"];
                  getAlleySlotsId(parkingSlotsTotal);
                  //insideParkingInfoFetched.update("Occupied Slots", (value) => 5);
                  //getInsideParkingSlotsInfo(insideParkingInfoFetched); STOPPED HERE

                  print(
                      "DATA SNAPSHOT: $linkedParkingNameAndInsideInfo)))) SOURCE: $source _____ ${insideParkingInfoFetched["Available Slots"]}");

                  return Column(
                    children: [
                      bookerBody(
                          alleyListViewMinHeightToDisplay, startTime, endTime),
                    ],
                  );
                }
              }),
        ),
      ),
    );

    //WILLL NEED 3 COLUMNS with an expanded or flex for the 3 vertical columns and in each of the two extreme columns, INKWELL AND A CONATINER CHILD FOR EACH SLOT with the icons and colors. So find a wwway to create a function that allows me to show those and not repeat code much
  }

  Color getSelectedTimeSlotColor(int index) {
    return fetchedTimes.isEmpty
        ? Colors.white
        : context.watch<StateManagement>().selectedTime ==
                fetchedTimes.elementAt(index)
            ? selectedTimeSlotColor
            : Colors.white;
  }

  fetchAlleySelectedSlotId(int i, String alley) {
    for (var singleAlleyInfo in mappedSelectedSlotAlley) {
      singleAlleyInfo.update('isSlotSelected', (value) => 'false');
      // DO NOT MOVE OR REMOVE THE UPPER LINE CMD. It has to put everything to false before putting only the selected slot to true
      singleAlleyInfo.update('highlightColor', (value) => Colors.transparent);
      refreshSlotColorState(Colors.transparent);
      if (singleAlleyInfo.keys.first.contains('B') && alley.contains('B')) {
        mappedSelectedSlotAlley.elementAt(i + parkingSlotsTotal ~/ 2) ==
                singleAlleyInfo //parkingSlotsTotal ~/ 2 = 3 needed to get to the B section because the received i in parameters is limited to half the total number of slots
            ? {
                mappedSelectedSlotAlley
                    .elementAt(i + parkingSlotsTotal ~/ 2)
                    .update('isSlotSelected', (value) => 'true'),
                mappedSelectedSlotAlley
                    .elementAt(i + parkingSlotsTotal ~/ 2)
                    .update('highlightColor', (value) => slotHighlithgColor),
              }
            : {
                singleAlleyInfo.update('isSlotSelected', (value) => 'false'),
                singleAlleyInfo.update(
                    'highlightColor', (value) => Colors.transparent)
              };
      } else if (singleAlleyInfo.keys.first.contains('A') &&
          alley.contains('A')) {
        mappedSelectedSlotAlley.elementAt(i) == singleAlleyInfo
            ? {
                mappedSelectedSlotAlley
                    .elementAt(i)
                    .update('isSlotSelected', (value) => 'true'),
                mappedSelectedSlotAlley
                    .elementAt(i)
                    .update('highlightColor', (value) => slotHighlithgColor),
                refreshSlotColorState(
                    mappedSelectedSlotAlley.elementAt(i).values.last),
              }
            : {
                singleAlleyInfo.update('isSlotSelected', (value) => 'false'),
                singleAlleyInfo.update(
                    'highlightColor', (value) => Colors.transparent)
              };
      }
    }

    print(
        "REALLY? ${mappedSelectedSlotAlley.elementAt(i)} ___ $mappedSelectedSlotAlley");
  }

  buildLeftAlleySlots(
      int parkingSlotsTotal, double spaceBetweenSlots, bool isSelected) {
    int leftAlleySlotsTotal = parkingSlotsTotal ~/ 2;
    return List.generate(
        leftAlleySlotsTotal,
        (i) => Material(
              color: const Color.fromARGB(255, 63, 97, 95).withAlpha(80),
              child: InkWell(
                highlightColor: Colors.pink,
                onTap: () {
                  isSelected = true;
                  print("Click event on Container _");
                  fetchAlleySelectedSlotId(i, "alleyA");
                  //highlightSelectedSlot(isSelected, i);
                },
                splashColor: Colors.yellow,
                child: Container(
                  height: singleSpotHeight, //REVIENS
                  width: singleSpotWidth,
                  decoration: BoxDecoration(
                    color: mappedSelectedSlotAlley.elementAt(i).values.last,
                    border: Border(
                      top: BorderSide(
                          color: Colors.indigo.withAlpha(30), width: 2),
                      bottom: BorderSide(
                          color: Colors.indigo.withAlpha(30), width: 2),
                    ),
                    /*  gradient: LinearGradient(
                      /* begin: Alignment(0.0, -1.0),
                                  end: Alignment(0.0, 0.6), */
                      colors: <Color>[
                        Colors.indigo.withAlpha(70),
                        const Color(0x00ef5f50),
                      ],
                    ), */
                  ),
                  child: CustomPaint(
                    foregroundPainter: DashedSeparatedBordersPainterLTRB(
                        false, true, false, true),
                    child: Center(
                        child: mappedSelectedSlotAlley.elementAt(i).values.contains(
                                'true') //crcks if 'isSlotSelected is true or not
                            ? const Text('Selected')
                            : Text('A$i')),
                  ),
                ),
              ),
            )).toList(); // replace * with your rupee or use Icon instead
  }

  buildRightAlleySlots(
      int parkingSlotsTotal, double spaceBetweenSlots, bool isSelected) {
    int rightAlleySlotsTotal = parkingSlotsTotal ~/ 2;
    return List.generate(
        rightAlleySlotsTotal,
        (i) => Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  print("Click event on Container");
                  fetchAlleySelectedSlotId(i, "alleyB");
                },
                splashColor: Colors.yellow,
                focusColor: Colors.green,
                child: Container(
                  height: singleSpotHeight,
                  width: singleSpotWidth,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          color: Colors.indigo.withAlpha(30), width: 2),
                      bottom: BorderSide(
                          color: Colors.indigo.withAlpha(30), width: 2),
                    ),
                    gradient: LinearGradient(
                      /* begin: Alignment(0.0, -1.0),
                                  end: Alignment(0.0, 0.6), */
                      colors: <Color>[
                        Colors.indigo.withAlpha(70),
                        const Color(0x00ef5f50),
                      ],
                    ),
                  ),
                  child: CustomPaint(
                    //child: Container(color: Colors.yellow,),
                    foregroundPainter: DashedSeparatedBordersPainterLTRB(
                        false, true, false, true),
                    child: Center(child: Text('B$i')),
                  ),
                ),
              ),
            )).toList(); // replace * with your rupee or use Icon instead
  }

  /* donotdelete */ Color checkMate(int i) {
    //DO LIKE I DID WITH MY BOOKER CARD BSELECT COLOR AND REMOVE COLOR ATTRIBUTE IN ALLEYS MAP
    Color myColor = Colors.yellow;
    for (var singleAlleyInfo in mappedSelectedSlotAlley) {
      myColor = Colors.transparent;
      if (mappedSelectedSlotAlley.elementAt(i).values.last ==
          singleAlleyInfo.values.last) {
        myColor = Colors.transparent;
      }
    }
    return myColor;
  }

  refreshSlotColorState(selectedSlotColorFetched) {
    setState(() {
      finalSelectedColorSlot = selectedSlotColorFetched;
    });
  }

  getAlleySlotsId(parkingSlotsTotal) {
    int alleyBindexStart = parkingSlotsTotal ~/ 2;

    var j = 0;
    for (var i = 0; i < parkingSlotsTotal; i++) {
      (i < parkingSlotsTotal ~/ 2)
          ? {
              alleyA.add("A$i"),
              mappedSelectedSlotAlley.add({
                "alleyA_Id": alleyA.elementAt(i) /* "A$i" */,
                "isSlotSelected": false,
                "highlightColor": Colors.transparent
              })
            }
          : {
              alleyB.add("B${j++}"),
              mappedSelectedSlotAlley.add({
                "alleyB_Id": alleyB.elementAt(i -
                    alleyBindexStart), //3 because at this point, i = 3 and I need the counter to reset
                "isSlotSelected": false,
                "highlightColor": Colors.transparent
              })
            };
    }
    print("ALLEY A : $alleyA ______________ ALLEY B : $alleyB");
    print("mappedAlleysAndSlotIdsSelected : $mappedSelectedSlotAlley ");
    //print("mappedAlleysAndSlotIdsSelected : $mappedAlleyASelectedCheck ");

    mappedAlleysAndSlotIds.addAll({
      'Alley A': alleyA,
      'Alley B': alleyB,
    });

    print("mappedAlleysAndSlotIds : $mappedAlleysAndSlotIds");
  }

  insideParkingLayout(double alleyListViewMinHeightToDisplay) {
    return Container(
      margin: const EdgeInsets.only(left: 10, right: 10),
      color: Colors.transparent,
      width: double.infinity,
      //padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                /* LEFT ALLEY */
                decoration: BoxDecoration(
                    color: Colors.indigo.withAlpha(10),
                    border: Border(
                      left: BorderSide(
                          color: Colors.indigo.withAlpha(30), width: 2),
                      right: BorderSide(
                          color: Colors.indigo.withAlpha(30), width: 2),
                    )),
                width: MediaQuery.of(context).size.width * alleySpotWidthRatio,
                height:
                    alleyListViewMinHeightToDisplay, //otherwise, the slot will appear cutted so I need to show at least half of half the alley number of slots for UI concerns
                child: ListView.separated(
                  shrinkWrap: false,
                  itemCount: parkingSlotsTotal ~/ 2,
                  itemBuilder: (context, index) {
                    final item = buildLeftAlleySlots(parkingSlotsTotal,
                        spaceBetweenSlots, isSelected)[index];
                    return item;
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return SizedBox(height: spaceBetweenSlots);
                  },
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.indigo.withAlpha(20),
                  height: alleyListViewMinHeightToDisplay,
                  child: Stack(
                    alignment: Alignment.center,
                    children: const [
                      Positioned(
                        top: 0,
                        child: Icon(Icons.arrow_circle_down),
                      ),
                      Positioned(
                        bottom: 0,
                        child: Icon(Icons.arrow_circle_down),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                    color: Colors.indigo.withAlpha(10),
                    border: Border(
                      left: BorderSide(
                          color: Colors.indigo.withAlpha(30), width: 2),
                      right: BorderSide(
                          color: Colors.indigo.withAlpha(30), width: 2),
                    )),
                width: MediaQuery.of(context).size.width * alleySpotWidthRatio,
                height: alleyListViewMinHeightToDisplay,
                child: ListView.separated(
                  shrinkWrap: false,
                  itemCount: parkingSlotsTotal ~/ 2,
                  itemBuilder: (context, index) {
                    final item = buildRightAlleySlots(parkingSlotsTotal,
                        spaceBetweenSlots, isSelected)[index];
                    return item;
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return SizedBox(height: spaceBetweenSlots);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void showUserRangePicker(int index, TimeOfDay parkingClosingHour,
      TimeOfDay parkingOpeningHour) async {
    TimeRange result = await showTimeRangePicker(
        context: context,
        start: fetchedTimes.elementAt(index),
        end: TimeOfDay(
            hour: fetchedTimes.elementAt(index).hour + 3,
            minute: fetchedTimes.elementAt(index).minute),
        disabledTime: TimeRange(
            startTime: parkingClosingHour, endTime: parkingOpeningHour),
        disabledColor: Colors.red.withOpacity(0.5),
        strokeWidth: 5,
        ticks: 24,
        ticksOffset: -12,
        ticksLength: 15,
        ticksColor: Colors.grey,
        labels: ["24h", "3h", "6h", "9h", "12h", "15h", "18h", "21h"]
            .asMap()
            .entries
            .map((e) {
          return ClockLabel.fromIndex(idx: e.key, length: 8, text: e.value);
        }).toList(),
        labelOffset: -30,
        rotateLabels: false,
        padding: 35);
    print("resultTimeRange ${result.toString()}");
  }

  timeSlotsGrid(TimeOfDay startTime, TimeOfDay endTime) {
    return Container(
      color: Colors.white,
      height: fetchedTimes.toList().length * 20,
      child: Scrollbar(
        thumbVisibility: true,
        controller: gridController,
        child: GridView.builder(
            //primary: false,
            controller: gridController,
            shrinkWrap: true,
            itemCount: fetchedTimes.toList().isEmpty
                ? 10
                : fetchedTimes.toList().length - 1,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                childAspectRatio: 1.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 15,
                crossAxisCount: 3),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () async {
                  context.read<StateManagement>().updateSelectedTime(
                      fetchedTimes.elementAt(index)); //don't change
                  showUserRangePicker(index, endTime, startTime);
                },
                child: Row(
                  children: [
                    Card(
                        //margin:const EdgeInsets.only(left: 20, right: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        color: getSelectedTimeSlotColor(index),
                        child: fetchedTimes.toList().isEmpty
                            ? null
                            : Center(
                                child: (index + 1) ==
                                        fetchedTimes.toList().length
                                    ? null
                                    : GridTile(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              left: 8.0, right: 8.0),
                                          child: FittedBox(
                                            alignment: Alignment.bottomCenter,
                                            child: Text(
                                                "${fetchedTimes.elementAt(index).format(context)} - ${fetchedTimes.elementAt(index + 1).format(context)}"),
                                          ),
                                        ),
                                      ),
                              )),
                  ],
                ),
              );
            }),
      ),
    );
  }

  tableCalendar() {
    return Container(
      //CALENDAR//
      margin: const EdgeInsets.fromLTRB(15, 5, 15, 5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TableCalendar(
        rowHeight: 40,
        pageJumpingEnabled: true,
        startingDayOfWeek: StartingDayOfWeek.monday,
        focusedDay: focusedDay,
        firstDay: DateTime.now(),
        lastDay: DateTime(DateTime.now().year + 1),
        selectedDayPredicate: (day) {
          return isSameDay(selectedDay, day);
        },
        onDaySelected: (newSelectedDay, newFocusedDay) {
          print("BEFORE  SELECTED $selectedDay FOCUSED $focusedDay");
          setState(() {
            (newSelectedDay.weekday == DateTime.sunday ||
                    newSelectedDay.weekday == DateTime.saturday)
                ? null
                : selectedDay = newSelectedDay;
            focusedDay = newFocusedDay; // update `_focusedDay` here as well
          });
          print("AFTERR SELECTED $selectedDay FOCUSED $focusedDay");
        },
        //STYLING OF CALENDAR
        calendarFormat: format,
        onFormatChanged: (newFormat) => setState(() {
          format = newFormat;
        }),
        calendarStyle: const CalendarStyle(
          //weekendDecoration: BoxDecoration(color: Colors.purple),
          selectedDecoration:
              BoxDecoration(color: Colors.green, shape: BoxShape.circle),
        ),
      ),
    );
  }

  timeSlotsLegendColorCode() {
    return Row(
      //COLOR LEGEND TIME
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Row(
          //AVAILABLE
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                  color: Colors.green, shape: BoxShape.circle),
            ),
            const SizedBox(width: 3),
            const FittedBox(
              child: Text(
                'Available',
                style: TextStyle(color: Colors.black, fontSize: 15),
              ),
            )
          ],
        ),
        Row(
          //SELECTED
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                  color: Colors.orange, shape: BoxShape.circle),
            ),
            const SizedBox(width: 3),
            const FittedBox(
              child: Text(
                'Selected',
                style: TextStyle(color: Colors.black, fontSize: 15),
              ),
            ),
          ],
        ),
        Row(
          //BOOKED
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle),
            ),
            const SizedBox(width: 3),
            const FittedBox(
              child: Text(
                'Booked',
                style: TextStyle(color: Colors.black, fontSize: 15),
              ),
            )
          ],
        ),
      ],
    );
  }

  addWhiteSpace(double i) {
    return SizedBox(
      height: i,
    );
  }

  bookingStepper() {
    return Container(
      margin: const EdgeInsets.only(left: 5, right: 5),
      width: 90,
      child: IconStepper(
          previousButtonIcon: const Icon(
            Icons.keyboard_double_arrow_left,
            size: 20,
            color: Colors.white,

            ///STOPPED HERE
          ),
          lineColor: Colors.white,
          activeStepBorderColor: Colors.white,
          activeStepBorderWidth: 2,
          stepColor: Colors.white,
          activeStepColor: Colors.green,
          enableNextPreviousButtons: false,
          lineLength: 30,
          lineDotRadius: 1.8,
          stepRadius: 18,
          icons: const [
            Icon(
              Icons.looks_one_outlined,
              color: Colors.black,
            ),
            Icon(
              Icons.looks_two_outlined,
              color: Colors.black,
            ),
            Icon(
              Icons.looks_3_outlined,
              color: Colors.black,
            ),
          ],
          activeStep: activeStep,
          // This ensures step-tapping updates the activeStep.
          onStepReached: (index) {
            setState(() {
              activeStep = index;
            });
          }),
    );
  }

  nextButton() {
    return SizedBox(
      width: 65,
      height: 35,
      child: ElevatedButton(
        style: ButtonStyle(
            elevation: MaterialStateProperty.all(1),
            shape: MaterialStateProperty.all(
              const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20),
                top: Radius.circular(20),
              )),
            ),
            shadowColor: MaterialStateProperty.all(const Color(0xff7986CB)),
            backgroundColor:
                MaterialStateProperty.all(const Color(0xff78909C))),
        onPressed: () {
          activeStep < upperBound
              ? setState(() {
                  activeStep += 1;
                })
              : null;
        },
        child: const Align(child: FittedBox(child: Text("Next"))),
      ),
    );
  }

  /// Returns the previous button.
  previousButton() {
    return SizedBox(
      width: 65,
      height: 35,
      child: ElevatedButton(
        style: ButtonStyle(
            elevation: MaterialStateProperty.all(1),
            shape: MaterialStateProperty.all(
              const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20),
                top: Radius.circular(20),
              )),
            ),
            shadowColor: MaterialStateProperty.all(const Color(0xff7986CB)),
            backgroundColor:
                MaterialStateProperty.all(const Color(0xff78909C))),
        onPressed: () {
          activeStep > 0
              ? setState(() {
                  activeStep -= 1;
                })
              : null;
        },
        child: const Align(child: FittedBox(child: Text("Prev."))),
      ),
    );
  }

  /// Returns the header wrapping the header text.
  bookerBody(double alleyListViewMinHeightToDisplay, TimeOfDay startTime,
      TimeOfDay endTime) {
    return Container(
      child:
          switchBookerBody(alleyListViewMinHeightToDisplay, startTime, endTime),
    );
  }

  // Returns the header text based on the activeStep.
  switchBookerBody(double alleyListViewMinHeightToDisplay, TimeOfDay startTime,
      TimeOfDay endTime) {
    switch (activeStep) {
      case 0:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 10),
            child: Row(
              children: const [
                Icon(
                  Icons.info,
                  color: Colors.indigo,
                ),
                SizedBox(width: 10),
                Text(
                  'Parking Details',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ],
            ),
          ),
          addWhiteSpace(10),
          Container(
            margin: const EdgeInsets.only(left: 15, right: 15),
            height: 100,
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: RawScrollbar(
                      minOverscrollLength: 8,
                      scrollbarOrientation: ScrollbarOrientation.bottom,
                      thumbColor: Colors.blueGrey,
                      radius: const Radius.circular(20),
                      thumbVisibility: true,
                      trackVisibility: true,
                      controller: infoListViewController,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                        child: ListView.builder(
                            controller:
                                infoListViewController, //DO NOT REMOVE. LISTVIEW AND SCROLLBAR MUST SHARE THE SAME CONTROLLER OR YOU'LL GET AN ERROR
                            itemCount: 4,
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              final item = Card(
                                // surfaceTintColor: Colors.yellow,
                                shadowColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                elevation: 5,
                                child: Container(
                                  //THERE WAS AN EXPANDED HERE BEFORE CONTAINER
                                  //width: 95,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50)),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Align(
                                        child: FittedBox(
                                          child: Text(
                                            index == 0
                                                ? 'Name'
                                                : index == 1
                                                    ? "Capacity"
                                                    : index == 2
                                                        ? "Available"
                                                        : "Fee/30mns",
                                            style: const TextStyle(
                                              color: Colors.blueGrey,
                                              fontSize: 15,
                                              fontFamily: 'OpenSans',
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                          width: 85,
                                          child: Align(
                                            child: FittedBox(
                                                child: Text(
                                              //

                                              index == 0
                                                  ? linkedParkingNameAndInsideInfo[
                                                      'Parking Name']
                                                  : index == 1
                                                      ? insideParkingInfoFetched[
                                                              'Total Slots Number']
                                                          .toString()
                                                      : index == 2
                                                          ? insideParkingInfoFetched[
                                                                  'Available Slots']
                                                              .toString()
                                                          : index == 3
                                                              ? "${insideParkingInfoFetched['Fee per 30 minutes'].toString()} CFA"
                                                              : 'Loading',

                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                                fontFamily: 'OpenSans',
                                                fontWeight: FontWeight.w900,
                                              ),
                                            )),
                                          )),
                                    ],
                                  ),
                                ),
                              );
                              return item;
                            }),
                      ),
                    ),
                  ),
                ]),
          ),
          addWhiteSpace(20),

          //
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 0, 10),
            child: Text(
              'Pick A Date',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          tableCalendar(),
          addWhiteSpace(40),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 0, 0),
            child: Text(
              'Pick A Vehicule',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          SelectVehicule(currentlySIUser: currentlySignedInUser),
        ]);

      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(11, 10, 0, 10),
              child: Text(
                'Pick Your Desired Spot',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            insideParkingLayout(alleyListViewMinHeightToDisplay),
            addWhiteSpace(20),
            timeSlotsLegendColorCode(),
            addWhiteSpace(10), //edit height and shape of card
            timeSlotsGrid(startTime, endTime),
          ],
        );

      case 2:
        return Container(
          color: Colors.red,
          child: const Text('VEHICLE SELECT CAR OR MOTORCYCLE'),
        );

      default:
        return Container(
          color: Colors.green,
        );
    }
  }
}

/* void getInsideParkingSlotsInfo(Map<String,dynamic> insideParkingInfoFetched) {
   for (var element in insideParkingInfoFetched) {
     
   }
      
    }
    ;
    insideParkingInfoFetched.keys
                    .where((element) => element.toString() == 'Available Slots')
                    .fetchedAvailableSlots =
                insideParkingInfoFetched.values.where((element) =>
                    element.toString() ==
                    'Available Slots'); //FIND A WAY TO FETCH EVERY ELEMENT OF DATA SNAPSHOT
            //snapshot.data!.docs;
  }*/

//
class DashedSeparatedBordersPainterLTRB extends CustomPainter {
  bool left = false, top = false, right = false, bottom = false;

  DashedSeparatedBordersPainterLTRB(
      this.left, this.top, this.right, this.bottom);

  void drawDashedLeftBorder(
      Canvas canvas,
      Size size,
      Paint paint,
      int dashWidth,
      int dashSpace,
      double paintStartXmin,
      double paintStartYmax) {
    double startX = paintStartXmin;
    double y = size.height; //final destination
    while (y > paintStartYmax) {
      canvas.drawLine(Offset(startX, y), Offset(startX, y - dashWidth), paint);
      y -= dashWidth + dashSpace;
    }
  }

  void drawDashedTopBorder(Canvas canvas, Size size, Paint paint, int dashWidth,
      int dashSpace, double paintStartXmin, double paintStartYmax) {
    double startX = paintStartXmin;
    double y = paintStartYmax;
    while (startX < size.width) {
      // Draw a small line.
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), paint);
      // Update the starting X
      startX += dashWidth + dashSpace;
    }
  }

  void drawDashedRightBorder(Canvas canvas, Size size, Paint paint,
      int dashWidth, int dashSpace, double paintStartYmax) {
    double startX = size.width;
    double y = size.height; //final destination
    while (y > paintStartYmax) {
      canvas.drawLine(Offset(startX, y), Offset(startX, y - dashWidth), paint);
      y -= dashWidth + dashSpace;
    }
  }

  void drawDashedBottomBorder(
      Canvas canvas,
      Size size,
      Paint paint,
      int dashWidth,
      int dashSpace,
      double paintStartXmin,
      double paintStartYmin) {
    double startX = paintStartXmin;
    double y = paintStartYmin + 1;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.grey
      ..strokeCap = StrokeCap.square
      ..strokeWidth = 1;
    _drawDashedLine(canvas, size, paint);
  }

  void _drawDashedLine(Canvas canvas, Size size, Paint paint) {
    // Chage to your preferred size
    const int dashWidth = 4;
    const int dashSpace = 4;
    double paintStartYmax = size.height - 47; //début top-left and - right
    double paintStartXmin = 0;
    double paintStartYmin = size.height;

    left == true
        ? drawDashedLeftBorder(canvas, size, paint, dashWidth, dashSpace,
            paintStartXmin, paintStartYmax)
        : null;

    top == true
        ? drawDashedTopBorder(canvas, size, paint, dashWidth, dashSpace,
            paintStartXmin, paintStartYmax)
        : null;
    right == true
        ? drawDashedRightBorder(
            canvas, size, paint, dashWidth, dashSpace, paintStartYmax)
        : null;

    bottom == true
        ? drawDashedBottomBorder(canvas, size, paint, dashWidth, dashSpace,
            paintStartXmin, paintStartYmin)
        : null;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
