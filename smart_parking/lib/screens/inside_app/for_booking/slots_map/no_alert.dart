import 'package:firebase_auth/firebase_auth.dart';
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
      {Key? key, required this.receivedID, required this.mappedParkingsGeneralInfo, required this.slotBooked})
      : super(key: key);

  @override
  State<BookingThroughSlotsMapNoAlertDialog> createState() => _BookingThroughSlotsMapNoAlertDialogState();
}

class _BookingThroughSlotsMapNoAlertDialogState extends State<BookingThroughSlotsMapNoAlertDialog> {
  //AUTHENTICATION
  var myDB = FirebaseFirestore.instance;
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
      child: const Image(
        image: AssetImage("assets/images/car3.jpg"),
      ));

  Color slotHighlithbgColor = Colors.green;
  Color finalSelectedColorSlot = Colors.transparent;

  //LISTS AND MAPS
  final alleyA = <String>{}, alleyB = <String>{};
  var mappedAlleyASelectedCheck = {}, mappedAlleyBSelectedCheck = {};
  List<Map<String, dynamic>> mappedSelectedSlotAlley = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> slotsReservationsInfoFetchedList = [];
  Map<String, dynamic> linkedParkingNameAndInsideInfo = {},
      insideParkingInfoFetched = {},
      bookerFirstPageInfoMapped = {},
      selectedVehiculeInfoMappedFromSelectVehicule = {},
      slotsReservationsInfoFetchedAsMapWithData = {};
  Map<String, Set> mappedAlleysAndSlotIds = {};
  late Map<String, dynamic> mappedInfoFromWidget = {};

  bool test = true;

//RESERVATION VARS
  bool isReservationDayPicked = false,
      isReservationStartTimePicked = false,
      isReservationDurationPicked = false,
      firstTimeAskingForDateSelect = true,
      nextPressedWithoutFirstPageAllInfoFetched = false,
      removeMaterialBannerSizedBox = false,
      reShowSelectedCarCard = false,
      dontShowAlleyAlertAgainTemporairyly = false,
      updatedClosingAndOpening = false;

  Set rAvailableIDs = {},
      rOccupiedAfterBookedIDs = {},
      rOccupiedNoPriorBookingIDs = {},
      rBookedIDs = {},
      sAvailableIDs = {},
      sOccupiedAfterBookedIDs = {},
      sOccupiedNoPriorBookingIDs = {},
      sBookedIDs = {},
      allSpecialSpotsIDs = {},
      allRegularSpotsID = {};

  int specialTotal = 0,
      specialAvailableTotal = 0,
      regularTotal = 0,
      regularAvailableTotal = 0,
      totalParkingCapacity = 0;
  //OccupiedNoPriorBooking for cars parked onlhy by interacting with the real parking and didn't use the app to book like taxis or whatever
  Set<String> spotIDsWithinXHoursList = {},
      spotIDsWithinXHoursBookedNotOccupied = {},
      spotIDsWithinXHoursBookedAndOccupied = {},
      spotIDsWithinXHoursBookedThenFreed =
          {}; //do not delete any because will need to update an eventuel is booking over value

