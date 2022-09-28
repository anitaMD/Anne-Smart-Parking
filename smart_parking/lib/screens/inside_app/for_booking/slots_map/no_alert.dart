// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_parking/screens/inside_app/for_booking/booking_overview.dart';
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
  int parkingSlotsTotal = 10;
  late String parkingNameToolBar;
  double alleyHeight = 200,
      singleSpotHeight = 50,
      singleSpotWidth = 120,
      spaceBetweenSlots = 35.0,
      alleySpotWidthRatio = 1 / 4;
  bool isSelected = false;
  Transform occupiedSpotIconLegend = Transform.rotate(
      angle: 50.15,
      child: const Image(image: AssetImage("assets/images/car3.jpg")));

  Color slotHighlithbgColor = Colors.green;
  Color finalSelectedColorSlot = Colors.transparent;

  //LISTS AND MAPS
  final alleyA = <String>{}, alleyB = <String>{};
  var mappedAlleyASelectedCheck = {}, mappedAlleyBSelectedCheck = {};
  List<Map<String, dynamic>> mappedSelectedSlotAlley = [];
  Map<String, dynamic> linkedParkingNameAndInsideInfo = {},
      insideParkingInfoFetched = {},
      bookerFirstPageInfoMapped = {},
      selectedVehiculeInfoMappedFromSelectVehicule = {};
  Map<String, Set> mappedAlleysAndSlotIds = {};
  late Map<String, dynamic> mappedInfoFromWidget = {};
  ScrollController leftAlleyController = ScrollController(),
      rightAlleyController = ScrollController();

//RESERVATION VARS
  bool isReservationDayPicked = false,
      isReservationStartTimePicked = false,
      isReservationDurationPicked = false,
      firstTimeAskingForDateSelect = true,
      nextPressedWithoutFirstPageAllInfoFetched = false,
      removeMaterialBannerSizedBox = false,
      reShowSelectedCarCard = false,
      dontShowAlleyAlertAgainTemporairyly = false;
  Set available = {}, occupied = {}, booked = {};