//BOOKER

  Map<String, dynamic> testallBookedTimeSlotsInMinutes = {}, withinXHoursParkingSpotIDsToShow = {};
  Set<TimeOfDay> allBookedTimeSlots = {};
  Map<String, dynamic> testallBookedTimeSlots = {}, allReservationsSameDaySameParkingWithKey = {};
  Set<TimeOfDay> timesOfDayFetched = {};
  CalendarFormat format = CalendarFormat.week;
  Duration interval = const Duration(minutes: 30);
  DateTime selectedDay = DateTime.now(), focusedDay = DateTime.now();
  Color selectedTimeSlotColor = Colors.blueGrey.shade500;
  ScrollController singleChildController = ScrollController(),
      leftAlleyController = ScrollController(),
      rightAlleyController = ScrollController(),
      timeSlotGridController = ScrollController(),
      infoListViewController = ScrollController(),
      bodyScrollBarController = ScrollController();
  int activeStep = 0, upperBound = 2, stop = 0; //do not remove any of these
  var timeSlotAvailable = {}, timeSlotCurrentlyOccupied = {}, timeSlotbooked = {};

  @override
  void dispose() {
    infoListViewController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    //getAlleySlotsId(parkingSlotsTotal);
    //batchWriteInsideParkingInfo();
    var ok = widget.mappedParkingsGeneralInfo[widget.receivedID] as Map<String, dynamic>;
    mappedInfoFromWidget.addAll(ok);
    setState(
      () {
        parkingNameToolBar = ok['Name'];
        debugPrint("NAMEMA ${widget.receivedID}");
      },
    );

    fetchParkingSlotsInfoFromFB();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("WIDGET MAPPED! $mappedInfoFromWidget _ $focusedDay");
    debugPrint("nextPressedWithoutFirstPageAllInfoFetched $nextPressedWithoutFirstPageAllInfoFetched");
    currentlySignedInUser = firebaseService.auth.currentUser;
    debugPrint("SIGNED IN CURRENTLY ${firebaseService.auth.currentUser?.uid.toString()}");
    double alleyListViewMinHeightToDisplay =
        alleyHeight + (spaceBetweenSlots * (parkingSlotsTotal ~/ (parkingSlotsTotal ~/ 2) - 1));

    var stateManagerRead = context.read<StateManagement>();

    debugPrint(
        "OK LISTENING: ${stateManagerRead.updateOpeningAndClosingHours(mappedInfoFromWidget['Opening Hour'], mappedInfoFromWidget['Closing Hour'])} __________ ${context.watch<StateManagement>().openingHour} ______ ${context.watch<StateManagement>().closingHour}");
    //TIMESLOTSELECTION
    TimeOfDay startTime = TimeOfDay(
            hour: int.parse(context.watch<StateManagement>().openingHour.split(":")[0]),
            minute: int.parse(context.watch<StateManagement>().openingHour.split(":")[1])),
        endTime = TimeOfDay(
            hour: int.parse(context.watch<StateManagement>().closingHour.split(":")[0]),
            minute: int.parse(context.watch<StateManagement>().closingHour.split(":")[1]));

    debugPrint("OK LISTENING TIME OF  DAY $startTime ___ $endTime");
    stateManagerRead.getTimeSlotsIntervals(startTime, endTime, interval).toList().then((value) {
      debugPrint("OK LISTENING LIST $value   ___ \t stop $stop");
      stop < 2
          ? setState(() {
              timesOfDayFetched.clear;
              timesOfDayFetched.addAll(value);
              context.read<StateManagement>().timeSlotsParsed = value;
            })
          : null;

      debugPrint(
          "VOIR $timesOfDayFetched ____ context.readtimeSlotsParsed ${context.read<StateManagement>().timeSlotsParsed}");
    });
    stop += 1;
    Map<String, dynamic> selectedVehiculeInfoEmptyTest;
    bookerFirstPageInfoMapped.isNotEmpty
        ? {
            selectedVehiculeInfoEmptyTest = bookerFirstPageInfoMapped['Selected Vehicule Info'] as Map<String, dynamic>,
            selectedVehiculeInfoEmptyTest.isNotEmpty
                ? {
                    ScaffoldMessenger.of(context).clearMaterialBanners(),
                    setState(() {
                      removeMaterialBannerSizedBox = true;
                      debugPrint("removeMaterialBannerSizedBox $removeMaterialBannerSizedBox");
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
                    .collection("locations/${widget.receivedID}/insideParkingInfo")
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
                    String source = snapshot.data!.metadata.hasPendingWrites ? "Local" : "Server";
                    // insideParkingInfoFetched.clear();
                    insideParkingInfoFetched = snapshot.data!.docs[0].data(); //PUT BACK 0
                    for (var element in widget.mappedParkingsGeneralInfo.entries) {
                      if (element.key == widget.receivedID) {
                        String currentlySelectedParkingsName = element.value
                            .toString()
                            .split(',')
                            .toList()
                            .elementAt(element.value
                                .toString()
                                .split(',')
                                .toList()
                                .indexWhere((element) => element.contains("Parking")))
                            .split(':')
                            .toList()
                            .last
                            .split('}')
                            .first;
//come back here and put whatever as Map<String, dynamic> and treat the data isntead of splitting
                        linkedParkingNameAndInsideInfo
                            .addAll({'Parking Name': currentlySelectedParkingsName, 'Info': insideParkingInfoFetched});
                        /* snapshot.data!.docs[0]
                            .data()
                            .update('Occupied Slots', (value) => 2); */
                      }
                    }
                    parkingSlotsTotal = insideParkingInfoFetched["Total"];
                    fetchParkingSlotsInfoFromFB();
                    debugPrint(
                        "DATA SNAP: linkedParkingNameAndInsideInfo $linkedParkingNameAndInsideInfo \t insideParkingInfoFetched $insideParkingInfoFetched");

                    return Column(
                      children: [bookerBody(alleyListViewMinHeightToDisplay, startTime, endTime)],
                    );
                  }
                }),
          ),
        ),
      ),
    );
  }

  Color getSelectedTimeSlotColor(int index, Map<String, dynamic> slotsReservationsInfoFetchedAsMapWithData) {
    Map<String, dynamic> bookedIntervalsSlotColor =
        testconvertAllTimesOfDayFetched(testallBookedTimeSlotsInMinutes, timesOfDayFetched);
    Set timeSlotCardBookedIndex = <int>{};

    for (var element in bookedIntervalsSlotColor.values) {
      debugPrint("MALA : $element");
      index >= element['startIndex'] && index <= element['endIndex'] ? timeSlotCardBookedIndex.add(index) : null;
    }
    /*
    DO NOT DELETE
    Set<int> allBookedTimeSlotsInMinutes = {};
     /*  var sameDayReservationAsUserList =
        slotsReservationsInfoFetchedAsMapWithData.values.where(
      (element) {
        //fetching all the timeSlots that are booked for the selectedDay if USER HAS NOT CLICKED YET ON ANY PARKING SPOT
        var timeST = element['BookingStart'] as Timestamp;

        //debugPrint("MTMT ${timeST.toDate()}");
        return timeST.toDate().day == selectedDay.day &&
            timeST.toDate().month == selectedDay.month &&
            timeST.toDate().year == selectedDay.year;
      },
    ); */
     for (var singleReservationSameDayAsUserSelectedDay
        in sameDayReservationAsUserList) {
      var singleReservationCasted =
          singleReservationSameDayAsUserSelectedDay as Map<String, dynamic>;
      var singleBookingStartTimeStamp =
          singleReservationSameDayAsUserSelectedDay['BookingStart']
              as Timestamp;
      var singleBookingEndTimeStamp =
          singleReservationSameDayAsUserSelectedDay['BookingEnd'] as Timestamp;
      debugPrint("$singleReservationCasted");

      allBookedTimeSlots
          .add(TimeOfDay.fromDateTime(singleBookingStartTimeStamp.toDate()));
      testallBookedTimeSlotsInMinutes.addAll({});

      int bookedTimeInt =
          (TimeOfDay.fromDateTime(singleBookingStartTimeStamp.toDate()).hour *
                      60 +
                  TimeOfDay.fromDateTime(singleBookingStartTimeStamp.toDate())
                      .minute) *
              60;
      allBookedTimeSlotsInMinutes.add(bookedTimeInt);
    }
  Set<int> bookedTimeSlotColor = convertAllTimesOfDayFetched(
        allBookedTimeSlotsInMinutes, timesOfDayFetched); 
        
         /*FOR the return below : bookedTimeSlotColor.any((element) => element ~/ 2 == index) ==
                    true
                ? Colors.orange */
            
        */
    debugPrint(" PFF ${bookedIntervalsSlotColor.values}");
    return timesOfDayFetched.isEmpty
        ? Colors.blue
        : context.watch<StateManagement>().selectedTime == timesOfDayFetched.elementAt(index)
            ? selectedTimeSlotColor
            /*  : timeSlotCardBookedIndex.any((element) => element == index) == true
                ? Colors.orange */ //ADD IF PARKING SPOT IS SELECTED TOO
            : Colors.white;
    //: Colors.white;
  }

  fetchAlleySelectedSlotId(int i, String alley) {
    for (var singleAlleyInfo in mappedSelectedSlotAlley) {
      singleAlleyInfo.update('isSlotSelected', (value) => false);
      // DO NOT MOVE OR REMOVE THE UPPER LINE CMD. It has to put everything to false before putting only the selected slot to true
      singleAlleyInfo.update('highlightColor', (value) => Colors.transparent);
      refreshSlotColorState(Colors.transparent);
      if (singleAlleyInfo.keys.first.contains('B') && alley.contains('B')) {
        mappedSelectedSlotAlley.elementAt(i + parkingSlotsTotal ~/ 2) ==
                singleAlleyInfo //parkingSlotsTotal ~/ 2 = 3 needed to get to the B section because the received i in parameters is limited to half the total number of slots
            ? {
                mappedSelectedSlotAlley.elementAt(i + parkingSlotsTotal ~/ 2).update('isSlotSelected', (value) => true),
                mappedSelectedSlotAlley
                    .elementAt(i + parkingSlotsTotal ~/ 2)
                    .update('highlightColor', (value) => slotHighlithbgColor),
                refreshSlotColorState(mappedSelectedSlotAlley.elementAt(i + parkingSlotsTotal ~/ 2).values.last),
              }
            : {
                singleAlleyInfo.update('isSlotSelected', (value) => false),
                singleAlleyInfo.update('highlightColor', (value) => Colors.transparent)
              };
      } else if (singleAlleyInfo.keys.first.contains('A') && alley.contains('A')) {
        mappedSelectedSlotAlley.elementAt(i) == singleAlleyInfo
            ? {
                mappedSelectedSlotAlley.elementAt(i).update('isSlotSelected', (value) => true),
                mappedSelectedSlotAlley.elementAt(i).update('highlightColor', (value) => slotHighlithbgColor),
                refreshSlotColorState(mappedSelectedSlotAlley.elementAt(i).values.last),
              }
            : {
                singleAlleyInfo.update('isSlotSelected', (value) => false),
                singleAlleyInfo.update('highlightColor', (value) => Colors.transparent)
              };
      }
    }

    debugPrint("REALLY? ${mappedSelectedSlotAlley.elementAt(i)} ___ $mappedSelectedSlotAlley");
  }

  buildLeftAlleySlots(int parkingSlotsTotal, double spaceBetweenSlots, bool isSelected) {
    int leftAlleySlotsTotal = parkingSlotsTotal ~/ 2;
    return List.generate(
        leftAlleySlotsTotal,
        (i) => Material(
              color: const Color.fromARGB(255, 63, 97, 95).withAlpha(80),
              child: InkWell(
                onHover: (value) => debugPrint("HOVERED $value"),
                highlightColor: Colors.blueGrey.shade500,
                onTap: () {
                  fetchAlleySelectedSlotId(i, "alleyA");
                  //highlightSelectedSlot(isSelected, i);
                },
                splashColor: Colors.yellow,
                child: Container(
                  height: singleSpotHeight,
                  width: singleSpotWidth,
                  decoration: BoxDecoration(
                    color: mappedSelectedSlotAlley.elementAt(i).values.last,
                    border: Border(
                      top: BorderSide(color: Colors.indigo.withAlpha(30), width: 2),
                      bottom: BorderSide(color: Colors.indigo.withAlpha(30), width: 2),
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
                    foregroundPainter: DashedSeparatedBordersPainterLTRB(false, true, false, true),
                    child: Center(
                      child: mappedSelectedSlotAlley.elementAt(i)['isSlotSelected'] ==
                              true //checks if 'isSlotSelected is true or not
                          ? const Text('Selected')
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Flexible(
                                    flex: 2,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        allSpecialSpotsIDs.contains("A$i")
                                            ? Flexible(flex: 1, child: getParkingSpotIcon("insideSpot", 'accessible'))
                                            : Container(),
                                        Flexible(
                                          child: /* available.contains("A$i") ||
                                                  specialAvailable.contains("A$i")
                                              ? getParkingSpotIcon(
                                                  "insideSpot", 'available')
                                              : occupied.contains("A$i") ||
                                                      specialOccupied.contains("A$i")
                                                  ? occupiedSpotIconLegend
                                                  :  */
                                              rOccupiedAfterBookedIDs.contains("A$i") ||
                                                      sOccupiedAfterBookedIDs.contains("A$i")
                                                  ? occupiedSpotIconLegend
                                                  : spotIDsWithinXHoursBookedAndOccupied.contains("A$i") ||
                                                          rOccupiedNoPriorBookingIDs.contains("A$i") ||
                                                          sOccupiedNoPriorBookingIDs.contains("A$i")
                                                      ? const Icon(Icons.time_to_leave, color: Colors.red, size: 20)
                                                      : spotIDsWithinXHoursBookedThenFreed.contains("A$i") ||
                                                              sAvailableIDs.contains("A$i") ||
                                                              rAvailableIDs.contains("A$i")
                                                          ? getParkingSpotIcon("insideSpot", 'available')
                                                          : getParkingSpotIcon("insideSpot", 'booked'),
                                        ),
                                      ],
                                    )),
                                Flexible(flex: 2, child: FittedBox(child: Text('A$i'))),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            )).toList(); // replace * with your rupee or use Icon instead
  }

  buildRightAlleySlots(int parkingSlotsTotal, double spaceBetweenSlots, bool isSelected) {
    int rightAlleySlotsTotal = parkingSlotsTotal ~/ 2;
    return List.generate(
        rightAlleySlotsTotal,
        (i) => Material(
              color: const Color.fromARGB(255, 63, 97, 95).withAlpha(80),
              child: InkWell(
                onTap: () {
                  debugPrint("Click event on Container");
                  fetchAlleySelectedSlotId(i, "alleyB");
                },
                highlightColor: Colors.blueGrey.shade500,
                splashColor: Colors.yellow,
                child: Container(
                  height: singleSpotHeight,
                  width: singleSpotWidth,
                  decoration: BoxDecoration(
                    color: mappedSelectedSlotAlley.elementAt(i + parkingSlotsTotal ~/ 2).values.last,
                    border: Border(
                      top: BorderSide(color: Colors.indigo.withAlpha(30), width: 2),
                      bottom: BorderSide(color: Colors.indigo.withAlpha(30), width: 2),
                    ),
                  ),
                  child: CustomPaint(
                    //child: Container(color: Colors.yellow,),
                    foregroundPainter: DashedSeparatedBordersPainterLTRB(false, true, false, true),
                    child: Center(
                        child: mappedSelectedSlotAlley.elementAt(i + parkingSlotsTotal ~/ 2)['isSlotSelected'] ==
                                true //crcks if 'isSlotSelected is true or not
                            ? const Text('Selected')
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Flexible(
                                    flex: 2,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        allSpecialSpotsIDs.contains("B$i")
                                            ? Flexible(flex: 1, child: getParkingSpotIcon("insideSpot", 'accessible'))
                                            : Container(),
                                        Flexible(
                                          child: rOccupiedAfterBookedIDs.contains("B$i") ||
                                                  sOccupiedAfterBookedIDs.contains("B$i")
                                              ? occupiedSpotIconLegend
                                              : spotIDsWithinXHoursBookedAndOccupied.contains("B$i") ||
                                                      rOccupiedNoPriorBookingIDs.contains("B$i") ||
                                                      sOccupiedNoPriorBookingIDs.contains("B$i")
                                                  ? const Icon(Icons.time_to_leave, color: Colors.red, size: 20)
                                                  : spotIDsWithinXHoursBookedThenFreed.contains("B$i") ||
                                                          sAvailableIDs.contains("B$i") ||
                                                          rAvailableIDs.contains("B$i")
                                                      ? getParkingSpotIcon("insideSpot", 'available')
                                                      : getParkingSpotIcon("insideSpot", 'booked'),
                                          /* available.contains("B$i") ||
                                                  specialAvailable.contains("B$i")
                                              ? getParkingSpotIcon(
                                                  "insideSpot", 'available')
                                              : occupied.contains("B$i") ||
                                                      specialOccupied.contains("B$i")
                                                  ? occupiedSpotIconLegend
                                                  : getParkingSpotIcon(
                                                      "insideSpot", 'booked') */
                                        ),
                                      ],
                                    ),
                                  ),
                                  Flexible(flex: 2, child: Text('B$i')),
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
      if (mappedSelectedSlotAlley.elementAt(i).values.last == singleAlleyInfo.values.last) {
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

  getAlleySlotsIdWithFBListeners(parkingSlotsTotal) {
    var withinXHoursEntriesFetched = getWithinXHoursAvailabalitySatus(3);
    FirebaseFirestore.instance
        .collection("slotsReservations")
        .where("ParkingID", isEqualTo: widget.receivedID)
        .snapshots()
        .listen((event) {
      //by default, someone who books will not be parked yet. so VEHICULESTATUS will be not yet parked
      for (var change in event.docChanges) {
        switch (change.type) {
          case DocumentChangeType.added:
            debugPrint("Slots Reservations Document Just Loaded: ${change.doc.data()}");
            break;
          case DocumentChangeType.modified:
            debugPrint("Slots Reservations Document Just EDITED: ${change.doc.data()}");
            if (change.doc.data()!['VehiculeStatus'] == 'Parked') {
              spotIDsWithinXHoursBookedNotOccupied.remove(change.doc.data()!['SlotID']);
              spotIDsWithinXHoursBookedAndOccupied.add(change.doc.data()!['SlotID']);
            }
            if (change.doc.data()!['VehiculeStatus'] == 'Gone') {
              spotIDsWithinXHoursBookedAndOccupied.remove(change.doc.data()!['SlotID']);
              spotIDsWithinXHoursBookedThenFreed.add(change.doc.data()!['SlotID']);
            }
            break;
          case DocumentChangeType.removed:
            debugPrint("Reservation DONE SO Archived: ${change.doc.data()}");
            break;
        }
      }
    });
    //FIND A WAY TO LINK THESE TWO EVENT LISTENERS TRHOUG BOOKED AND OCCUPIDETHENBOOKED. available will depen on these so no need to touch it
    FirebaseFirestore.instance
        .collection("locations/${widget.receivedID}/insideParkingInfo")
        .where("Fee per 30 minutes", isGreaterThan: 400)
        .snapshots()
        .listen((event) {
      for (var change in event.docChanges) {
        switch (change.type) {
          case DocumentChangeType.added:
            debugPrint("Inside Parking Info Document Just Loaded: ${change.doc.data()}");
            break;
          case DocumentChangeType.modified:
            debugPrint("Inside Parking Info Document Just EDITED: ${change.doc.data()}");

            if (change.doc.data()!['Regular']['Available']['Booked'] == 'Parked') {
              spotIDsWithinXHoursBookedNotOccupied.remove(change.doc.data()!['SlotID']);
              spotIDsWithinXHoursBookedAndOccupied.add(change.doc.data()!['SlotID']);
            }
            if (change.doc.data()!['VehiculeStatus'] == 'Gone') {
              spotIDsWithinXHoursBookedAndOccupied.remove(change.doc.data()!['SlotID']);
              spotIDsWithinXHoursBookedThenFreed.add(change.doc.data()!['SlotID']);
            }

            break;
          case DocumentChangeType.removed:
            debugPrint("Reservation DONE SO Archived: ${change.doc.data()}");
            break;
        }
      }
    });

    for (var element in withinXHoursEntriesFetched) {
      var values = element.value as Map<String, dynamic>;
      spotIDsWithinXHoursList.add(values['SlotID']);
      values['VehiculeStatus'] == 'Parked'
          ? spotIDsWithinXHoursBookedAndOccupied.add(values['SlotID'])
          : values['VehiculeStatus'] == 'Not Yet Parked'
              ? spotIDsWithinXHoursBookedNotOccupied.add(values['SlotID'])
              : spotIDsWithinXHoursBookedThenFreed.add(values['SlotID']);
    }
    withinXHoursParkingSpotIDsToShow.addAll({
      'All Spot IDs': spotIDsWithinXHoursList,
      'WithinXHoursBookedNotOccupied': spotIDsWithinXHoursBookedNotOccupied,
      'WithinXHoursBookedThenFree': spotIDsWithinXHoursBookedThenFreed,
      'WithinXHoursBookedAndOccupied': spotIDsWithinXHoursBookedAndOccupied
    });
    debugPrint("WORKED $withinXHoursEntriesFetched ______ $withinXHoursParkingSpotIDsToShow");

    int alleyBindexStart = parkingSlotsTotal ~/ 2;
    var j = 0;
    //fetchParkingSlotsInfoFromFB();
    createAlleysMappingWithIDs(alleyBindexStart, j);
    debugPrint("mappedAlleysAndSlotIds : $mappedAlleysAndSlotIds");
  }

  insideParkingLayout(double alleyListViewMinHeightToDisplay) {
    double kindaWorkingContainerHeightForAlleys = ((parkingSlotsTotal ~/ 2) - 0.5) * 80;
    //print("kindaWorkingContainerHeightForAlleys $kindaWorkingContainerHeightForAlleys");
    return GestureDetector(
      onVerticalDragCancel: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        var status = prefs.getBool('dontShowAlleyAlertAgain') ?? true;
        debugPrint("DON'T SHOW ALLEY EVER AGAIN? $status  _______ reshow tempo $dontShowAlleyAlertAgainTemporairyly");
        dontShowAlleyAlertAgainTemporairyly == false
            ? showAlleyAlert()
            : dontShowAlleyAlertAgainTemporairyly == true || status == true
                ? null
                : null;
      },
      child: Container(
        margin: const EdgeInsets.only(left: 10, right: 10),
        height: kindaWorkingContainerHeightForAlleys > 480 ? 480 : kindaWorkingContainerHeightForAlleys,
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
                decoration: BoxDecoration(
                    color: Colors.indigo.withAlpha(10),
                    border: Border(
                      left: BorderSide(color: Colors.indigo.withAlpha(30), width: 2),
                      right: BorderSide(color: Colors.indigo.withAlpha(30), width: 2),
                    )),
                width: MediaQuery.of(context).size.width * alleySpotWidthRatio,
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
                      final item = buildLeftAlleySlots(parkingSlotsTotal, spaceBetweenSlots, isSelected)[index];
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
                  //height: alleyHeight + spaceBetweenSlots * parkingSlotsTotal ~/ 2,
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
                      left: BorderSide(color: Colors.indigo.withAlpha(30), width: 2),
                      right: BorderSide(color: Colors.indigo.withAlpha(30), width: 2),
                    )),
                width: MediaQuery.of(context).size.width * alleySpotWidthRatio,
                //height: alleyHeight + spaceBetweenSlots * parkingSlotsTotal ~/ 2,
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
                      final item = buildRightAlleySlots(parkingSlotsTotal, spaceBetweenSlots, isSelected)[index];
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

  showUserRangePicker(int index, TimeOfDay parkingClosingHour, TimeOfDay parkingOpeningHour,
      Map<String, dynamic> slotsReservationsInfoFetchedAsMapWithData) async {
    TimeRange? result = await showTimeRangePicker(
        context: context,
        start: timesOfDayFetched.elementAt(index),
        end: TimeOfDay(
            hour: timesOfDayFetched.elementAt(index).hour + 3, minute: timesOfDayFetched.elementAt(index).minute),
        disabledTime: TimeRange(startTime: parkingClosingHour, endTime: parkingOpeningHour),
        disabledColor: Colors.red.withOpacity(0.5),
        strokeWidth: 5,
        ticks: 24,
        ticksOffset: -12,
        ticksLength: 15,
        ticksColor: Colors.grey,
        labels: ["24h", "3h", "6h", "9h", "12h", "15h", "18h", "21h"].asMap().entries.map((e) {
          return ClockLabel.fromIndex(idx: e.key, length: 8, text: e.value);
        }).toList(),
        labelOffset: -30,
        rotateLabels: false,
        padding: 35);
    debugPrint("resultTimeRange ${result.toString()}");
  }

  timeSlotsGrid(
      TimeOfDay startTime, TimeOfDay endTime, Map<String, dynamic> slotsReservationsInfoFetchedAsMapWithData) {
    return Container(
      color: Colors.white,
      height: timesOfDayFetched.toList().length * 10,
      child: Column(
        children: [
          Flexible(
            child: Scrollbar(
              thumbVisibility: false,
              controller: timeSlotGridController,
              child: GridView.builder(
                  //primary: false,
                  controller: timeSlotGridController,
                  shrinkWrap: true,
                  itemCount: timesOfDayFetched.toList().isEmpty ? 10 : (timesOfDayFetched.toList().length ~/ 2),

                  ///becaause I used two items per bloc
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      childAspectRatio: 1.5, crossAxisSpacing: 10, mainAxisSpacing: 15, crossAxisCount: 3),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () async {
                        context
                            .read<StateManagement>()
                            .updateSelectedTime(timesOfDayFetched.elementAt(index)); //don't change
                        debugPrint("MAMAMA ${focusedDay.hour}");
                        showUserRangePicker(index, endTime, startTime, slotsReservationsInfoFetchedAsMapWithData);
                      },
                      child: Row(
                        children: [
                          Flexible(
                            child: Card(
                                //margin:const EdgeInsets.only(left: 20, right: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                color: getSelectedTimeSlotColor(index, slotsReservationsInfoFetchedAsMapWithData),
                                child: timesOfDayFetched.toList().isEmpty
                                    ? null
                                    : Center(
                                        child: (index + 1) == timesOfDayFetched.toList().length
                                            ? null
                                            : GridTile(
                                                child: Padding(
                                                  padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                                                  child: FittedBox(
                                                    alignment: Alignment.bottomCenter,
                                                    child: Text(
                                                        (index * 2) + 1 < timesOfDayFetched.length - 1
                                                            ? "${timesOfDayFetched.elementAt(index * 2).format(context)} - ${timesOfDayFetched.elementAt(index * 2 + 1).format(context)}"
                                                            : 'OK',
                                                        style: TextStyle(
                                                            color: context.watch<StateManagement>().selectedTime ==
                                                                    timesOfDayFetched.elementAt(index)
                                                                ? Colors.white
                                                                : Colors.black,
                                                            fontWeight: FontWeight.w400)),
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
              formatButtonTextStyle: TextStyle(fontSize: 10.0), titleTextStyle: TextStyle(fontSize: 11)),
          pageJumpingEnabled: true,
          startingDayOfWeek: StartingDayOfWeek.monday,
          focusedDay: focusedDay,
          firstDay: DateTime.now(),
          lastDay: DateTime(DateTime.now().year + 1),
          selectedDayPredicate: (day) {
            return isSameDay(selectedDay, day);
          },
          onDaySelected: (newSelectedDay, newFocusedDay) {
            debugPrint("BEFORE  SELECTED $selectedDay FOCUSED $focusedDay");
            setState(() {
              /*  (newSelectedDay.weekday == DateTime.sunday ||
                      newSelectedDay.weekday == DateTime.saturday)
                  ? null
                  : //I'LL SUPPOSE THE PARKINGS ARE OPEN EVERYDAY */

              selectedDay = DateTime(newSelectedDay.year, newSelectedDay.month, newSelectedDay.day, DateTime.now().hour,
                  DateTime.now().minute, DateTime.now().second);

              focusedDay = DateTime(newFocusedDay.year, newFocusedDay.month, newFocusedDay.day, DateTime.now().hour,
                  DateTime.now().minute, DateTime.now().second);
              //selectedDay.hour = DateTime.now().
              // update `_focusedDay` here as well
            });
            debugPrint("AFTERR SELECTED $selectedDay FOCUSED $focusedDay");
          },
          //STYLING OF CALENDAR
          calendarFormat: format,
          onFormatChanged: (newFormat) => setState(() {
            format = newFormat;
          }),
          calendarStyle: const CalendarStyle(
            //weekendDecoration: BoxDecoration(color: Colors.purple),
            selectedDecoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
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
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
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
                decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
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
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
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
            backgroundColor: MaterialStateProperty.all(const Color(0xff78909C))),
        onPressed: () {
          setState(() {
            nextPressedWithoutFirstPageAllInfoFetched = true;
          });
          var selectedVehiculeInfoEmptyTest =
              bookerFirstPageInfoMapped['Selected Vehicule Info'] as Map<String, dynamic>;
          selectedVehiculeInfoEmptyTest.isNotEmpty
              ? null
              : {
                  //

                  ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
                      onVisible: (() {}),
                      elevation: 10,
                      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 30),
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
                              color: Colors.white, fontSize: 15, fontFamily: 'OpenSans', fontWeight: FontWeight.w900),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              nextPressedWithoutFirstPageAllInfoFetched = false;
                            });
                            ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
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
            backgroundColor: MaterialStateProperty.all(const Color(0xff78909C))),
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
  bookerBody(double alleyListViewMinHeightToDisplay, TimeOfDay startTime, TimeOfDay endTime) {
    return Container(
      child: switchBookerBody(alleyListViewMinHeightToDisplay, startTime, endTime),
    );
  }

  // Returns the header text based on the activeStep.
  switchBookerBody(double alleyListViewMinHeightToDisplay, TimeOfDay startTime, TimeOfDay endTime) {
    switch (activeStep) {
      case 0:
        bookerFirstPageInfoMapped.addAll({
          'Selected Parking Name': linkedParkingNameAndInsideInfo['Parking Name'],
          'Selected Parking Fee / 30mns': insideParkingInfoFetched['Fee per 30 minutes'].toString(),
          'Selected Day': selectedDay,
          'Selected Vehicule Info': selectedVehiculeInfoMappedFromSelectVehicule
        });
        debugPrint(
            "Booker First Page INFO: $bookerFirstPageInfoMapped ___ normalSpotsTotal $regularTotal ___ specialsPOTS $specialTotal }");
        BookingOverviewFinal(bookerFirstPageInfoFetched: bookerFirstPageInfoMapped);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          nextPressedWithoutFirstPageAllInfoFetched == true && removeMaterialBannerSizedBox == false
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
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
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
                                scrollbarOrientation: ScrollbarOrientation.bottom,
                                thumbColor: Colors.blueGrey,
                                radius: const Radius.circular(20),
                                thumbVisibility: true,
                                trackVisibility: true,
                                controller: infoListViewController,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(0, 5, 0, 20),
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
                                            borderRadius: BorderRadius.circular(10.0),
                                          ),
                                          elevation: 5,
                                          child: Container(
                                            //THERE WAS AN EXPANDED HERE BEFORE CONTAINER
                                            // width: 115,
                                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(50)),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              crossAxisAlignment: CrossAxisAlignment.center,
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
                                                        fontWeight: FontWeight.w800,
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
                                                                      : index == 3
                                                                          ? mappedInfoFromWidget['Opening Hour']
                                                                          : mappedInfoFromWidget['Closing Hour'],

                                                                  style: const TextStyle(
                                                                    color: Colors.black87,
                                                                    fontSize: 13,
                                                                    fontFamily: 'OpenSans',
                                                                    fontWeight: FontWeight.w800,
                                                                  ),
                                                                )
                                                              : Row(
                                                                  children: [
                                                                    const Icon(Icons.accessible,
                                                                        color: Colors.blue, size: 15),
                                                                    Text(index == 0
                                                                        ? specialTotal.toString()
                                                                        : specialAvailableTotal
                                                                            .toString()), // for handicaped
                                                                    const SizedBox(
                                                                      width: 10,
                                                                    ),
                                                                    const Icon(Icons.not_accessible,
                                                                        color: Colors.blue, size: 15),
                                                                    Text(index == 0
                                                                        ? regularTotal.toString()
                                                                        : regularAvailableTotal
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
                        Icon(Icons.calendar_month_rounded, color: Colors.indigo),
                        SizedBox(width: 10),
                        Text(
                          'Select A Date',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
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
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  SelectVehicule(
                      currentlySIUser: currentlySignedInUser,
                      updateParkingDetailsAndSelectedDayMapped: fetchSelectedVehiculeInfo,
                      reShowSelectedCarCard: selectedVehiculeInfoMappedFromSelectVehicule.isEmpty ? false : true,
                      selectedCarDetails: selectedVehiculeInfoMappedFromSelectVehicule),
                ],
              ),
            ),
          )
        ]);

      case 1:
        debugPrint(
            "rAvailable $rAvailableIDs \t rBooked $rBookedIDs \t rOccupiedAfterBook $rOccupiedAfterBookedIDs \t SPECIAL rOccupiedNoPriorBooking $rOccupiedNoPriorBookingIDs \n sAvailable $sAvailableIDs \t sBooked $sBookedIDs \t sOccupiedAfterBooked $sOccupiedAfterBookedIDs \t sOccupiedNoPriorBooking $sOccupiedNoPriorBookingIDs \n specialTotal $specialTotal \t specialAvailableTotal $specialAvailableTotal \t regularTotal $regularTotal \t regularAvailableTotal $regularAvailableTotal \t totalParkingCapacity $totalParkingCapacity");

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection("slotsReservations").snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Text('');
              } else {
                slotsReservationsInfoFetchedList = snapshot.data!.docs;
                //slotsReservationsInfoFetchedAsMapWithData.addAll(slotsReservationsInfoFetchedList.);
                for (var element in slotsReservationsInfoFetchedList) {
                  slotsReservationsInfoFetchedAsMapWithData
                      .addAll({element.id: element.data()}); //lement id is key and value is the data
                }
                debugPrint("slotsReservationsInfoFetchedAsMap $slotsReservationsInfoFetchedAsMapWithData");
                fetchSlotReservationInfoFromFB(slotsReservationsInfoFetchedAsMapWithData);
                getAlleySlotsIdWithFBListeners(parkingSlotsTotal);

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
                                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 0, right: 10),
                                        width: 100,
                                        height: 78,
                                        child: Card(
                                          color: Colors.white,
                                          elevation: 5,
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(5, 5, 10, 5),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                //FRIST LINE
                                                Flexible(
                                                  child: SizedBox(
                                                    height: 15,
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Padding(
                                                          padding: const EdgeInsets.only(left: 4.0),
                                                          child: getParkingSpotIcon("legend", 'available'),
                                                        ),
                                                        const Flexible(
                                                          child: FittedBox(
                                                            child: Text(
                                                              "Available",
                                                              style:
                                                                  TextStyle(fontSize: 8, fontWeight: FontWeight.w500),
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
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Padding(
                                                          padding: const EdgeInsets.only(left: 4.0),
                                                          child: getParkingSpotIcon("legend", "booked"),
                                                        ),
                                                        const SizedBox(
                                                          width: 10,
                                                        ),
                                                        const Flexible(
                                                          child: FittedBox(
                                                            child: Text(
                                                              "Booked",
                                                              style:
                                                                  TextStyle(fontSize: 8, fontWeight: FontWeight.w500),
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
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        occupiedSpotIconLegend,
                                                        const SizedBox(
                                                          width: 10,
                                                        ),
                                                        const Flexible(
                                                          child: FittedBox(
                                                            child: Text(
                                                              "Occupied",
                                                              style:
                                                                  TextStyle(fontSize: 8, fontWeight: FontWeight.w500),
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
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Padding(
                                                          padding: const EdgeInsets.only(left: 3.0, bottom: 5),
                                                          child: getParkingSpotIcon("legend", 'accessible'),
                                                        ),
                                                        const Flexible(
                                                          child: FittedBox(
                                                            child: Text(
                                                              "Special",
                                                              style:
                                                                  TextStyle(fontSize: 8, fontWeight: FontWeight.w500),
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
                                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 0, right: 10),
                                        width: 100,
                                        height: 60,
                                        child: Card(
                                          color: Colors.white,
                                          elevation: 5,
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(5, 5, 10, 5),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                //FRIST LINE
                                                Flexible(
                                                  child: SizedBox(
                                                    height: 15,
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        getTimeSpotIcon('available'),
                                                        const Flexible(
                                                          child: FittedBox(
                                                            child: Text(
                                                              "Available",
                                                              style:
                                                                  TextStyle(fontSize: 8, fontWeight: FontWeight.w500),
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
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        getTimeSpotIcon('booked'),
                                                        const SizedBox(
                                                          width: 10,
                                                        ),
                                                        const Flexible(
                                                          child: FittedBox(
                                                            child: Text(
                                                              "Booked",
                                                              style:
                                                                  TextStyle(fontSize: 8, fontWeight: FontWeight.w500),
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
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Transform.rotate(
                                                            angle: 50.15, child: getTimeSpotIcon('occupied')),
                                                        const SizedBox(
                                                          width: 10,
                                                        ),
                                                        const Flexible(
                                                          child: FittedBox(
                                                            child: Text(
                                                              "Occupied",
                                                              style:
                                                                  TextStyle(fontSize: 8, fontWeight: FontWeight.w500),
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
                                timeSlotsGrid(startTime, endTime, slotsReservationsInfoFetchedAsMapWithData),

                                //test()
                              ]),
                            ),
                          ],
                        )),
                  ],
                );
              }
            });

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
                            color: Colors.white, fontSize: 20, fontFamily: 'OpenSans', fontWeight: FontWeight.w900),
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
                              style: TextStyle(fontSize: 12, color: Colors.red.shade400),
                            ))),
                        FittedBox(
                          child: TextButton(
                              onPressed: () {
                                Navigator.pop(context, 'show again');
                              },
                              child: const Text("OK", style: TextStyle(fontSize: 12))),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            )).then((value) {
      debugPrint("SHOW AGAIN OR NOT $value");
      value == 'do not show again'
          ? prefs.setBool("dontShowAlleyAlertAgain", true)
          : value == 'show again'
              ? {
                  prefs.setBool("dontShowAlleyAlertAgain", false),
                  setState(
                    () {
                      dontShowAlleyAlertAgainTemporairyly = true; //temporairement
                    },
                  )
                }
              : setState(() {
                  dontShowAlleyAlertAgainTemporairyly = false; //temporairement
                });
    });
  }

  Icon getParkingSpotIcon(String legendOrInsideSpot, String whichIcon) {
    // don't need to add spotOccupiedIcon because it is NOT an ICON but an IMAGE
    double? iconSize = legendOrInsideSpot == 'legend' ? 13 : 20;
    Icon spotBookedIcon = Icon(Icons.lock_clock_outlined, size: iconSize, color: Colors.orange.shade700),
        spotAvailableIcon = Icon(Icons.lock_open_outlined, color: Colors.green, size: iconSize),
        specialAccessIcon = Icon(Icons.accessible, color: Colors.blue, size: iconSize + 2);

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

  Map<String, dynamic> testconvertAllTimesOfDayFetched(
      Map<String, dynamic> testallBookedTimeSlotsInMinutes, Set<TimeOfDay> timesOfDayFetched) {
    Set<int> convertedTimesSet = {};
    Map<String, dynamic> correspondingStartandEndIndexes = {};

    for (var element in timesOfDayFetched) {
      convertedTimesSet.add((element.hour * 60 + element.minute) * 60);
    }

    for (var i = 0; i < testallBookedTimeSlotsInMinutes.length; i++) {
      var currentEntry = testallBookedTimeSlotsInMinutes.entries.elementAt(i);
      int firstMatchForStartIndex = 0, firstMatchForEndIndex = 0;
      for (int convertedIndex = 0; convertedIndex < convertedTimesSet.length - 1; convertedIndex++) {
        if (convertedTimesSet.elementAt(convertedIndex) <= currentEntry.value['BookingStart'] &&
            convertedTimesSet.elementAt(convertedIndex + 1) >= currentEntry.value['BookingStart']) {
          firstMatchForStartIndex = convertedIndex ~/ 2;
        }

        if (convertedTimesSet.elementAt(convertedIndex) <= currentEntry.value['BookingEnd'] &&
            convertedTimesSet.elementAt(convertedIndex + 1) > currentEntry.value['BookingEnd']) {
          firstMatchForEndIndex = convertedIndex ~/ 2;
        }

        correspondingStartandEndIndexes.addAll({
          testallBookedTimeSlotsInMinutes.keys.elementAt(i): {
            'startIndex': firstMatchForStartIndex,
            'endIndex': firstMatchForEndIndex
          }
        });
      }
    }

    debugPrint(
        "allBookedTimeSlotsInMinutes $testallBookedTimeSlotsInMinutes ____ correspondingIndexes $correspondingStartandEndIndexes ");
    return correspondingStartandEndIndexes;
  }

  void fetchSlotReservationInfoFromFB(Map<String, dynamic> slotsReservationsInfoFetchedAsMapWithData) {
    /* DateTime currentlySelectedDateForTimeSlotAvailability =
        bookerFirstPageInfoMapped['Selected Day'];
 */
    var sameDayReservationAsUserList = slotsReservationsInfoFetchedAsMapWithData.entries.where(
      (element) {
        var res = slotsReservationsInfoFetchedAsMapWithData.entries.where((element1) {
          var oj = element1.value as Map<String,
              dynamic>; //fetching all the timeSlots that are booked for the selectedDay if USER HAS NOT CLICKED YET ON ANY PARKING SPOT
          var timeST = oj['BookingStart'] as Timestamp;
          return timeST.toDate().day == selectedDay.day &&
              timeST.toDate().month == selectedDay.month &&
              timeST.toDate().year == selectedDay.year &&
              oj['ParkingID'] == widget.receivedID;
        });
        return res.any((element2) => element2.key == element.key);
      },
    );

    for (var singleReservationSameDayAsUserSelectedDay in sameDayReservationAsUserList) {
      var singleReservationNoKeyCasted = singleReservationSameDayAsUserSelectedDay.value as Map<String, dynamic>;
      var singleBookingStartTimeStamp = singleReservationNoKeyCasted['BookingStart'] as Timestamp;
      var singleBookingEndTimeStamp = singleReservationNoKeyCasted['BookingEnd'] as Timestamp;

      allReservationsSameDaySameParkingWithKey
          .addAll({singleReservationSameDayAsUserSelectedDay.key: singleReservationNoKeyCasted});
      debugPrint("singleReservationNoKeyCasted $singleReservationNoKeyCasted");

      testallBookedTimeSlots.addAll({
        singleReservationSameDayAsUserSelectedDay.key: {
          'BookingStart': TimeOfDay.fromDateTime(singleBookingStartTimeStamp.toDate()),
          'BookingEnd': TimeOfDay.fromDateTime(singleBookingEndTimeStamp.toDate()),
        }
      });
      int bookedTimeStartInt = (TimeOfDay.fromDateTime(singleBookingStartTimeStamp.toDate()).hour * 60 +
                  TimeOfDay.fromDateTime(singleBookingStartTimeStamp.toDate()).minute) *
              60,
          bookedTimeEndInt = (TimeOfDay.fromDateTime(singleBookingEndTimeStamp.toDate()).hour * 60 +
                  TimeOfDay.fromDateTime(singleBookingEndTimeStamp.toDate()).minute) *
              60;
      testallBookedTimeSlotsInMinutes.addAll({
        singleReservationSameDayAsUserSelectedDay.key: {
          'BookingStart': bookedTimeStartInt,
          'BookingEnd': bookedTimeEndInt,
        }
      });
      debugPrint("testallBookedTimeSlotsInMinutes $testallBookedTimeSlotsInMinutes");
    }
  }

  Iterable<MapEntry<String, dynamic>> getWithinXHoursAvailabalitySatus(int availabilityHoursInterval) {
    int selectedDayPlusXHourToInt = ((selectedDay.hour + availabilityHoursInterval) * 60 + selectedDay.minute) * 60,
        selectedDayToInt = ((selectedDay.hour) * 60 + selectedDay.minute) * 60;

    var work = allReservationsSameDaySameParkingWithKey.entries.where((entry) {
      var matchingTimeStampEntry = testallBookedTimeSlotsInMinutes.entries.where((element) => element.key == entry.key);
      var matchingTSEntryFinal = matchingTimeStampEntry.first.value as Map<String, dynamic>;
      return matchingTSEntryFinal['BookingStart'] >= selectedDayToInt &&
              matchingTSEntryFinal['BookingStart'] <= selectedDayPlusXHourToInt ||
          matchingTSEntryFinal['BookingEnd'] >= selectedDayToInt &&
              matchingTSEntryFinal['BookingEnd'] <= selectedDayPlusXHourToInt;
    });

    return work;
  }

  batchWriteInsideParkingInfo() async {
    currentlySignedInUser = firebaseService.auth.currentUser;
    CollectionReference collectionRef = myDB.collection("locations/${widget.receivedID}/insideParkingInfo");
    WriteBatch batch = myDB.batch();

    batch.set(
      collectionRef.doc(),
      {
        'Fee per 30 minutes': 500,
        'Special': {
          'Available': {
            'IDs': ['A3', 'B6'],
            'Total': 2
          },
          'Booked': {'IDs': [], 'Total': 0},
          'Occupied': {
            'From Real Parking': {
              'IDs': ['B4', 'B5'],
              'Total': 2
            },
            'From Booking': {'IDs': [], 'Total': 0},
          },
          'Total': 4,
        },
        'Regular': {
          'Available': {
            'IDs': ['A0', 'A1', 'A2', 'A4', 'B0', 'B2', 'B3'],
            'Total': 7
          },
          'Booked': {
            'IDs': ['B1'],
            'Total': 1
          },
          'Occupied': {
            'From Real Parking': {
              'IDs': ['A6', 'A5'],
              'Total': 2
            },
            'From Booking': {'IDs': [], 'Total': 0},
          },
          'Total': 10,
        },
        'Total': 14
      },
    );

    await batch.commit().whenComplete(() => debugPrint("SUCCESSFULLY WRITTEN INSIDE PARKING TO FIREBASE"));
  }

  void fetchParkingSlotsInfoFromFB() {
    if (insideParkingInfoFetched.isNotEmpty) {
      var cast1 = insideParkingInfoFetched['Regular']['Available'] as Map<String, dynamic>;
      var castedRAvailableSlotsItems = cast1['IDs'] as List;
      rAvailableIDs.addAll(castedRAvailableSlotsItems);

      var cast2 = insideParkingInfoFetched['Regular']['Booked'] as Map<String, dynamic>;
      var castedRBookedSlotsList = cast2['IDs'] as List;
      rBookedIDs.addAll(castedRBookedSlotsList);

      var cast3 = insideParkingInfoFetched['Regular']['Occupied'] as Map<String, dynamic>;

      var cast31 = cast3['From Booking'] as Map<String, dynamic>;
      var castedROccupiedAfterBook = cast31['IDs'] as List;
      rOccupiedAfterBookedIDs.addAll(castedROccupiedAfterBook);

      var cast32 = cast3['From Real Parking'] as Map<String, dynamic>;
      var castedROccupiedNoPriorBooking = cast32['IDs'] as List;
      rOccupiedNoPriorBookingIDs.addAll(castedROccupiedNoPriorBooking);

      var cast4 = insideParkingInfoFetched['Special']['Available'] as Map<String, dynamic>;
      var castedSAvailable = cast4['IDs'] as List;
      sAvailableIDs.addAll(castedSAvailable);

      var cast5 = insideParkingInfoFetched['Special']['Booked'] as Map<String, dynamic>;
      var castedSBookedSlotsList = cast5['IDs'] as List;
      sBookedIDs.addAll(castedSBookedSlotsList);

      var cast6 = insideParkingInfoFetched['Special']['Occupied'] as Map<String, dynamic>;

      var cast61 = cast6['From Booking'] as Map<String, dynamic>;
      var castedSOccupiedAfterBook = cast61['IDs'] as List;
      sOccupiedAfterBookedIDs.addAll(castedSOccupiedAfterBook);

      var cast62 = cast6['From Real Parking'] as Map<String, dynamic>;
      var castedSOccupiedNoPriorBooking = cast62['IDs'] as List;
      sOccupiedNoPriorBookingIDs.addAll(castedSOccupiedNoPriorBooking);

      allSpecialSpotsIDs = [sBookedIDs, sAvailableIDs, sOccupiedAfterBookedIDs, sOccupiedNoPriorBookingIDs]
          .expand((element) => element)
          .toSet();

      allRegularSpotsID = [
        rBookedIDs,
        rAvailableIDs,
        rOccupiedAfterBookedIDs,
        rOccupiedNoPriorBookingIDs,
        sBookedIDs,
      ].expand((element) => element).toSet();

      specialTotal = allSpecialSpotsIDs.length;
      specialAvailableTotal = sAvailableIDs.length;
      regularTotal = allRegularSpotsID.length;
      regularAvailableTotal = rAvailableIDs.length;
      totalParkingCapacity = insideParkingInfoFetched['Total'];
    }
    debugPrint(
        "rAvailable $rAvailableIDs \t rBooked $rBookedIDs \t rOccupiedAfterBook $rOccupiedAfterBookedIDs \t SPECIAL rOccupiedNoPriorBooking $rOccupiedNoPriorBookingIDs \n sAvailable $sAvailableIDs \t sBooked $sBookedIDs \t sOccupiedAfterBooked $sOccupiedAfterBookedIDs \t sOccupiedNoPriorBooking $sOccupiedNoPriorBookingIDs \n specialTotal $specialTotal \t specialAvailableTotal $specialAvailableTotal \t regularTotal $regularTotal \t regularAvailableTotal $regularAvailableTotal \t totalParkingCapacity $totalParkingCapacity");
  }

  void createAlleysMappingWithIDs(int alleyBindexStart, int j) {
    for (var i = 0; i < parkingSlotsTotal; i++) {
      (i < parkingSlotsTotal ~/ 2)
          ? {
              alleyA.add("A$i"),
              mappedSelectedSlotAlley.add({
                "alleyA_Id": alleyA.elementAt(i) /* "A$i" */,
                "isSlotSelected": false,
                "isSlotBooked": rBookedIDs.contains("A$i") || sBookedIDs.contains("A$i") ? true : false,
                "isSlotOccupied": {
                  'AfterBooked':
                      rOccupiedAfterBookedIDs.contains("A$i") || sOccupiedAfterBookedIDs.contains("A$i") ? true : false,
                  'NoPriorBooking':
                      rOccupiedNoPriorBookingIDs.contains("A$i") || sOccupiedNoPriorBookingIDs.contains("A$i")
                          ? true
                          : false,
                },
                "isSlotFree": rAvailableIDs.contains("A$i") || sAvailableIDs.contains("A$i") ? true : false,
                "isSpecialSpot": allSpecialSpotsIDs.contains("A$i") ? true : false,
                "isBookedWithinXHours": withinXHoursParkingSpotIDsToShow.values.contains("A$i") ? true : false,
                "highlightColor": Colors.transparent
              })
            }
          : {
              alleyB.add("B${j++}"),
              mappedSelectedSlotAlley.add({
                "alleyB_Id": alleyB
                    .elementAt(i - alleyBindexStart), //3 because at this point, i = 3 and I need the counter to reset
                "isSlotSelected": false,
                "isSlotBooked":
                    rBookedIDs.contains("B${i - alleyBindexStart}") || sBookedIDs.contains("B${i - alleyBindexStart}")
                        ? true
                        : false,
                "isSlotOccupied": {
                  'AfterBooked': rOccupiedAfterBookedIDs.contains("B${i - alleyBindexStart}") ||
                          sOccupiedAfterBookedIDs.contains("B${i - alleyBindexStart}")
                      ? true
                      : false,
                  'NoPriorBooking': rOccupiedNoPriorBookingIDs.contains("B${i - alleyBindexStart}") ||
                          sOccupiedNoPriorBookingIDs.contains("B${i - alleyBindexStart}")
                      ? true
                      : false,
                },
                "isSlotFree": rAvailableIDs.contains("B${i - alleyBindexStart}") ||
                        sAvailableIDs.contains("B${i - alleyBindexStart}")
                    ? true
                    : false,
                "isSpecialSpot": allSpecialSpotsIDs.contains("B${i - alleyBindexStart}") ? true : false,
                "isBookedWithinXHours":
                    withinXHoursParkingSpotIDsToShow.values.contains("B${i - alleyBindexStart}") ? true : false,

                "highlightColor": Colors.transparent
              })
            };
    }

    debugPrint("ALLEY A : $alleyA ______________ ALLEY B : $alleyB");
    debugPrint("mappedAlleysAndSlotIdsStatus : \t $mappedSelectedSlotAlley ");
    mappedAlleysAndSlotIds.addAll({
      'Alley A': alleyA,
      'Alley B': alleyB,
    });
  }
} //CLSOGIN BRACKS

//
class DashedSeparatedBordersPainterLTRB extends CustomPainter {
  bool left = false, top = false, right = false, bottom = false;

  DashedSeparatedBordersPainterLTRB(this.left, this.top, this.right, this.bottom);

  void drawDashedLeftBorder(Canvas canvas, Size size, Paint paint, int dashWidth, int dashSpace, double paintStartXmin,
      double paintStartYmax) {
    double startX = paintStartXmin;
    double y = size.height; //final destination
    while (y > paintStartYmax) {
      canvas.drawLine(Offset(startX, y), Offset(startX, y - dashWidth), paint);
      y -= dashWidth + dashSpace;
    }
  }

  void drawDashedTopBorder(Canvas canvas, Size size, Paint paint, int dashWidth, int dashSpace, double paintStartXmin,
      double paintStartYmax) {
    double startX = paintStartXmin;
    double y = paintStartYmax;
    while (startX < size.width) {
      // Draw a small line.
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), paint);
      // Update the starting X
      startX += dashWidth + dashSpace;
    }
  }

  void drawDashedRightBorder(
      Canvas canvas, Size size, Paint paint, int dashWidth, int dashSpace, double paintStartYmax) {
    double startX = size.width;
    double y = size.height; //final destination
    while (y > paintStartYmax) {
      canvas.drawLine(Offset(startX, y), Offset(startX, y - dashWidth), paint);
      y -= dashWidth + dashSpace;
    }
  }

  void drawDashedBottomBorder(Canvas canvas, Size size, Paint paint, int dashWidth, int dashSpace,
      double paintStartXmin, double paintStartYmin) {
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
        ? drawDashedLeftBorder(canvas, size, paint, dashWidth, dashSpace, paintStartXmin, paintStartYmax)
        : null;

    top == true ? drawDashedTopBorder(canvas, size, paint, dashWidth, dashSpace, paintStartXmin, paintStartYmax) : null;
    right == true ? drawDashedRightBorder(canvas, size, paint, dashWidth, dashSpace, paintStartYmax) : null;

    bottom == true
        ? drawDashedBottomBorder(canvas, size, paint, dashWidth, dashSpace, paintStartXmin, paintStartYmin)
        : null;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