//BOOKER
  Set<TimeOfDay> fetchedTimes = {};
  CalendarFormat format = CalendarFormat.week;
  Duration interval = const Duration(minutes: 30);
  DateTime selectedDay = DateTime.now(), focusedDay = DateTime.now();
  Color selectedTimeSlotColor = Colors.orange;
  ScrollController singleChildController = ScrollController(),
      timeSlotGridController = ScrollController(),
      infoListViewController = ScrollController(),
      bodyScrollBarController = ScrollController();
  int activeStep = 0, upperBound = 2;

  @override
  void dispose() {
    infoListViewController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    //getAlleySlotsId(parkingSlotsTotal);
    var ok = widget.mappedParkingsGeneralInfo[widget.receivedID]
        as Map<String, dynamic>;
    mappedInfoFromWidget.addAll(ok);
    setState(
      () {
        parkingNameToolBar = ok['Name'];
        print("NAMEMA $parkingNameToolBar");
      },
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print("WIDGET MAPPED! ${widget.mappedParkingsGeneralInfo.values.first}");
    print(
        "nextPressedWithoutFirstPageAllInfoFetched $nextPressedWithoutFirstPageAllInfoFetched");
    currentlySignedInUser = firebaseService.auth.currentUser;
    print(
        "SIGNED IN CURRENTLY ${firebaseService.auth.currentUser?.uid.toString()}");
    double alleyListViewMinHeightToDisplay = alleyHeight +
        (spaceBetweenSlots *
            (parkingSlotsTotal ~/ (parkingSlotsTotal ~/ 2) - 1));

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
    Map<String, dynamic> selectedVehiculeInfoEmptyTest;
    bookerFirstPageInfoMapped.isNotEmpty
        ? {
            selectedVehiculeInfoEmptyTest =
                bookerFirstPageInfoMapped['Selected Vehicule Info']
                    as Map<String, dynamic>,
            selectedVehiculeInfoEmptyTest.isNotEmpty
                ? {
                    ScaffoldMessenger.of(context).clearMaterialBanners(),
                    setState(() {
                      removeMaterialBannerSizedBox = true;
                      print(
                          "removeMaterialBannerSizedBox $removeMaterialBannerSizedBox");
                    })
                  }
                : null
          }
        : null;
    return Scaffold(
      //backgroundColor: Colors.white60,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        toolbarHeight: 90,
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
              ),
              widget.mappedParkingsGeneralInfo.isNotEmpty
                  ? FittedBox(
                      child: Text(
                        parkingNameToolBar,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    )
                  : const Text("LOADING"),
            ],
          )),
        ],
        backgroundColor: Colors.blueGrey,
      ),
      body: RawScrollbar(
        thickness: 5,
        //mainAxisMargin: 190,
        minOverscrollLength: 5,
        minThumbLength: 7,
        scrollbarOrientation: ScrollbarOrientation.right,
        thumbColor: Colors.black26,
        radius: const Radius.circular(50),
        trackRadius: const Radius.circular(50),
        trackColor: Colors.blueGrey.shade100,
        trackBorderColor: Colors.blueGrey.shade100,
        thumbVisibility: true,
        trackVisibility: true,
        controller: singleChildController,
        child: SingleChildScrollView(
          controller: singleChildController,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
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
                        /* snapshot.data!.docs[0]
                            .data()
                            .update('Occupied Slots', (value) => 2); */
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
                        bookerBody(alleyListViewMinHeightToDisplay, startTime,
                            endTime),
                      ],
                    );
                  }
                }),
          ),
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
                    .update('highlightColor', (value) => slotHighlithbgColor),
                refreshSlotColorState(mappedSelectedSlotAlley
                    .elementAt(i + parkingSlotsTotal ~/ 2)
                    .values
                    .last),
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
                    .update('highlightColor', (value) => slotHighlithbgColor),
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
                onHover: (value) => print("HOVERED $value"),
                highlightColor: Colors.blueGrey.shade500,
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
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Flexible(
                                    flex: 2,
                                    child: available.contains("A$i")
                                        ? getParkingSpotIcon(
                                            "insideSpot", 'available')
                                        : occupied.contains("A$i")
                                            ? occupiedSpotIconLegend
                                            : getParkingSpotIcon(
                                                "insideSpot", 'booked')),
                                Flexible(child: FittedBox(child: Text('A$i'))),
                              ],
                            ),
                    ),
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
              color: const Color.fromARGB(255, 63, 97, 95).withAlpha(80),
              child: InkWell(
                onTap: () {
                  print("Click event on Container");
                  fetchAlleySelectedSlotId(i, "alleyB");
                },
                highlightColor: Colors.blueGrey.shade500,
                splashColor: Colors.yellow,
                child: Container(
                  height: singleSpotHeight,
                  width: singleSpotWidth,
                  decoration: BoxDecoration(
                    color: mappedSelectedSlotAlley
                        .elementAt(i + parkingSlotsTotal ~/ 2)
                        .values
                        .last,
                    border: Border(
                      top: BorderSide(
                          color: Colors.indigo.withAlpha(30), width: 2),
                      bottom: BorderSide(
                          color: Colors.indigo.withAlpha(30), width: 2),
                    ),
                  ),
                  child: CustomPaint(
                    //child: Container(color: Colors.yellow,),
                    foregroundPainter: DashedSeparatedBordersPainterLTRB(
                        false, true, false, true),
                    child: Center(
                        child: mappedSelectedSlotAlley
                                .elementAt(i + parkingSlotsTotal ~/ 2)
                                .values
                                .contains(
                                    'true') //crcks if 'isSlotSelected is true or not
                            ? const Text('Selected')
                            : Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Flexible(
                                      flex: 2,
                                      child: available.contains("B$i")
                                          ? getParkingSpotIcon(
                                              "insideSpot", 'available')
                                          : occupied.contains("B$i")
                                              ? occupiedSpotIconLegend
                                              : getParkingSpotIcon(
                                                  "insideSpot", 'booked')),
                                  Flexible(child: Text('B$i')),
                                ],
                              )),
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
    var availableSlotsList = insideParkingInfoFetched.isNotEmpty
        ? insideParkingInfoFetched['Available Slots']['IDs'] as List
        : 'insideParkingInfoFetched empty';

    var bookedSlotsList = insideParkingInfoFetched.isNotEmpty
        ? insideParkingInfoFetched['Booked Slots']['IDs'] as List
        : 'insideParkingInfoFetched empty';

    var currentlyOccupiedSlotsList = insideParkingInfoFetched.isNotEmpty
        ? insideParkingInfoFetched['Occupied Slots']['IDs'] as List
        : 'insideParkingInfoFetched empty';

    print(
        "availableSlotsStatus $availableSlotsList \t bookedSlotsList $bookedSlotsList \t currentlyOccupiedSlotsList $currentlyOccupiedSlotsList");
    for (var i = 0; i < parkingSlotsTotal; i++) {
      (i < parkingSlotsTotal ~/ 2)
          ? {
              alleyA.add("A$i"),
              mappedSelectedSlotAlley.add({
                "alleyA_Id": alleyA.elementAt(i) /* "A$i" */,
                "isSlotSelected": false,
                "isSlotBooked":
                    bookedSlotsList.toString().contains("A$i") ? true : false,
                "isSlotCurrentlyOccupied":
                    currentlyOccupiedSlotsList.toString().contains("A$i")
                        ? true
                        : false,
                "isSlotCurrentlyFree":
                    availableSlotsList.toString().contains("A$i")
                        ? true
                        : false,
                "highlightColor": Colors.transparent
              })
            }
          : {
              alleyB.add("B${j++}"),
              mappedSelectedSlotAlley.add({
                "alleyB_Id": alleyB.elementAt(i -
                    alleyBindexStart), //3 because at this point, i = 3 and I need the counter to reset
                "isSlotSelected": false,
                "isSlotBooked": bookedSlotsList
                        .toString()
                        .contains("B${i - alleyBindexStart}")
                    ? true
                    : false,
                "isSlotCurrentlyOccupied": currentlyOccupiedSlotsList
                        .toString()
                        .contains("B${i - alleyBindexStart}")
                    ? true
                    : false,
                "isSlotCurrentlyFree": availableSlotsList
                        .toString()
                        .contains("B${i - alleyBindexStart}")
                    ? true
                    : false,
                "highlightColor": Colors.transparent
              })
            };
    }
    print("ALLEY A : $alleyA ______________ ALLEY B : $alleyB");
    for (var element in mappedSelectedSlotAlley) {
      element['isSlotCurrentlyFree'] == true
          ? available.add(element.values.first)
          : element['isSlotBooked'] == true
              ? booked.add(element.values.first)
              : element['isSlotCurrentlyOccupied'] == true
                  ? occupied.add(element.values.first)
                  : null;
    }
    debugPrint("Available: $available");
    debugPrint("Booked: $booked");
    debugPrint("Occupied: $occupied");

    debugPrint(
        "\t mappedAlleysAndSlotIdsSelected : \t $mappedSelectedSlotAlley ");
    //print("mappedAlleysAndSlotIdsSelected : $mappedAlleyASelectedCheck ");

    mappedAlleysAndSlotIds.addAll({
      'Alley A': alleyA,
      'Alley B': alleyB,
    });

    print("mappedAlleysAndSlotIds : $mappedAlleysAndSlotIds");
  }

  insideParkingLayout(double alleyListViewMinHeightToDisplay) {
    double kindaWorkingContainerHeightForAlleys =
        ((parkingSlotsTotal ~/ 2) - 0.5) * 80;
    return GestureDetector(
      onVerticalDragCancel: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        var status = prefs.getBool('dontShowAlleyAlertAgain') ?? true;
        debugPrint(
            "DON'T SHOW ALLEY EVER AGAIN? $status  _______ reshow tempo $dontShowAlleyAlertAgainTemporairyly");
        dontShowAlleyAlertAgainTemporairyly == false
            ? showAlleyAlert()
            : dontShowAlleyAlertAgainTemporairyly == true || status == true
                ? null
                : null;
      },
      child: Container(
        margin: const EdgeInsets.only(left: 10, right: 10),
        height: kindaWorkingContainerHeightForAlleys,
        width: double.infinity,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3.0), //<-- SEE HERE
            side: BorderSide(
              color: Colors.indigo.withAlpha(20),
            ),
          ),
          elevation: 8,
          child: Row(
            children: [
              Container(
                /* LEFT ALLEY */
                /* padding: const EdgeInsets.only(
                  top: 10,
                  bottom: 10,
                ), */
                decoration: BoxDecoration(
                    color: Colors.indigo.withAlpha(10),
                    border: Border(
                      left: BorderSide(
                          color: Colors.indigo.withAlpha(30), width: 2),
                      right: BorderSide(
                          color: Colors.indigo.withAlpha(30), width: 2),
                    )),
                width: MediaQuery.of(context).size.width * alleySpotWidthRatio,
                /*  height: alleyListViewMinHeightToDisplay, //otherwise, the slot will appear cutted so I need to show at least half of half the alley number of slots for UI concerns*/
                child: RawScrollbar(
                  mainAxisMargin: 5.0,
                  trackVisibility: false,
                  trackColor: Colors.transparent,
                  thickness: 3,
                  thumbColor: Colors.black54.withOpacity(0.2),
                  scrollbarOrientation: ScrollbarOrientation.left,
                  thumbVisibility: false,
                  controller: leftAlleyController,
                  child: ListView.separated(
                    controller: leftAlleyController,
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
              ),
              Expanded(
                child: Container(
                  color: Colors.indigo.withAlpha(20),
                  height:
                      alleyHeight + spaceBetweenSlots * parkingSlotsTotal ~/ 2,
                  child: Stack(
                    alignment: Alignment.center,
                    children: const [
                      Positioned(
                        top: 0,
                        child: Icon(Icons.arrow_circle_down),
                      ),
                      /*   Center(
                        child: Container(
                          height: 100,
                          width: 100,
                          color: Colors.transparent,
                          child: Card(
                            color: Colors.transparent,
                            child: Column(
                              children: [
                                Flexible(
                                    child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                        child: Icon(Icons.lock_open_outlined,
                                            size: 10)),
                                    Flexible(
                                        child: SizedBox(
                                      width: 30,
                                    )),
                                    Flexible(
                                      child: FittedBox(
                                        child: Text("Currently Free"),
                                      ),
                                    )
                                  ],
                                ))
                              ],
                            ),
                          ),
                        ),
                      ),
                       */
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
                height:
                    alleyHeight + spaceBetweenSlots * parkingSlotsTotal ~/ 2,
                child: RawScrollbar(
                  mainAxisMargin: 5.0,
                  trackVisibility: false,
                  trackColor: Colors.transparent,
                  thickness: 3,
                  thumbColor: Colors.black54.withOpacity(0.2),
                  scrollbarOrientation: ScrollbarOrientation.right,
                  thumbVisibility: false,
                  controller: rightAlleyController,
                  child: ListView.separated(
                    controller: rightAlleyController,
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
              ),
            ],
          ),
        ),
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
      child: Column(
        children: [
          Flexible(
            child: Scrollbar(
              thumbVisibility: true,
              controller: timeSlotGridController,
              child: GridView.builder(
                  //primary: false,
                  controller: timeSlotGridController,
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
                          Flexible(
                            child: Card(
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
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 8.0,
                                                          right: 8.0),
                                                  child: FittedBox(
                                                    alignment:
                                                        Alignment.bottomCenter,
                                                    child: Text(
                                                        "${fetchedTimes.elementAt(index).format(context)} - ${fetchedTimes.elementAt(index + 1).format(context)}"),
                                                  ),
                                                ),
                                              ),
                                      )),
                          ),
                        ],
                      ),
                    );
                  }),
            ),
          ),
        ],
      ),
    );
  }

  tableCalendar() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Container(
        //CALENDAR//
        margin: const EdgeInsets.only(left: 20, right: 20, top: 5, bottom: 5),
        /* decoration: BoxDecoration(
          border: Border.all(color: Colors.black54, width: 1.0),
          borderRadius: BorderRadius.circular(20),
        ), */
        child: TableCalendar(
          rowHeight: 40,
          headerStyle: const HeaderStyle(
              formatButtonTextStyle: TextStyle(fontSize: 10.0),
              titleTextStyle: TextStyle(fontSize: 11)),
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
      ),
    );
  }

  timeSlotsLegendColorCode() {
    return Card(
      child: Row(
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
      ),
    );
  }

  addWhiteSpace(double i) {
    return SizedBox(
      height: i,
    );
  }

  fetchSelectedVehiculeInfo(Map<String, dynamic> selectedVehiculeInf) {
    setState(() {
      selectedVehiculeInfoMappedFromSelectVehicule.addAll(selectedVehiculeInf);
    });
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
          setState(() {
            nextPressedWithoutFirstPageAllInfoFetched = true;
          });
          var selectedVehiculeInfoEmptyTest =
              bookerFirstPageInfoMapped['Selected Vehicule Info']
                  as Map<String, dynamic>;
          selectedVehiculeInfoEmptyTest.isNotEmpty
              ? null
              : {
                  //

                  ScaffoldMessenger.of(context).showMaterialBanner(
                      MaterialBanner(
                          onVisible: (() {}),
                          elevation: 10,
                          contentTextStyle: const TextStyle(
                              color: Colors.white, fontSize: 30),
                          backgroundColor: Colors.black.withOpacity(0.5),
                          leadingPadding: const EdgeInsets.only(right: 10),
                          leading: const Icon(
                            Icons.info,
                            color: Colors.red,
                            size: 25,
                          ),
                          content: const FittedBox(
                            child: Text(
                              'Please select a vehicule to proceed.',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontFamily: 'OpenSans',
                                  fontWeight: FontWeight.w900),
                            ),
                          ),
                          actions: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              nextPressedWithoutFirstPageAllInfoFetched = false;
                            });
                            ScaffoldMessenger.of(context)
                                .hideCurrentMaterialBanner();
                          },
                          child: const Text('OK',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 15,
                                  fontFamily: 'OpenSans',
                                  fontWeight: FontWeight.w900)),
                        ),
                      ])),

                  /* ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: Colors.black.withOpacity(0.7),
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 50),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20))),
                    elevation: 10,
                    behavior: SnackBarBehavior.floating,
                    content: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.info,
                          color: Colors.red,
                          size: 25,
                        ),
                        SizedBox(width: 15),
                        FittedBox(
                          child: Text(
                            'Please select a vehicule to proceed.',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontFamily: 'OpenSans',
                                fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ))
                 */
                };
          activeStep < upperBound && selectedVehiculeInfoEmptyTest.isNotEmpty
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
        bookerFirstPageInfoMapped.addAll({
          'Selected Parking Name':
              linkedParkingNameAndInsideInfo['Parking Name'],
          'Selected Parking Fee / 30mns':
              insideParkingInfoFetched['Fee per 30 minutes'].toString(),
          'Selected Day': selectedDay,
          'Selected Vehicule Info': selectedVehiculeInfoMappedFromSelectVehicule
        });
        print("Booker First Page INFO: $bookerFirstPageInfoMapped}");
        BookingOverviewFinal(
            bookerFirstPageInfoFetched: bookerFirstPageInfoMapped);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          nextPressedWithoutFirstPageAllInfoFetched == true &&
                  removeMaterialBannerSizedBox == false
              ? const SizedBox(height: 40)
              : Container(),
          SizedBox(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.info,
                          color: Colors.indigo,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Parking Details',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  addWhiteSpace(05),
                  Flexible(
                    child: SizedBox(
                      //margin: const EdgeInsets.only(right: 5),
                      height: 170,
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: RawScrollbar(
                                minOverscrollLength: 8,
                                scrollbarOrientation:
                                    ScrollbarOrientation.bottom,
                                thumbColor: Colors.blueGrey,
                                radius: const Radius.circular(20),
                                thumbVisibility: true,
                                trackVisibility: true,
                                controller: infoListViewController,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 5, 0, 20),
                                  child: ListView.builder(
                                      controller:
                                          infoListViewController, //DO NOT REMOVE. LISTVIEW AND SCROLLBAR MUST SHARE THE SAME CONTROLLER OR YOU'LL GET AN ERROR
                                      itemCount: 5, //4,
                                      scrollDirection: Axis.horizontal,
                                      itemBuilder: (context, index) {
                                        final item = Card(
                                          // surfaceTintColor: Colors.yellow,
                                          shadowColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                          elevation: 5,
                                          child: Container(
                                            //THERE WAS AN EXPANDED HERE BEFORE CONTAINER
                                            // width: 115,
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(50)),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Align(
                                                  child: FittedBox(
                                                    child: Text(
                                                      /* index == 0
                                                          ? 'Name'
                                                          :  */
                                                      index == 0
                                                          ? "Capacity"
                                                          : index == 1
                                                              ? "Available"
                                                              : index == 2
                                                                  ? "Fee/30mns"
                                                                  : index == 3
                                                                      ? "Opening Hour"
                                                                      : "Closing Hour",
                                                      style: const TextStyle(
                                                        color: Colors.blueGrey,
                                                        fontSize: 12,
                                                        fontFamily: 'OpenSans',
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                    width: 100,
                                                    child: Align(
                                                      child: FittedBox(
                                                          child: index > 1
                                                              ? Text(
                                                                  //

                                                                  /* index == 0
                                                            ? linkedParkingNameAndInsideInfo[
                                                                'Parking Name']
                                                            :  */
                                                                  index == 2
                                                                      ? "${insideParkingInfoFetched['Fee per 30 minutes'].toString()} CFA"
                                                                      : index ==
                                                                              3
                                                                          ? mappedInfoFromWidget[
                                                                              'Opening Hour']
                                                                          : mappedInfoFromWidget[
                                                                              'Closing Hour'],

                                                                  style:
                                                                      const TextStyle(
                                                                    color: Colors
                                                                        .black87,
                                                                    fontSize:
                                                                        13,
                                                                    fontFamily:
                                                                        'OpenSans',
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w800,
                                                                  ),
                                                                )
                                                              : Row(
                                                                  children: [
                                                                    const Icon(
                                                                        Icons
                                                                            .accessible,
                                                                        color: Colors
                                                                            .blue,
                                                                        size:
                                                                            15),
                                                                    Text(index ==
                                                                            0
                                                                        ? insideParkingInfoFetched['Total Slots Number']
                                                                            .toString()
                                                                        : insideParkingInfoFetched['Available Slots']['Total']
                                                                            .toString()), // for handicaped
                                                                    const SizedBox(
                                                                      width: 10,
                                                                    ),
                                                                    const Icon(
                                                                        Icons
                                                                            .not_accessible,
                                                                        color: Colors
                                                                            .blue,
                                                                        size:
                                                                            15),
                                                                    Text(index ==
                                                                            0
                                                                        ? insideParkingInfoFetched['Total Slots Number']
                                                                            .toString()
                                                                        : insideParkingInfoFetched['Available Slots']['Total']
                                                                            .toString()), // for handicaped
                                                                  ],
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
                  ),
                ],
              ),
            ),
          ),
          addWhiteSpace(50),
          SizedBox(
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: const [
                        Icon(Icons.calendar_month_rounded,
                            color: Colors.indigo),
                        SizedBox(width: 10),
                        Text(
                          'Select A Date',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  tableCalendar(),
                ],
              ),
            ),
          ),
          addWhiteSpace(50),
          SizedBox(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 10,
                right: 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Colors.indigo,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Select A Vehicule',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  SelectVehicule(
                      currentlySIUser: currentlySignedInUser,
                      updateParkingDetailsAndSelectedDayMapped:
                          fetchSelectedVehiculeInfo,
                      reShowSelectedCarCard:
                          selectedVehiculeInfoMappedFromSelectVehicule.isEmpty
                              ? false
                              : true,
                      selectedCarDetails:
                          selectedVehiculeInfoMappedFromSelectVehicule),
                ],
              ),
            ),
          )
        ]);

      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: const EdgeInsets.only(left: 5, right: 5),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 0, 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Row(
                                children: const [
                                  CircleAvatar(
                                    radius: 15,
                                    backgroundColor: Colors.blueGrey,
                                    foregroundColor: Colors.white,
                                    child: Icon(
                                      Icons.local_parking_sharp,
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    'Select A Spot',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Container(
                                margin:
                                    const EdgeInsets.only(top: 0, right: 10),
                                width: 100,
                                height: 78,
                                child: Card(
                                  color: Colors.white,
                                  elevation: 5,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(5, 5, 10, 5),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        //FRIST LINE
                                        Flexible(
                                          child: SizedBox(
                                            height: 15,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 4.0),
                                                  child: getParkingSpotIcon(
                                                      "legend", 'available'),
                                                ),
                                                const Flexible(
                                                  child: FittedBox(
                                                    child: Text(
                                                      "Available",
                                                      style: TextStyle(
                                                          fontSize: 8,
                                                          fontWeight:
                                                              FontWeight.w500),
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        //SECOND LINE
                                        Flexible(
                                          child: SizedBox(
                                            height: 15,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 4.0),
                                                  child: getParkingSpotIcon(
                                                      "legend", "booked"),
                                                ),
                                                const SizedBox(
                                                  width: 10,
                                                ),
                                                const Flexible(
                                                  child: FittedBox(
                                                    child: Text(
                                                      "Booked",
                                                      style: TextStyle(
                                                          fontSize: 8,
                                                          fontWeight:
                                                              FontWeight.w500),
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        Flexible(
                                          child: SizedBox(
                                            height: 15,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                occupiedSpotIconLegend,
                                                const SizedBox(
                                                  width: 10,
                                                ),
                                                const Flexible(
                                                  child: FittedBox(
                                                    child: Text(
                                                      "Occupied",
                                                      style: TextStyle(
                                                          fontSize: 8,
                                                          fontWeight:
                                                              FontWeight.w500),
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        Flexible(
                                          child: SizedBox(
                                            height: 15,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 3.0, bottom: 5),
                                                  child: getParkingSpotIcon(
                                                      "legend", 'accessible'),
                                                ),
                                                const Flexible(
                                                  child: FittedBox(
                                                    child: Text(
                                                      "Special",
                                                      style: TextStyle(
                                                          fontSize: 8,
                                                          fontWeight:
                                                              FontWeight.w500),
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    insideParkingLayout(alleyListViewMinHeightToDisplay),
                    addWhiteSpace(40),
                    //
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 0, 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Row(
                                children: const [
                                  CircleAvatar(
                                    radius: 15,
                                    backgroundColor: Colors.blueGrey,
                                    foregroundColor: Colors.white,
                                    child: Icon(
                                      Icons.access_time_filled_outlined,
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    'Select A Time Slot',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Container(
                                margin:
                                    const EdgeInsets.only(top: 0, right: 10),
                                width: 100,
                                height: 60,
                                child: Card(
                                  color: Colors.white,
                                  elevation: 5,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(5, 5, 10, 5),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        //FRIST LINE
                                        Flexible(
                                          child: SizedBox(
                                            height: 15,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                getTimeSpotIcon('available'),
                                                const Flexible(
                                                  child: FittedBox(
                                                    child: Text(
                                                      "Available",
                                                      style: TextStyle(
                                                          fontSize: 8,
                                                          fontWeight:
                                                              FontWeight.w500),
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        //SECOND LINE
                                        Flexible(
                                          child: SizedBox(
                                            height: 15,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                getTimeSpotIcon('booked'),
                                                const SizedBox(
                                                  width: 10,
                                                ),
                                                const Flexible(
                                                  child: FittedBox(
                                                    child: Text(
                                                      "Booked",
                                                      style: TextStyle(
                                                          fontSize: 8,
                                                          fontWeight:
                                                              FontWeight.w500),
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        Flexible(
                                          child: SizedBox(
                                            height: 15,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Transform.rotate(
                                                    angle: 50.15,
                                                    child: getTimeSpotIcon(
                                                        'occupied')),
                                                const SizedBox(
                                                  width: 10,
                                                ),
                                                const Flexible(
                                                  child: FittedBox(
                                                    child: Text(
                                                      "Occupied",
                                                      style: TextStyle(
                                                          fontSize: 8,
                                                          fontWeight:
                                                              FontWeight.w500),
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),

                    addWhiteSpace(10), //edit height and shape of card
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 0, 20),
                      child: Column(children: [
                        timeSlotsGrid(startTime, endTime),
                        //test()
                      ]),
                    ),
                  ],
                )),
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

  showAlleyAlert() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: Colors.black45.withOpacity(0.4),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FittedBox(
                      child: Text(
                        "Slide through the alleys to check all the slots.",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: 'OpenSans',
                            fontWeight: FontWeight.w900),
                      ),
                    ),
                    Image.asset(
                      "assets/images/alleys.gif",
                      height: 300,
                      width: 300,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                            onPressed: () {
                              Navigator.pop(context, 'do not show again');
                            },
                            child: FittedBox(
                                child: Text(
                              "DO NOT SHOW EVER AGAIN",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.red.shade400),
                            ))),
                        FittedBox(
                          child: TextButton(
                              onPressed: () {
                                Navigator.pop(context, 'show again');
                              },
                              child: const Text("OK",
                                  style: TextStyle(fontSize: 12))),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            )).then((value) {
      print("SHOW AGAIN OR NOT $value");
      value == 'do not show again'
          ? prefs.setBool("dontShowAlleyAlertAgain", true)
          : value == 'show again'
              ? {
                  prefs.setBool("dontShowAlleyAlertAgain", false),
                  setState(
                    () {
                      dontShowAlleyAlertAgainTemporairyly =
                          true; //temporairement
                    },
                  )
                }
              : setState(() {
                  dontShowAlleyAlertAgainTemporairyly = false; //temporairement
                });
    });
  }

  Icon getParkingSpotIcon(String legendOrInsideSpot, String whichIcon) {
    double? iconSize = legendOrInsideSpot == 'legend' ? 13 : 20;
    Icon spotBookedIcon = Icon(Icons.lock_clock_outlined,
            size: iconSize, color: Colors.orange.shade700),
        spotAvailableIcon =
            Icon(Icons.lock_open_outlined, color: Colors.green, size: iconSize),
        specialAccessIcon =
            Icon(Icons.accessible, color: Colors.blue, size: iconSize + 2);

    return whichIcon == 'available'
        ? spotAvailableIcon
        : whichIcon == 'accessible'
            ? specialAccessIcon
            : spotBookedIcon;
  }

  getTimeSpotIcon(String status) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
          color: status == 'available'
              ? Colors.green
              : status == 'occupied'
                  ? Colors.red
                  : Colors.orange.shade700,
          shape: BoxShape.circle),
    );
  }

  test() {
    bool autoValidate = true;
    bool readOnly = false;
    bool showSegmentedControl = true;
    final _formKey = GlobalKey<FormBuilderState>();
    bool _ageHasError = false;
    bool _genderHasError = false;

    var genderOptions = ['Male', 'Female', 'Other'];

    void _onChanged(dynamic val) => debugPrint("ANNAM ${val.toString()}");
    return Column(
      children: [
        FormBuilder(
          key: _formKey,
          // enabled: false,
          onChanged: () {
            _formKey.currentState!.save();
            debugPrint(_formKey.currentState!.value.toString());
          },
          autovalidateMode: AutovalidateMode.disabled,
          initialValue: const {
            'movie_rating': 5,
            'best_language': 'Dart',
            'age': '13',
            'gender': 'Male',
            'languages_filter': ['Dart']
          },
          skipDisabled: true,
          child: Column(
            children: <Widget>[
              const SizedBox(height: 15),
              FormBuilderDateTimePicker(
                name: 'date',
                initialEntryMode: DatePickerEntryMode.calendar,
                initialValue: DateTime.now(),
                inputType: InputType.both,
                decoration: InputDecoration(
                  labelText: 'Appointment Time',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _formKey.currentState!.fields['date']?.didChange(null);
                    },
                  ),
                ),
                initialTime: const TimeOfDay(hour: 8, minute: 0),
                // locale: const Locale.fromSubtags(languageCode: 'fr'),
              ),
              FormBuilderDateRangePicker(
                name: 'date_range',
                firstDate: DateTime(1970),
                lastDate: DateTime(2030),
                onChanged: _onChanged,
                decoration: InputDecoration(
                  labelText: 'Date Range',
                  helperText: 'Helper text',
                  hintText: 'Hint text',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _formKey.currentState!.fields['date_range']
                          ?.didChange(null);
                    },
                  ),
                ),
              ),
              FormBuilderSlider(
                name: 'slider',
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.min(6),
                ]),
                onChanged: _onChanged,
                min: 0.0,
                max: 10.0,
                initialValue: 7.0,
                divisions: 20,
                activeColor: Colors.red,
                inactiveColor: Colors.pink[100],
                decoration: const InputDecoration(
                  labelText: 'Number of things',
                ),
              ),
              FormBuilderRangeSlider(
                name: 'range_slider',
                // validator: FormBuilderValidators.compose([FormBuilderValidators.min(context, 6)]),
                onChanged: _onChanged,
                min: 0.0,
                max: 100.0,
                initialValue: const RangeValues(4, 7),
                divisions: 20,
                activeColor: Colors.red,
                inactiveColor: Colors.pink[100],
                decoration: const InputDecoration(labelText: 'Price Range'),
              ),
              FormBuilderCheckbox(
                name: 'accept_terms',
                initialValue: false,
                onChanged: _onChanged,
                title: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'I have read and agree to the ',
                        style: TextStyle(color: Colors.black),
                      ),
                      TextSpan(
                        text: 'Terms and Conditions',
                        style: TextStyle(color: Colors.blue),
                        // Flutter doesn't allow a button inside a button
                        // https://github.com/flutter/flutter/issues/31437#issuecomment-492411086
                        /*
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      print('launch url');
                                    },
                                  */
                      ),
                    ],
                  ),
                ),
                validator: FormBuilderValidators.equal(
                  true,
                  errorText: 'You must accept terms and conditions to continue',
                ),
              ),
              FormBuilderTextField(
                autovalidateMode: AutovalidateMode.always,
                name: 'age',
                decoration: InputDecoration(
                  labelText: 'Age',
                  suffixIcon: _ageHasError
                      ? Icon(Icons.error, color: Colors.red)
                      : const Icon(Icons.check, color: Colors.green),
                ),
                onChanged: (val) {
                  setState(() {
                    _ageHasError =
                        !(_formKey.currentState?.fields['age']?.validate() ??
                            false);
                  });
                },
                // valueTransformer: (text) => num.tryParse(text),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.numeric(),
                  FormBuilderValidators.max(70),
                ]),
                // initialValue: '12',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              FormBuilderDropdown<String>(
                // autovalidate: true,
                name: 'gender',
                decoration: InputDecoration(
                  labelText: 'Gender',
                  suffix: _genderHasError
                      ? const Icon(Icons.error)
                      : const Icon(Icons.check),
                  hintText: 'Select Gender',
                ),
                validator: FormBuilderValidators.compose(
                    [FormBuilderValidators.required()]),
                items: genderOptions
                    .map((gender) => DropdownMenuItem(
                          alignment: AlignmentDirectional.center,
                          value: gender,
                          child: Text(gender),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _genderHasError =
                        !(_formKey.currentState?.fields['gender']?.validate() ??
                            false);
                  });
                },
                valueTransformer: (val) => val?.toString(),
              ),
              FormBuilderRadioGroup<String>(
                decoration: const InputDecoration(
                  labelText: 'My chosen language',
                ),
                initialValue: null,
                name: 'best_language',
                onChanged: _onChanged,
                validator: FormBuilderValidators.compose(
                    [FormBuilderValidators.required()]),
                options: ['Dart', 'Kotlin', 'Java', 'Swift', 'Objective-C']
                    .map((lang) => FormBuilderFieldOption(
                          value: lang,
                          child: Text(lang),
                        ))
                    .toList(growable: false),
                controlAffinity: ControlAffinity.trailing,
              ),
              FormBuilderSegmentedControl(
                decoration: const InputDecoration(
                  labelText: 'Movie Rating (Archer)',
                ),
                name: 'movie_rating',
                // initialValue: 1,
                // textStyle: TextStyle(fontWeight: FontWeight.bold),
                options: List.generate(5, (i) => i + 1)
                    .map((number) => FormBuilderFieldOption(
                          value: number,
                          child: Text(
                            number.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ))
                    .toList(),
                onChanged: _onChanged,
              ),
              FormBuilderSwitch(
                title: const Text('I Accept the terms and conditions'),
                name: 'accept_terms_switch',
                initialValue: true,
                onChanged: _onChanged,
              ),
              FormBuilderCheckboxGroup<String>(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(
                    labelText: 'The language of my people'),
                name: 'languages',
                // initialValue: const ['Dart'],
                options: const [
                  FormBuilderFieldOption(value: 'Dart'),
                  FormBuilderFieldOption(value: 'Kotlin'),
                  FormBuilderFieldOption(value: 'Java'),
                  FormBuilderFieldOption(value: 'Swift'),
                  FormBuilderFieldOption(value: 'Objective-C'),
                ],
                onChanged: _onChanged,
                separator: const VerticalDivider(
                  width: 10,
                  thickness: 5,
                  color: Colors.red,
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.minLength(1),
                  FormBuilderValidators.maxLength(3),
                ]),
              ),
              FormBuilderFilterChip<String>(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(
                    labelText: 'The language of my people'),
                name: 'languages_filter',
                selectedColor: Colors.red,
                options: const [
                  FormBuilderChipOption(
                    value: 'Dart',
                    avatar: CircleAvatar(child: Text('D')),
                  ),
                  FormBuilderChipOption(
                    value: 'Kotlin',
                    avatar: CircleAvatar(child: Text('K')),
                  ),
                  FormBuilderChipOption(
                    value: 'Java',
                    avatar: CircleAvatar(child: Text('J')),
                  ),
                  FormBuilderChipOption(
                    value: 'Swift',
                    avatar: CircleAvatar(child: Text('S')),
                  ),
                  FormBuilderChipOption(
                    value: 'Objective-C',
                    avatar: CircleAvatar(child: Text('O')),
                  ),
                ],
                onChanged: _onChanged,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.minLength(1),
                  FormBuilderValidators.maxLength(3),
                ]),
              ),
              FormBuilderChoiceChip<String>(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(
                    labelText:
                        'Ok, if I had to choose one language, it would be:'),
                name: 'languages_choice',
                initialValue: 'Dart',
                options: const [
                  FormBuilderChipOption(
                    value: 'Dart',
                    avatar: CircleAvatar(child: Text('D')),
                  ),
                  FormBuilderChipOption(
                    value: 'Kotlin',
                    avatar: CircleAvatar(child: Text('K')),
                  ),
                  FormBuilderChipOption(
                    value: 'Java',
                    avatar: CircleAvatar(child: Text('J')),
                  ),
                  FormBuilderChipOption(
                    value: 'Swift',
                    avatar: CircleAvatar(child: Text('S')),
                  ),
                  FormBuilderChipOption(
                    value: 'Objective-C',
                    avatar: CircleAvatar(child: Text('O')),
                  ),
                ],
                onChanged: _onChanged,
              ),
            ],
          ),
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.saveAndValidate() ?? false) {
                    debugPrint(
                        " ANNAM ${_formKey.currentState?.value.toString()}");
                  } else {
                    debugPrint(_formKey.currentState?.value.toString());
                    debugPrint('validation failed');
                  }
                },
                child: const Text(
                  'Submit',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _formKey.currentState?.reset();
                },
                // color: Theme.of(context).colorScheme.secondary,
                child: Text(
                  'Reset',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.secondary),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
}

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
