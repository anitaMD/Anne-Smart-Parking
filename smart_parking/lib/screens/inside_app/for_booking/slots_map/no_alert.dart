// ignore_for_file: prefer_typing_uninitialized_variables, avoid_function_literals_in_foreach_calls, unused_local_variable
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_parking/screens/inside_app/for_booking/booking_overview.dart';
import 'package:smart_parking/screens/inside_app/for_booking/slots_map/select_vehicule.dart';
import 'package:smart_parking/screens/inside_app/home.dart';
import 'package:smart_parking/services/firebase/firebase_service.dart';
import 'package:smart_parking/services/firebase/firestore_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_parking/notifiers/booking_state_management.dart';
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
  var firestoreWalletService = FirestoreWalletService();
  User? currentlySignedInUser;
  int parkingSlotsTotal = 10;
  late String parkingNameToolBar, walletCollId = '', insideParkingInfoDocIDNeeded = '';
  String tappedOnAlley = '', previouslySelectedParkingSpotID = '';
  double alleyHeight = 200,
      singleSpotHeight = 50,
      singleSpotWidth = 120,
      spaceBetweenSlots = 35.0,
      alleySpotWidthRatio = 1 / 4;
  bool isSelected = false, anyReservationForSelectedDay = false;

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
  List<int> allDisabledTimeRangeIndexesForTimeSelection = [], outOfXhoursRangeIndexes = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> slotsReservationsInfoFetchedList = [];
  Map<String, dynamic> linkedParkingNameAndInsideInfo = {},
      insideParkingInfoFetched = {},
      bookerFirstPageInfoMapped = {},
      bookerTimeAndSpotInfoMapped = {'Selected Parking Spot': '', 'Selected Time Interval': ''},
      selectedVehiculeInfoMappedFromSelectVehicule = {},
      slotsReservationsInfoFetchedAsMapWithData = {};
  Map<String, Set> mappedAlleysAndSlotIds = {};
  late Map<String, dynamic> mappedInfoFromWidget = {};
  Map<String, dynamic> correspondingStartandEndIndexes = {};
  List<Map<String, dynamic>> withinXHoursParkingSpotInfosNeeded = [], allHoursParkingSpotInfosNeeded = [];
  bool test = true, rebuildIDLists = false;

//RESERVATION VARS
  bool isReservationDayPicked = false,
      isReservationStartTimePicked = false,
      isReservationDurationPicked = false,
      firstTimeAskingForDateSelect = true,
      nextPressedWithoutFirstPageAllInfoFetched = false,
      removeMaterialBannerSizedBox = false,
      reShowSelectedCarCard = false,
      dontShowAlleyAlertAgainTemporairyly = false,
      updatedClosingAndOpening = false,
      doDisplayAvailabilityForWholeDay = false;

  Set rAvailableIDs = {},
      rOccupiedAfterBookedIDs = {},
      rOccupiedNoPriorBookingIDs = {},
      rBookedIDs = {},
      sAvailableIDs = {},
      sOccupiedAfterBookedIDs = {},
      sOccupiedNoPriorBookingIDs = {},
      sBookedIDs = {},
      allSpecialSpotsIDs = {},
      allRegularSpotsID = {},
      allConvertedTimesOfDayToInt = {},
      allFinallyBookedIndexes = {};

  int specialTotal = 0,
      specialAvailableTotal = 0,
      regularTotal = 0,
      regularAvailableTotal = 0,
      totalParkingCapacity = 0,
      previouslyReachedStep = 0,
      stopClearing = 0;

  //OccupiedNoPriorBooking for cars parked onlhy by interacting with the real parking and didn't use the app to book like taxis or whatever
  List<Set<String>> spotIDsWithinXHoursList = [],
      spotIDsWithinXHoursBookedNotOccupied = [],
      allSpotIDsAllHoursBookedNotOccupied =
          []; //do not delete any because will need to update an eventuel is booking over value
  List indexesToDisplayWithnXHours = [];

//BOOKER

  Map<String, dynamic> testallBookedTimeSlotsInMinutes = {};
  Set<TimeOfDay> allBookedTimeSlots = {};
  Map<String, dynamic> testallBookedTimeSlots = {},
      allReservationsSameDaySameParkingWithKey = {},
      allReservationsExistingSameTimeAsNowDifferentDay = {};
  TimeOfDay selectedBookingEndTimeFromTSGrid = TimeOfDay.now(), selectedBookingStartTimeFromTSGrid = TimeOfDay.now();
  TimeRange finallyBookedTimeRange =
      TimeRange(startTime: const TimeOfDay(hour: 00, minute: 00), endTime: const TimeOfDay(hour: 01, minute: 00));
  Set<TimeOfDay> timesOfDayFetched = {};
  CalendarFormat format = CalendarFormat.week;
  Duration interval = const Duration(minutes: 30);
  DateTime selectedDay = DateTime.now(), focusedDay = DateTime.now(), previouslySelectedDay = DateTime.now();
  Color selectedTimeSlotColor = Colors.blueGrey.shade500;
  ScrollController singleChildController = ScrollController(),
      leftAlleyController = ScrollController(),
      rightAlleyController = ScrollController(),
      timeSlotGridController = ScrollController(),
      infoListViewController = ScrollController(),
      bodyScrollBarController = ScrollController();
  int activeStep = 0,
      upperBound = 2,
      stop = 0,
      selectedDayIndex = 0,
      selectedDayPlusXHourToIntIndex = 0,
      tappedOnParkingSpotID = 0,
      selectedDayPlusXHourToInt = 0,
      selectedDayToInt = 0; //do not remove any of these
  var timeSlotAvailable = {}, timeSlotCurrentlyOccupied = {}, timeSlotbooked = {};
  num bookingTotalNum = 0;
  int bookingTotalToPay = 0, clearOutOfXrange = 0;

  @override
  void dispose() {
    infoListViewController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    currentlySignedInUser = firebaseService.auth.currentUser;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
    //getAlleySlotsId(parkingSlotsTotal);
    // batchWriteInsideParkingInfo(18);
    var ok = widget.mappedParkingsGeneralInfo[widget.receivedID] as Map<String, dynamic>;
    mappedInfoFromWidget.addAll(ok);
    setState(
      () {
        parkingNameToolBar = ok['Name'];
        debugPrint("NAMEMA ${widget.receivedID}");
      },
    );

    fetchParkingSlotsInfoFromFB();
    myDB.collection("users/${currentlySignedInUser?.uid}/wallet").get().then((value) async {
      debugPrint("THE BALANCE : ${value.docs.first.data()['Balance'].runtimeType} ___ $bookingTotalToPay");
      setState(() {
        walletCollId = value.docs.first.id;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var totalBookingDuration = (finallyBookedTimeRange.endTime.hour * 60 + finallyBookedTimeRange.endTime.minute) -
        (finallyBookedTimeRange.startTime.hour * 60 + finallyBookedTimeRange.startTime.minute);
    String durationToString(int minutes) {
      var d = Duration(minutes: minutes);
      List<String> parts = d.toString().split(':');
      return '${parts[0].padLeft(2, '0')}h ${parts[1].padLeft(2, '0')}mn';
    }

    var totalBookingDurationMinutePart =
        int.parse(durationToString(totalBookingDuration).split(' ').last.substring(0, 2));

    /* debugPrint("WIDGET MAPPED! $mappedInfoFromWidget _ $focusedDay");
    debugPrint("nextPressedWithoutFirstPageAllInfoFetched $nextPressedWithoutFirstPageAllInfoFetched"); */
    currentlySignedInUser = firebaseService.auth.currentUser;
    debugPrint("SIGNED IN CURRENTLY ${firebaseService.auth.currentUser?.uid.toString()}");
    double alleyListViewMinHeightToDisplay =
        alleyHeight + (spaceBetweenSlots * (parkingSlotsTotal ~/ (parkingSlotsTotal ~/ 2) - 1));

    var stateManagerRead = context.read<BookingStateManagement>();

    debugPrint(
        "OK LISTENING: ${stateManagerRead.updateOpeningAndClosingHours(mappedInfoFromWidget['Opening Hour'], mappedInfoFromWidget['Closing Hour'])} __________ ${context.watch<BookingStateManagement>().openingHour} ______ ${context.watch<BookingStateManagement>().closingHour}");
    //TIMESLOTSELECTION
    TimeOfDay startTime = TimeOfDay(
            hour: int.parse(context.watch<BookingStateManagement>().openingHour.split(":")[0]),
            minute: int.parse(context.watch<BookingStateManagement>().openingHour.split(":")[1])),
        endTime = TimeOfDay(
            hour: int.parse(context.watch<BookingStateManagement>().closingHour.split(":")[0]),
            minute: int.parse(context.watch<BookingStateManagement>().closingHour.split(":")[1]));

    debugPrint("OK LISTENING TIME OF  DAY $startTime ___ $endTime");
    stateManagerRead.getTimeSlotsIntervals(startTime, endTime, interval).toList().then((value) {
      debugPrint("OK LISTENING LIST $value   ___ \t stop $stop");
      stop < 2
          ? setState(() {
              timesOfDayFetched.clear;
              timesOfDayFetched.addAll(value);
              context.read<BookingStateManagement>().timeSlotsParsed = value;
            })
          : null;

      debugPrint(
          "VOIR $timesOfDayFetched ____ context.readtimeSlotsParsed ${context.read<BookingStateManagement>().timeSlotsParsed}");
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
    if (insideParkingInfoFetched.isNotEmpty) {
      bookingTotalNum = totalBookingDurationMinutePart < 30
          ? (totalBookingDuration ~/ 30 * insideParkingInfoFetched['Fee per 30 minutes']) +
              ((totalBookingDurationMinutePart * insideParkingInfoFetched['Fee per 30 minutes']) ~/ 30)
          : totalBookingDurationMinutePart > 30
              ? (totalBookingDuration ~/ 30 * insideParkingInfoFetched['Fee per 30 minutes']) +
                  (((totalBookingDurationMinutePart - 30) * insideParkingInfoFetched['Fee per 30 minutes']) ~/ 30)
              : totalBookingDuration ~/ 30 * insideParkingInfoFetched['Fee per 30 minutes'];
    }
    bookingTotalToPay = int.parse(bookingTotalNum.toString());

    return Scaffold(
      backgroundColor: activeStep != 2 ? Theme.of(context).scaffoldBackgroundColor : Colors.blueGrey,
      appBar: activeStep != 2
          ? AppBar(
              bottomOpacity: 0.0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => activeStep != 2
                    ? Navigator.of(context).pop()
                    : setState(() {
                        activeStep -= 1;
                      }),
              ),
              toolbarHeight: activeStep != 2 ? 90 : 50,
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
                activeStep != 2
                    ? Flexible(
                        child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              previousButton(),
                              bookingIconStepper(),
                              nextButton(),
                            ],
                          ),
                          widget.mappedParkingsGeneralInfo.isNotEmpty
                              ? FittedBox(
                                  child: Text(
                                    /* activeStep == 2 ? "Your Booking Overview" :  */ parkingNameToolBar,
                                    style: const TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                )
                              : const Text("LOADING"),
                        ],
                      ))
                    : Container(),
              ],
              backgroundColor: Colors.blueGrey,
            )
          : null,
      bottomNavigationBar: activeStep == 2
          ? BottomAppBar(
              color: Colors.white.withOpacity(0.6),
              elevation: 1,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.only(
                      top: 5,
                      right: 15,
                    ),
                    height: 70,
                    width: MediaQuery.of(context).size.width * 0.6,
                    //color: Colors.transparent,
                    child: Column(
                      children: [
                        const FittedBox(
                          child: Text(
                            'TOTAL',
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'OpenSans',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text("$bookingTotalToPay CFA",
                              style: const TextStyle(
                                color: Colors.black,
                                fontFamily: 'OpenSans',
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              )),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15)),
                      ),
                      width: MediaQuery.of(context).size.width - MediaQuery.of(context).size.width * 0.6,
                      height: 70,
                      child: Material(
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                        color: Colors.orange,
                        child: InkWell(
                          highlightColor: Colors.red,
                          borderRadius:
                              const BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15)),
                          onTap: () async {
                            /*        var bookingStartDate = Timestamp.fromDate(DateTime(
                                    selectedDay.year,
                                    selectedDay.month,
                                    selectedDay.day,
                                    finallyBookedTimeRange.startTime.hour,
                                    finallyBookedTimeRange.startTime.minute))
                                .toDate();
                            var timeUntilResStarts = (bookingStartDate.difference(DateTime.now())).inSeconds;
                            debugPrint("TIME UNTIL RES BOOK OVERV :$timeUntilResStarts"); */
                            await myDB
                                .collection("users/${currentlySignedInUser?.uid}/wallet")
                                .get()
                                .then((value) async {
                              debugPrint(
                                  "THE BALANCE : ${value.docs.first.data()['Balance'].runtimeType} ___ $bookingTotalToPay");
                              setState(() {
                                walletCollId = value.docs.first.id;
                              });

                              value.docs.first.data()['Balance'] >= bookingTotalToPay
                                  ? stateManagerRead.updateBuildingBookingText('Registering your booking...')
                                  : stateManagerRead.updateBuildingBookingText(
                                      "Seems like you don't have enough SMP. \n Please top up to validate your booking.'");
                            }).whenComplete(() => checkWallet(bookingTotalToPay, stateManagerRead));
                            debugPrint("HERE IT IS THE SPOT ${bookerTimeAndSpotInfoMapped['Selected Parking Spot']}");

                            if (stateManagerRead.buildingBookingText == 'Registering your booking...') {
                              await createBookingItem(
                                  linkedParkingNameAndInsideInfo['Parking Name'],
                                  widget.receivedID,
                                  currentlySignedInUser,
                                  selectedVehiculeInfoMappedFromSelectVehicule,
                                  finallyBookedTimeRange,
                                  selectedDay);
                              await firestoreWalletService
                                  .debitAfterBooking(currentlySignedInUser, walletCollId, bookingTotalToPay,
                                      widget.receivedID, linkedParkingNameAndInsideInfo['Parking Name'])
                                  .whenComplete(() => updateParkingSpotsAvailability(
                                      bookerTimeAndSpotInfoMapped['Selected Parking Spot']));

                              var theDocToUpdate =
                                  myDB.collection("users/${currentlySignedInUser?.uid}/wallet").doc(walletCollId);
                              finallyBookedTimeRange.startTime;

                              debugPrint("THEDOCTOUPDATE ${theDocToUpdate.id}");
                              listeningToDebitsRT(theDocToUpdate);
                              var bookingStartDate = Timestamp.fromDate(DateTime(
                                      selectedDay.year,
                                      selectedDay.month,
                                      selectedDay.day,
                                      finallyBookedTimeRange.startTime.hour,
                                      finallyBookedTimeRange.startTime.minute))
                                  .toDate();
                              var timeUntilResStarts = (bookingStartDate.difference(DateTime.now())).inSeconds;
                              debugPrint("TIME UNTIL RES BOOK OVERV :$timeUntilResStarts");
                              Future.delayed(const Duration(seconds: 20));
                              if (!mounted) return;
                              Navigator.pop(context);
                              redirectingAlert();
                              Future.delayed(const Duration(seconds: 4)).then((value) {
                                if (mounted) {
                                  return Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (context) => Home(
                                            fromLoginView: true,
                                            parkingToNavigateTo: const {},
                                            newIndex: 0,
                                            timeUntilResStarts: timeUntilResStarts)),
                                  );
                                }
                              });
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(25),
                            child: FittedBox(
                                child: Text('BOOK NOW',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontFamily: 'OpenSans',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ))),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
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
                    //String source = snapshot.data!.metadata.hasPendingWrites ? "Local" : "Server";
                    // insideParkingInfoFetched.clear();
                    insideParkingInfoFetched = snapshot.data!.docs[0].data(); //PUT BACK 0
                    insideParkingInfoDocIDNeeded = snapshot.data!.docs[0].id;

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
                            .first
                            .toString()
                            .substring(1);
//come back here and put whatever as Map<String, dynamic> and treat the data isntead of splitting
                        linkedParkingNameAndInsideInfo
                            .addAll({'Parking Name': currentlySelectedParkingsName, 'Info': insideParkingInfoFetched});
                      }
                    }
                    parkingSlotsTotal = insideParkingInfoFetched["Total"];
                    fetchParkingSlotsInfoFromFB(); //do not remove
                    //allListeners();
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

  getSelectedTimeSlotColor(int index, Map<String, dynamic> slotsReservationsInfoFetchedAsMapWithData) {
    bool displayOccupiedIcon =
        sOccupiedNoPriorBookingIDs.isNotEmpty || rOccupiedNoPriorBookingIDs.isNotEmpty ? true : false;

    Map<String, dynamic> bookedIntervalsSlotColor =
        testconvertAllTimesOfDayFetched(testallBookedTimeSlotsInMinutes, timesOfDayFetched);
    Set timeSlotCardBookedIndex = <int>{};

    for (var element in bookedIntervalsSlotColor.values) {
      debugPrint("bookedIntervalsSlotColor : $element");
      index >= element['startIndex'] && index <= element['endIndex'] ? timeSlotCardBookedIndex.add(index) : null;
    }

    debugPrint(
        " getSelectedTimeSlotColorTest ${bookedIntervalsSlotColor.values} __ $indexesToDisplayWithnXHours _____ $withinXHoursParkingSpotInfosNeeded ");
    //debugPrint("VOILA ${mappedSelectedSlotAlley.elementAt(index ~/ 2)}");
    if (withinXHoursParkingSpotInfosNeeded.isNotEmpty) {
      debugPrint("CHACHACHA $withinXHoursParkingSpotInfosNeeded");
      /*  for (var element in withinXHoursParkingSpotInfosNeeded) {d
        var one = element.values.last as List; //the indexes in question
        indexesToDisplayWithnXHours.add(one);
      } */
    } else {
      indexesToDisplayWithnXHours.clear();
    }
    debugPrint(
        "getSelectedTimeSlotColor indexesToDisplayWithnXHours: $indexesToDisplayWithnXHours _ selectedDayToInt ${(selectedDay.hour * 60 + selectedDay.minute) * 60}");

    if (selectedDay.year == DateTime.now().year &&
        selectedDay.month == DateTime.now().month &&
        selectedDay.day > DateTime.now().day) {
      allDisabledTimeRangeIndexesForTimeSelection.clear();
      outOfXhoursRangeIndexes.clear();

      return Container();
    }
    //
    else {
      if (selectedDayPlusXHourToInt <= allConvertedTimesOfDayToInt.last) {
        if (indexesToDisplayWithnXHours.isNotEmpty) {
          //if left sup closing time basically, show normal indexes that are still within X hours of the currentTime but also within parking closing time
          clearOutOfXrange < 1 ? {outOfXhoursRangeIndexes.clear(), clearOutOfXrange += 1} : null;
          index > selectedDayPlusXHourToIntIndex ? outOfXhoursRangeIndexes.add(index) : null;
          outOfXhoursRangeIndexes = outOfXhoursRangeIndexes.toSet().toList();
          debugPrint(
              "FETCHING OUTOFXRANGE INDEXES(indexesToDisplayWithnXHours NOTempty) _______ $outOfXhoursRangeIndexes");
          var itdwxh = indexesToDisplayWithnXHours.any((element) {
            element as List;
            return index >= element.first;
          });
          if (mappedSelectedSlotAlley.any((element) =>
                  element['isSlotOccupied']['NoPriorBooking'] == true &&
                  (index >= selectedDayIndex &&
                      allConvertedTimesOfDayToInt.elementAt(index * 2) <= selectedDayToInt &&
                      allConvertedTimesOfDayToInt.elementAt((index * 2) + 1) >
                          selectedDayToInt /* &&
                      itdwxh == true */
                  )) ==
              true) {
            // debugPrint("OUIOUI");
            return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              //booked for certain parking spots and occuiped for others
              getTimeSpotIcon('occupied'), const SizedBox(width: 5), getTimeSpotIcon('booked'),

              // getTimeSpotIcon('available'),
            ]);
          }

          if (indexesToDisplayWithnXHours.any((element) {
                element as List;
                return index >= element.first &&
                    index <= element.last &&
                    index >= selectedDayIndex &&
                    index <= selectedDayPlusXHourToIntIndex;
              }) ==
              true) {
            return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              //booked and available for certain parking spots
              getTimeSpotIcon('booked'),
              const SizedBox(width: 5),
              getTimeSpotIcon('available'),
            ]);
          }

          /*  if (indexesToDisplayWithnXHours.any((element) {
                element as List;
                return index >= element.first &&
                        index <= element.last &&
                        index >= selectedDayIndex &&
                        index <= selectedDayPlusXHourToIntIndex ||
                    index >= element.first && index <= element.last && index >= selectedDayIndex;
              }) ==
              true) {
            return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              getTimeSpotIcon('booked'),
              getTimeSpotIcon('available'),
            ]);
          } */

          if (indexesToDisplayWithnXHours.any((element) {
                element as List;
                index < selectedDayIndex ? allDisabledTimeRangeIndexesForTimeSelection.add(index) : null;
                return index < selectedDayIndex;
              }) ==
              true) {
            return getTimeSpotIcon('unbookable');
          }
        }
        if (indexesToDisplayWithnXHours.isEmpty) {
          debugPrint(
              "FETCHING OUTOFXRANGE INDEXES(indexesToDisplayWithnXHours empty) _______ $outOfXhoursRangeIndexes ");

          //indexesToDisplayWithnXHours.isEmpty
          index < selectedDayIndex ? allDisabledTimeRangeIndexesForTimeSelection.add(index) : null;
          index > selectedDayPlusXHourToIntIndex ? outOfXhoursRangeIndexes.add(index) : null;
          outOfXhoursRangeIndexes = outOfXhoursRangeIndexes.toSet().toList();
          //debugPrint("THESE OUT OF RANGE INDEXES $index _________ $outOfXhoursRangeIndexes");
          return index < selectedDayIndex
              ? getTimeSpotIcon('unbookable')
              : index > selectedDayPlusXHourToIntIndex
                  ? getTimeSpotIcon('outOfXHours')
                  : getTimeSpotIcon('available');
        }
      } //
      else {
        //EVERYTHING ORNAGE WILL BE RELATED TO CURRENTLY BOOKEDNOTOCCUPED PLACES so only need THAT and unbookable.Everything else gree is FREE until the parking closes in less than 3 hours
        //debugPrint("YOU'RE HERE HAHA $selectedDayPlusXHourToInt _ ${allConvertedTimesOfDayToInt.last}");
        if (indexesToDisplayWithnXHours.isNotEmpty) {
          return indexesToDisplayWithnXHours.any((element) {
                    element as List;
                    index >= selectedDayIndex == false ? allDisabledTimeRangeIndexesForTimeSelection.add(index) : null;
                    return index >= element.first && index <= element.last && index >= selectedDayIndex;
                  }) ==
                  true
              ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  //booked for certain parking spots and occuiped for others
                  getTimeSpotIcon('booked'), const SizedBox(width: 5),
                  sAvailableIDs.isNotEmpty == true || rAvailableIDs.isNotEmpty == true
                      ? getTimeSpotIcon('available')
                      : Container(),
                  /* const SizedBox(width: 5),
                  rOccupiedNoPriorBookingIDs.isNotEmpty == true || sOccupiedNoPriorBookingIDs.isNotEmpty == true
                      ? getTimeSpotIcon('occupied')
                      : Container(), */

                  // getTimeSpotIcon('available'),
                ])
              : getTimeSpotIcon('unbookable');
        } else {
          index < selectedDayIndex ? allDisabledTimeRangeIndexesForTimeSelection.add(index) : null;
          debugPrint("STILL HERE __ $index __ $selectedDayIndex");
          index >= selectedDayIndex
              ? getTimeSpotIcon('available')
              /* : displayOccupiedIcon == true && index == selectedDayIndex
                  ? getTimeSpotIcon('occupied') */
              : getTimeSpotIcon('unbookable');
        }
      }
    }

    debugPrint(
        "THESE ARE HE INDEXES $selectedDayPlusXHourToInt ____${allConvertedTimesOfDayToInt.last} _____ $outOfXhoursRangeIndexes");
    selectedDayPlusXHourToInt <= allConvertedTimesOfDayToInt.last &&
            index < selectedDayPlusXHourToIntIndex &&
            indexesToDisplayWithnXHours.isNotEmpty
        ? null //check indexesToDisplayWithnXHours.isNotEmpty
        : selectedDayPlusXHourToInt > allConvertedTimesOfDayToInt.last &&
                index < selectedDayPlusXHourToIntIndex &&
                indexesToDisplayWithnXHours.isEmpty
            ? {
                outOfXhoursRangeIndexes.add(index),
                outOfXhoursRangeIndexes = outOfXhoursRangeIndexes.toSet().toList(),
                debugPrint("OUTOFXRANGE INDEXES $index _________ $outOfXhoursRangeIndexes"),
              }
            : null;
    return selectedDayPlusXHourToInt <= allConvertedTimesOfDayToInt.last &&
            index < selectedDayPlusXHourToIntIndex &&
            indexesToDisplayWithnXHours.isNotEmpty
        ? getTimeSpotIcon('available')
        : outOfXhoursRangeIndexes.isEmpty && index >= selectedDayIndex
            ? getTimeSpotIcon('available')
            : outOfXhoursRangeIndexes.isEmpty && index < selectedDayIndex
                ? getTimeSpotIcon('unbookable')
                : getTimeSpotIcon('outOfXHoursRange'); //

    /*   ? Colors.orange
                    : Colors.white; */

    /*  :  */ //ADD IF PARKING SPOT IS SELECTED TOO
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
                  setState(() {
                    doDisplayAvailabilityForWholeDay = true;
                    tappedOnParkingSpotID = i;
                    tappedOnAlley = 'alleyA';
                    previouslySelectedParkingSpotID = 'A$i';
                  });
                  context.read<BookingStateManagement>().updateSelectedTime(const TimeOfDay(hour: 0, minute: 0));

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
                                          child: rOccupiedAfterBookedIDs.contains("A$i") ||
                                                  sOccupiedAfterBookedIDs.contains("A$i")
                                              ? const Icon(Icons.time_to_leave, color: Colors.red, size: 20)
                                              : rOccupiedNoPriorBookingIDs.contains("A$i") ||
                                                      sOccupiedNoPriorBookingIDs.contains("A$i")
                                                  ? occupiedSpotIconLegend
                                                  : sAvailableIDs.contains("A$i") || rAvailableIDs.contains("A$i")
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
                  setState(() {
                    doDisplayAvailabilityForWholeDay = true;
                    tappedOnParkingSpotID = i;
                    tappedOnAlley = 'alleyB';
                    previouslySelectedParkingSpotID = 'B$i';
                  });
                  context.read<BookingStateManagement>().updateSelectedTime(const TimeOfDay(hour: 0, minute: 0));
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
                                              ? const Icon(Icons.time_to_leave, color: Colors.red, size: 20)
                                              : rOccupiedNoPriorBookingIDs.contains("B$i") ||
                                                      sOccupiedNoPriorBookingIDs.contains("B$i")
                                                  ? occupiedSpotIconLegend
                                                  : sAvailableIDs.contains("B$i") || rAvailableIDs.contains("B$i")
                                                      ? getParkingSpotIcon("insideSpot", 'available')
                                                      : getParkingSpotIcon("insideSpot", 'booked'),
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
    listeningToInsideParkingRealTime();
    int alleyBindexStart = parkingSlotsTotal ~/ 2;
    var j = 0;
    fetchParkingSlotsInfoFromFB();
    createAlleysMappingWithIDs(alleyBindexStart, j);
    debugPrint("mappedAlleysAndSlotIds : $mappedAlleysAndSlotIds");
  }

  insideParkingLayout(double alleyListViewMinHeightToDisplay) {
    double kindaWorkingContainerHeightForAlleys = ((parkingSlotsTotal ~/ 2) - 0.5) * 80;
    //debugPrint("kindaWorkingContainerHeightForAlleys $kindaWorkingContainerHeightForAlleys");
    return GestureDetector(
      onVerticalDragStart: (details) {
        debugPrint("VERTICAL DRAG START");
        setState(() {
          previouslyReachedStep = 5;
        }); //just cto not have 2 for spot booking part
      },
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
      Map<String, dynamic> slotsReservationsInfoFetchedAsMapWithData, Set<int> timeSlotsDisabled) async {
    await showDialog(
        context: context,
        builder: (context) {
          TimeOfDay startTime = TimeOfDay.now();
          TimeOfDay endTime = TimeOfDay.now();

          selectedBookingStartTimeFromTSGrid = timesOfDayFetched.elementAt(index * 2);
          selectedBookingEndTimeFromTSGrid = TimeOfDay(
              hour: timesOfDayFetched.elementAt(index * 2 + 1).hour,
              minute: timesOfDayFetched.elementAt(index * 2 + 1).minute); //if error, put both = TimeOfDay.now
          return AlertDialog(
            scrollable: true,
            contentPadding: EdgeInsets.zero,
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            //  title: const Text("Choose a nice timeframe"),
            content: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 400,
                child: TimeRangePicker(
                    hideButtons: true,
                    onStartChange: (p0) {
                      setState(() {
                        selectedBookingStartTimeFromTSGrid = p0;
                      });
                    },
                    onEndChange: (p0) {
                      setState(() {
                        selectedBookingEndTimeFromTSGrid = p0;
                      });
                      debugPrint("THE CHANGE $p0 _____ $selectedBookingEndTimeFromTSGrid");
                    },
                    minDuration: const Duration(minutes: 30),
                    handlerRadius: 7,
                    start: timesOfDayFetched.elementAt(index * 2).hour == TimeOfDay.now().hour &&
                            timesOfDayFetched.elementAt(index * 2).minute < TimeOfDay.now().minute
                        ? TimeOfDay.now()
                        : timesOfDayFetched.elementAt(index * 2), //FROM
                    //
                    end: timesOfDayFetched.elementAt(index * 2).hour == TimeOfDay.now().hour &&
                            timesOfDayFetched.elementAt(index * 2).minute < TimeOfDay.now().minute
                        ? TimeOfDay(
                            hour: TimeOfDay.now().minute + 30 >= 60 ? TimeOfDay.now().hour + 1 : TimeOfDay.now().hour,
                            minute: TimeOfDay.now().minute + 30 >= 60
                                ? TimeOfDay.now().minute + 30 - 60
                                : TimeOfDay.now().minute + 30)
                        : TimeOfDay(
                            hour: timesOfDayFetched.elementAt(index * 2 + 1).hour,
                            minute: timesOfDayFetched.elementAt(index * 2 + 1).minute), //TO
                    //
                    disabledTime: selectedDay.year == DateTime.now().year &&
                            selectedDay.month == DateTime.now().month &&
                            selectedDay.day == DateTime.now().day
                        ? TimeRange(
                            startTime: TimeOfDay(
                                hour: parkingClosingHour.minute == 0
                                    ? parkingClosingHour.hour - 1
                                    : parkingClosingHour.hour,
                                minute: parkingClosingHour.minute == 0 ? 55 : parkingClosingHour.minute - 5),
                            endTime: timesOfDayFetched.elementAt(index * 2).hour == TimeOfDay.now().hour &&
                                    timesOfDayFetched.elementAt(index * 2).minute < TimeOfDay.now().minute
                                ? TimeOfDay.now()
                                : TimeOfDay(
                                    hour: timesOfDayFetched.elementAt(index * 2).hour,
                                    minute: timesOfDayFetched.elementAt(index * 2).minute),
                          )
                        : TimeRange(
                            startTime: TimeOfDay(
                                hour: parkingClosingHour.minute == 0
                                    ? parkingClosingHour.hour - 1
                                    : parkingClosingHour.hour,
                                minute: parkingClosingHour.minute == 0 ? 55 : parkingClosingHour.minute - 5),
                            endTime: parkingOpeningHour),
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
                    padding: 35)),
            actions: <Widget>[
              TextButton(
                  child: const Text('CANCEL'),
                  onPressed: () {
                    Navigator.of(context).pop(TimeRange(
                        startTime: const TimeOfDay(hour: 0, minute: 0), endTime: const TimeOfDay(hour: 0, minute: 05)));
                  }),
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  debugPrint(
                      "selectedBookingStartTimeFromTSGrid $selectedBookingStartTimeFromTSGrid   selectedBookingENDTimeFromTSGrid $selectedBookingEndTimeFromTSGrid");
                  var selectedEndIndex = timesOfDayFetched
                          .toList()
                          .indexWhere((element) => element == selectedBookingEndTimeFromTSGrid),
                      selectedStartIndex = timesOfDayFetched
                          .toList()
                          .indexWhere((element) => element == selectedBookingStartTimeFromTSGrid);
                  int matchingStartIndexForTSGrid = selectedStartIndex ~/ 2,
                      matchingEndIndexForTSGrid = selectedEndIndex ~/ 2;
                  debugPrint(
                      "selectedStartIndex $selectedStartIndex \t selecteEndIndex $selectedEndIndex __ $index _ matchingStar : $matchingStartIndexForTSGrid matchingEnd $matchingEndIndexForTSGrid");

                  if (selectedStartIndex >= 0 &&
                      selectedStartIndex > index * 2 &&
                      matchingStartIndexForTSGrid >= index &&
                      selectedBookingStartTimeFromTSGrid == timesOfDayFetched.elementAt((selectedStartIndex)) &&
                      matchingStartIndexForTSGrid != matchingEndIndexForTSGrid) {
                    //if the selectedTimeIsIndeedInTheListOftIMeperiodsfetched, I have to check if that selectedTime is selectable. Can't book starting the endtimeof a slotinterval and a=can't end starting the timeofday of next slotinterval
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: Colors.black.withOpacity(0.7),
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 50),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                      behavior: SnackBarBehavior.floating,
                      elevation: 15,
                      //margin: EdgeInsets.only(bottom: 100, left: 30, right: 30),
                      content: FittedBox(
                        child: Text(/* ${TimeOfDay.now().hour}:${TimeOfDay.now().minute} and  */
                            "Please Select A Time Start Past ${timesOfDayFetched.elementAt(selectedStartIndex).format(context)}."),
                      ),
                    ));
                  } else if (selectedEndIndex >= 0 &&
                      selectedEndIndex > index * 2 &&
                      matchingEndIndexForTSGrid > index &&
                      selectedBookingEndTimeFromTSGrid == timesOfDayFetched.elementAt((selectedEndIndex)) &&
                      timesOfDayFetched.elementAt(selectedEndIndex + 1).minute -
                              selectedBookingEndTimeFromTSGrid.minute !=
                          5 &&
                      timesOfDayFetched.elementAt(selectedEndIndex) !=
                          TimeOfDay(
                              hour: parkingClosingHour.minute == 0
                                  ? parkingClosingHour.hour - 1
                                  : parkingClosingHour.hour,
                              minute: parkingClosingHour.minute == 0 ? 55 : parkingClosingHour.minute - 5)) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: Colors.black.withOpacity(0.7),
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                      behavior: SnackBarBehavior.floating,
                      elevation: 15,
                      //margin: EdgeInsets.only(bottom: 100, left: 30, right: 30),
                      content: FittedBox(
                        child: Text(/* ${TimeOfDay.now().hour}:${TimeOfDay.now().minute} and  */
                            "Please Select An End Time Before ${timesOfDayFetched.elementAt(selectedEndIndex).format(context)}."),
                      ),
                    ));
                  } else {
                    Navigator.of(context).pop(TimeRange(
                        startTime: selectedBookingStartTimeFromTSGrid, endTime: selectedBookingEndTimeFromTSGrid));
                  }
                },
              ),
            ],
          );
        }).then((value) {
      debugPrint("BOOKINGTIMESELCTIONSTATUS $value");
      int valueStartToInt, valueEndToInt;
      value == null
          ? debugPrint("VALUE IS NULL")
          : {
              value as TimeRange,
              value.startTime.hour == 00
                  ? null
                  : {
                      allFinallyBookedIndexes.clear(),
                      valueStartToInt = (value.startTime.hour * 60 + value.startTime.minute) * 60,
                      valueEndToInt = (value.endTime.hour * 60 + value.endTime.minute) * 60,
                      allConvertedTimesOfDayToInt.forEach(
                        (element) {
                          //to chaneg the color of the selected timeranges based on the finallybookedtimerange
                          var theindexindex;
                          element >= valueStartToInt && element < valueEndToInt
                              ? {
                                  theindexindex = allConvertedTimesOfDayToInt
                                      .toList()
                                      .indexWhere((element1) => element1 == element),
                                  allFinallyBookedIndexes.add(theindexindex)
                                }
                              : null;
                        },
                      ),
                      bookerTimeAndSpotInfoMapped.update('Selected Time Interval', (timeslot) => value),
                      setState(
                        () {
                          finallyBookedTimeRange = value;
                        },
                      )
                    },
              debugPrint("allFinallyBookedIndexes $allFinallyBookedIndexes"),
            };
    });
  }

  timeSlotsGrid(
      TimeOfDay startTime, TimeOfDay endTime, Map<String, dynamic> slotsReservationsInfoFetchedAsMapWithData) {
    Set<int> timeSlotsDisabled = allDisabledTimeRangeIndexesForTimeSelection.toSet();
    debugPrint("GOT THIS ${allDisabledTimeRangeIndexesForTimeSelection.toSet()}");
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
                  itemCount: timesOfDayFetched.toList().isEmpty ? 10 : ((timesOfDayFetched.toList().length - 1) ~/ 2),

                  ///becaause I used two items per bloc
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      childAspectRatio: 1.5, crossAxisSpacing: 10, mainAxisSpacing: 15, crossAxisCount: 3),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () async {
                        //don't change
                        //debugPrint("MAMAMA ${focusedDay.hour}");
                        timeSlotsDisabled.contains(index)
                            ? ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Sorry, time interval already in the past!"),
                                ),
                              )
                            : outOfXhoursRangeIndexes.contains(index)
                                ? ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: Colors.black.withOpacity(0.7),
                                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 50),
                                      shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.all(Radius.circular(20))),
                                      behavior: SnackBarBehavior.floating,
                                      elevation: 15,
                                      //margin: EdgeInsets.only(bottom: 100, left: 30, right: 30),
                                      content: const FittedBox(
                                        child: Text(
                                            "Please select a parking spot to see the \navailability status for this time interval. "),
                                      ),
                                    ),
                                  )
                                /* : mappedSelectedSlotAlley.any((element) =>
                                            element['isSlotOccupied']['NoPriorBooking'] == true &&
                                            index >= selectedDayIndex &&
                                            allConvertedTimesOfDayToInt.elementAt(index * 2) <= selectedDayToInt &&
                                            allConvertedTimesOfDayToInt.elementAt((index * 2) + 1) >=
                                                selectedDayToInt) ==
                                        true
                                    ? ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        backgroundColor: Colors.black.withOpacity(0.7),
                                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 50),
                                        shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(20))),
                                        behavior: SnackBarBehavior.floating,
                                        elevation: 15,
                                        //margin: EdgeInsets.only(bottom: 100, left: 30, right: 30),
                                        content: FittedBox(
                                          child: Text(/* ${TimeOfDay.now().hour}:${TimeOfDay.now().minute} and  */
                                              "Please select a time interval past ${timesOfDayFetched.elementAt((index * 2) + 1).format(context)}."),
                                        ),
                                      )) */
                                : {
                                    context
                                        .read<BookingStateManagement>()
                                        .updateSelectedTime(timesOfDayFetched.elementAt(index)),
                                    showUserRangePicker(index, endTime, startTime,
                                        slotsReservationsInfoFetchedAsMapWithData, timeSlotsDisabled)
                                  };
                      },
                      child: Row(
                        children: [
                          Flexible(
                            child: Card(
                                elevation: allDisabledTimeRangeIndexesForTimeSelection.toSet().contains(index)
                                    ? 25
                                    : outOfXhoursRangeIndexes.toSet().contains(index)
                                        ? 28
                                        : 20,
                                //margin:const EdgeInsets.only(left: 20, right: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                color: context.watch<BookingStateManagement>().selectedTime ==
                                            timesOfDayFetched.elementAt(index) &&
                                        allFinallyBookedIndexes.isEmpty
                                    ? selectedTimeSlotColor
                                    : allFinallyBookedIndexes.any((element) => element ~/ 2 == index) == true
                                        ? selectedTimeSlotColor
                                        : /* previouslyReachedStep == 1 && anyReservationForSelectedDay == true //when there is no reservation for the day selected
                                            ? Colors.yellow
                                            :  */
                                        allDisabledTimeRangeIndexesForTimeSelection.toSet().contains(index)
                                            ? Colors.purple.withOpacity(0.3)
                                            : outOfXhoursRangeIndexes.toSet().contains(index) &&
                                                    doDisplayAvailabilityForWholeDay == false
                                                ? Colors.white.withOpacity(0.5)
                                                : Colors.white,
                                /*  doDisplayAvailabilityForWholeDay == true
                                    ? displayAvailabilityForWholeDay(tappedOnParkingSpotID, "tappedOnAlley", index)
                                    : getSelectedTimeSlotColor(index, slotsReservationsInfoFetchedAsMapWithData), */
                                child: timesOfDayFetched.toList().isEmpty
                                    ? null
                                    : Center(
                                        child: (index * 2 + 1) == timesOfDayFetched.toList().length
                                            ? null
                                            : Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Flexible(
                                                    child: GridTile(
                                                      child: Padding(
                                                        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                                                        child: FittedBox(
                                                          alignment: Alignment.bottomCenter,
                                                          child: Text(
                                                              (index * 2) + 1 < timesOfDayFetched.length - 1
                                                                  ? "${timesOfDayFetched.elementAt(index * 2).format(context)} - ${timesOfDayFetched.elementAt(index * 2 + 1).format(context)}"
                                                                  : 'OK',
                                                              style: TextStyle(
                                                                  color: /* context
                                                                                  .watch<StateManagement>()
                                                                                  .selectedTime ==
                                                                              timesOfDayFetched.elementAt(index) || */
                                                                      allFinallyBookedIndexes.any(
                                                                                  (element) => element ~/ 2 == index) ==
                                                                              true
                                                                          ? Colors.white
                                                                          : Colors.black,
                                                                  fontWeight: FontWeight.w400)),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  doDisplayAvailabilityForWholeDay == true
                                                      ? displayAvailabilityForWholeDay(
                                                          tappedOnParkingSpotID, tappedOnAlley, index)
                                                      : getSelectedTimeSlotColor(
                                                          index, slotsReservationsInfoFetchedAsMapWithData),
                                                ],
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
    debugPrint(
        "THAT'S SELECTED $selectedDay ${TimeOfDay(hour: int.parse(context.read<BookingStateManagement>().closingHour.split(":")[0]), minute: int.parse(context.read<BookingStateManagement>().closingHour.split(":")[1])).hour}");
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
            var ok = (DateTime(newSelectedDay.year, newSelectedDay.month, newSelectedDay.day, TimeOfDay.now().hour,
                TimeOfDay.now().minute));
            debugPrint("PEPS $ok");

            ok.year == DateTime.now().year &&
                    ok.month == DateTime.now().month &&
                    ok.day == DateTime.now().day &&
                    ok.hour ==
                        TimeOfDay(
                                hour: int.parse(context.read<BookingStateManagement>().closingHour.split(":")[0]),
                                minute: int.parse(context.read<BookingStateManagement>().closingHour.split(":")[1]))
                            .hour
                ? {
                    debugPrint(
                        "IS SUPERIOR _ $ok  ${newSelectedDay.hour}__ ${TimeOfDay(hour: int.parse(context.read<BookingStateManagement>().closingHour.split(":")[0]), minute: int.parse(context.read<BookingStateManagement>().closingHour.split(":")[1])).hour}"),
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Sorry, we're closed for the day!"),
                      ),
                    )
                  }
                /*  (newSelectedDay.weekday == DateTime.sunday || 
                      newSelectedDay.weekday == DateTime.saturday)
                  ? null
                  : //I'LL SUPPOSE THE PARKINGS ARE OPEN EVERYDAY */

                : setState(() {
                    selectedDay = DateTime(newSelectedDay.year, newSelectedDay.month, newSelectedDay.day,
                        DateTime.now().hour, DateTime.now().minute, DateTime.now().second);
                    focusedDay = DateTime(newFocusedDay.year, newFocusedDay.month, newFocusedDay.day,
                        DateTime.now().hour, DateTime.now().minute, DateTime.now().second);

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

  bookingIconStepper() {
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
          onStepReached: (index) {}),
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
            stopClearing = 0;
          });

          debugPrint("PREVIOUSLY REACHED SETp: $previouslyReachedStep");

          if (previouslyReachedStep == 1) {
            // allDisabledTimeRangeIndexesForTimeSelection.clear();
            outOfXhoursRangeIndexes.clear();
            allFinallyBookedIndexes.clear();
            context.read<BookingStateManagement>().updateSelectedTime(const TimeOfDay(hour: 0, minute: 0));
            var ok =
                mappedSelectedSlotAlley.where((element) => element.values.first == previouslySelectedParkingSpotID);
            debugPrint("PREVIOUSLY ONPRESSED SELECTED PARKING spot: $ok");
            ok.forEach(
              (element) {
                element.update('isSlotSelected', (value) => false);
                element.update('highlightColor', (value) => Colors.transparent);
              },
            );
            refreshSlotColorState(Colors.transparent);
          }

          var selectedVehiculeInfoEmptyTest =
              bookerFirstPageInfoMapped['Selected Vehicule Info'] as Map<String, dynamic>;
          selectedVehiculeInfoEmptyTest.isNotEmpty
              ? null
              : {
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
          var ok = (DateTime(
              selectedDay.year, selectedDay.month, selectedDay.day, TimeOfDay.now().hour, TimeOfDay.now().minute));
          var selectedParkingSpotWithTimeSlot;
          debugPrint("CHECKING $allFinallyBookedIndexes");

          activeStep < upperBound && selectedVehiculeInfoEmptyTest.isNotEmpty
              ? ok.year == DateTime.now().year &&
                      ok.month == DateTime.now().month &&
                      ok.day == DateTime.now().day &&
                      ok.hour >=
                          TimeOfDay(
                                  hour: int.parse(context.read<BookingStateManagement>().closingHour.split(":")[0]),
                                  minute: int.parse(context.read<BookingStateManagement>().closingHour.split(":")[1]))
                              .hour
                  ? ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Sorry, we're closed for the day!"),
                      ),
                    )
                  : allFinallyBookedIndexes.isNotEmpty &&
                          mappedSelectedSlotAlley.where((element) => element['isSlotSelected'] == true).isEmpty
                      ? {
                          showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  content: SingleChildScrollView(
                                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
                                    Text(
                                        "As you have not selected a specific parking spot, you will be assigned a random available one. ")
                                  ])),
                                  actions: [
                                    TextButton(
                                        onPressed: () {
                                          Navigator.pop(context, 'GO BACK');
                                        },
                                        child: FittedBox(
                                            child: Text(
                                          "GO BACK",
                                          style: TextStyle(fontSize: 12, color: Colors.red.shade400),
                                        ))),
                                    FittedBox(
                                      child: TextButton(
                                          onPressed: () {
                                            Navigator.pop(context, 'PROCEED');
                                          },
                                          child: const Text("PROCEED", style: TextStyle(fontSize: 12))),
                                    ),
                                  ],
                                );
                              }).then((value) {
                            //  final randomSpot = Random();
                            value == null || value == 'GO BACK'
                                ? null
                                : {
                                    bookerTimeAndSpotInfoMapped.update(
                                        'Selected Parking Spot', (value) => (sAvailableIDs.toList()..shuffle()).first),
                                    setState(() {
                                      activeStep += 1;
                                    })
                                  };
                          }),
                        }
                      : allFinallyBookedIndexes.isNotEmpty &&
                              mappedSelectedSlotAlley.where((element) => element['isSlotSelected'] == true).isNotEmpty
                          ? {
                              debugPrint(
                                  "SELECTED IS HERE ${mappedSelectedSlotAlley.where((element) => element['isSlotSelected'] == true).first.values.first}"),
                              bookerTimeAndSpotInfoMapped.update(
                                  'Selected Parking Spot',
                                  (value) => mappedSelectedSlotAlley
                                      .where((element) => element['isSlotSelected'] == true)
                                      .first
                                      .values
                                      .first),
                              setState(() {
                                activeStep += 1;
                              })
                            }
                          : activeStep == 1 &&
                                  allFinallyBookedIndexes.isEmpty &&
                                  (selectedDay.year == DateTime.now().year &&
                                      selectedDay.month == DateTime.now().month &&
                                      selectedDay.day == DateTime.now().day)
                              ? {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Select at least a time interval to proceed."),
                                    ),
                                  )
                                }
                              : setState(() {
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
                  previouslyReachedStep = activeStep;
                  previouslySelectedDay = selectedDay;

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
        debugPrint("CHECKING AGAIN :$selectedVehiculeInfoMappedFromSelectVehicule");
        bookerFirstPageInfoMapped.addAll({
          'Selected Parking Name': linkedParkingNameAndInsideInfo['Parking Name'],
          'Selected Parking Fee / 30mns': insideParkingInfoFetched['Fee per 30 minutes'].toString(),
          'Selected Day': selectedDay,
          'Selected Vehicule Info': selectedVehiculeInfoMappedFromSelectVehicule
        });
        /*  debugPrint(
            "Booker First Page INFO: $bookerFirstPageInfoMapped ___ normalSpotsTotal $regularTotal ___ specialsPOTS $specialTotal }"); */
        BookingOverviewFinal(
            bookerFirstPageInfoFetched: bookerFirstPageInfoMapped,
            bookerSecondPageInfoFetched: bookerTimeAndSpotInfoMapped);
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
        outOfXhoursRangeIndexes.clear();
        //fetchParkingSlotsInfoFromFB();
        debugPrint(
            "rAvailable $rAvailableIDs \t rBooked $rBookedIDs \t rOccupiedAfterBook $rOccupiedAfterBookedIDs \t SPECIAL rOccupiedNoPriorBooking $rOccupiedNoPriorBookingIDs \n sAvailable $sAvailableIDs \t sBooked $sBookedIDs \t sOccupiedAfterBooked $sOccupiedAfterBookedIDs \t sOccupiedNoPriorBooking $sOccupiedNoPriorBookingIDs \n specialTotal $specialTotal \t specialAvailableTotal $specialAvailableTotal \t regularTotal $regularTotal \t regularAvailableTotal $regularAvailableTotal \t totalParkingCapacity $totalParkingCapacity");
        slotsReservationsInfoFetchedAsMapWithData.isNotEmpty == true
            ? slotsReservationsInfoFetchedAsMapWithData.clear
            : null;
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection("slotsReservations").snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Text('');
              } else {
                slotsReservationsInfoFetchedAsMapWithData.isNotEmpty == true
                    ? slotsReservationsInfoFetchedAsMapWithData.clear
                    : null;
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
                    GestureDetector(
                      //ADD A TOGGLE SWITCH TO SHOW WITHIN XHOURS AVAILABILITY OR NOT. that wil handle the tap and vertical drag issues
                      onVerticalDragStart: (details) {},
                      onTap: () {
                        debugPrint("TOGGLE tap HERE");
                        Iterable<Map<String, dynamic>> ok = {};
                        mappedSelectedSlotAlley.isNotEmpty
                            ? {
                                ok = mappedSelectedSlotAlley
                                    .where((element) => element.values.first == previouslySelectedParkingSpotID),
                                debugPrint("PREVIOUSLY ONPRESSED SELECTED PARKING spot: $ok"),
                                ok.forEach(
                                  (element) {
                                    element.update('isSlotSelected', (value) => false);
                                    element.update('highlightColor', (value) => Colors.transparent);
                                  },
                                ),
                                refreshSlotColorState(Colors.transparent),
                                setState(() {
                                  doDisplayAvailabilityForWholeDay = false;
                                })
                              }
                            : {};
                        /*  debugPrint("PREVIOUSLY CILOUMN SELECTED PARKING spot: $ok");
                        ok.isNotEmpty
                            ? {
                                ok.update('isSlotSelected', (value) => false),
                                ok.update('highlightColor', (value) => Colors.transparent),
                                setState(() => doDisplayAvailabilityForWholeDay = false),
                              }
                            : null;

                        refreshSlotColorState(Colors.transparent); */
                      },
                      child: Padding(
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
                                        /*   Row(
                                          children: [
                                            Container(
                                              child: ToggleSwitch(
                                                customWidths: [100.0, 50.0],
                                                cornerRadius: 20.0,
                                                activeBgColors: [
                                                  [Colors.indigo],
                                                  [Colors.redAccent]
                                                ],
                                                customTextStyles: [
                                                  TextStyle(
                                                    fontSize: 10,
                                                  )
                                                ],
                                                activeFgColor: Colors.white,
                                                inactiveBgColor: Colors.grey,
                                                inactiveFgColor: Colors.white,
                                                totalSwitches: 2,
                                                labels: [
                                                  'Availability \n until ${selectedDay.hour + 3}:${selectedDay.minute}',
                                                  ''
                                                ],
                                                icons: [null, Icons.do_not_disturb_alt_sharp],
                                                onToggle: (index) {
                                                  debugPrint('switched to: $index');
                                                },
                                              ),
                                            )
                                          ],
                                        )
                                      */
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(top: 0, right: 10),
                                          width: 100,
                                          height: 70,
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
                                                      height: 10,
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
                                                      height: 10,
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
                                                      height: 10,
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          getTimeSpotIcon('occupied'),
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
                                                      height: 10,
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          getTimeSpotIcon('unbookable'),
                                                          const SizedBox(
                                                            width: 10,
                                                          ),
                                                          const Flexible(
                                                            child: FittedBox(
                                                              child: Text(
                                                                "Disabled",
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
                    )
                  ],
                );
              }
            });

      case 2: /* First Page INFO: $bookerFirstPageInfoMapped ___ */
        debugPrint("Booker  SECOND PAGE $bookerTimeAndSpotInfoMapped }");
        return Container(
          color: Colors.blueGrey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.only(top: 40),
                    child: IconButton(
                      alignment: Alignment.center,
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: 25,
                      ),
                      onPressed: () => activeStep != 2
                          ? Navigator.of(context).pop()
                          : setState(() {
                              activeStep -= 1;
                            }),
                    ),
                  ),
                  /*   Flexible(
                    child: const FittedBox(
                      child: Text(
                        "BOOKING OVERVIEW",
                        style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 40),
                      ),
                    ),
                  ),
               */
                ],
              ),
              BookingOverviewFinal(
                  bookerFirstPageInfoFetched: bookerFirstPageInfoMapped,
                  bookerSecondPageInfoFetched: bookerTimeAndSpotInfoMapped),
            ],
          ), //const Text('VEHICLE SELECT CAR OR MOTORCYCLE'),
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
                  : status == 'booked'
                      ? Colors.orange.shade700
                      : status == 'unbookable'
                          ? Colors.purple.shade700
                          : Colors.white, //for unbookable as it's already past datetime.now
          shape: BoxShape.circle),
    );
  }

  Map<String, dynamic> testconvertAllTimesOfDayFetched(
      Map<String, dynamic> testallBookedTimeSlotsInMinutes, Set<TimeOfDay> timesOfDayFetched) {
    selectedDay.year == previouslySelectedDay.year &&
            selectedDay.month == previouslySelectedDay.month &&
            selectedDay.day == previouslySelectedDay.day
        ? null
        : {
            stopClearing < 1
                ? {
                    testallBookedTimeSlots.clear(),
                    testallBookedTimeSlotsInMinutes.clear(),
                    spotIDsWithinXHoursBookedNotOccupied.clear(),
                    stopClearing += 1
                  }
                : null
          };

    Set<int> convertedTimesSet = {};
    for (var element in timesOfDayFetched) {
      convertedTimesSet.add((element.hour * 60 + element.minute) * 60);
    }
    allConvertedTimesOfDayToInt = convertedTimesSet;
    for (var i = 0; i < convertedTimesSet.length - 1; i++) {
      int selectedDayToInt = (selectedDay.hour * 60 + selectedDay.minute) * 60;
      convertedTimesSet.elementAt(i) < selectedDayToInt && convertedTimesSet.elementAt(i + 1) > selectedDayToInt
          ? selectedDayIndex = (i + 1) ~/ 2
          : null;
      convertedTimesSet.elementAt(i) < selectedDayPlusXHourToInt &&
              convertedTimesSet.elementAt(i + 1) > selectedDayPlusXHourToInt
          ? selectedDayPlusXHourToIntIndex = (i + 1) ~/ 2
          : null;
    }
    testallBookedTimeSlotsInMinutes.isEmpty ? correspondingStartandEndIndexes.clear() : null;
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
    debugPrint(
        "convertedTimesSet $convertedTimesSet \t ${(selectedDay.hour * 60 + selectedDay.minute) * 60} __ selectedDayiNDEX $selectedDayIndex");

    return correspondingStartandEndIndexes;
  }

  void fetchSlotReservationInfoFromFB(Map<String, dynamic> slotsReservationsInfoFetchedAsMapWithData) {
    /* DateTime currentlySelectedDateForTimeSlotAvailability =
        bookerFirstPageInfoMapped['Selected Day'];
 */
    var allReservationsOnSelectedDayList = slotsReservationsInfoFetchedAsMapWithData.entries.where(
      (element) {
        var res = slotsReservationsInfoFetchedAsMapWithData.entries.where((element1) {
          var oj = element1.value as Map<String, dynamic>; //fetching all the timeSlots that are booked for all parkings
          //debugPrint("OJ $oj");
          var timeST = oj['BookingStart'] as Timestamp;
          return timeST.toDate().day == selectedDay.day &&
              timeST.toDate().month == selectedDay.month &&
              timeST.toDate().year == selectedDay.year &&
              oj['ParkingID'] ==
                  widget
                      .receivedID; //CHECKING all the timeSlots for the selectedDay if USER HAS NOT CLICKED YET ON ANY PARKING SPOT && for the current parking only
        });
        /*   res.any((element2) => element2.key == element.key);
        debugPrint("RES IS: $res"); */
        return res.any((element2) => element2.key == element.key);
      },
    );
    allReservationsOnSelectedDayList.isEmpty
        ? {
            anyReservationForSelectedDay = false,
            allReservationsSameDaySameParkingWithKey.clear(),
            debugPrint("allReservationsSameDaySameParkingWithKey $allReservationsSameDaySameParkingWithKey"),
            testallBookedTimeSlots.clear(),
            testallBookedTimeSlotsInMinutes.clear(),
            spotIDsWithinXHoursBookedNotOccupied.clear(),
//clear the bookedwithinXhourslist by comapring what is in it and what is not
          }
        : anyReservationForSelectedDay = true;
    //debugPrint("allReservationsSameDaySameParkingWithKey $testallBookedTimeSlots");

    debugPrint("VAR IS: $allReservationsOnSelectedDayList");
    for (var singleReservationSameDayAsUserSelectedDay in allReservationsOnSelectedDayList) {
      //debugPrint("CHECK $singleReservationSameDayAsUserSelectedDay");

      var singleReservationNoKeyCasted = singleReservationSameDayAsUserSelectedDay.value as Map<String, dynamic>;
      var singleBookingStartTimeStamp = singleReservationNoKeyCasted['BookingStart'] as Timestamp;
      var singleBookingEndTimeStamp = singleReservationNoKeyCasted['BookingEnd'] as Timestamp;

      if (selectedDay.year == DateTime.now().year &&
          selectedDay.month == DateTime.now().month &&
          selectedDay.day == DateTime.now().day) {
        allReservationsExistingSameTimeAsNowDifferentDay.clear(); //do not delete
        allReservationsSameDaySameParkingWithKey
            .addAll({singleReservationSameDayAsUserSelectedDay.key: singleReservationNoKeyCasted});
      } else {
        allReservationsSameDaySameParkingWithKey.clear(); //do not delete

        allReservationsExistingSameTimeAsNowDifferentDay
            .addAll({singleReservationSameDayAsUserSelectedDay.key: singleReservationNoKeyCasted});
      }

      debugPrint(
          "singleReservationNoKeyCasted $singleReservationNoKeyCasted ______ $allReservationsExistingSameTimeAsNowDifferentDay ");

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
    selectedDayPlusXHourToInt = ((selectedDay.hour + availabilityHoursInterval) * 60 + selectedDay.minute) *
        60; //closinghour to int , if selectedDayPlusXhours sup to closnghours to int, (fetchedTimes.last) then
    selectedDayToInt = ((selectedDay.hour) * 60 + selectedDay.minute) * 60;
    Set<int> convertedTimesSet = {};

    for (var element in timesOfDayFetched) {
      convertedTimesSet.add((element.hour * 60 + element.minute) * 60);
    }
    debugPrint("SELECTEDDAYTOI_NT :$selectedDayToInt");
    var work = allReservationsSameDaySameParkingWithKey.entries.where((entry) {
      var matchingTimeStampEntry = testallBookedTimeSlotsInMinutes.entries.where((element) => element.key == entry.key);
      var matchingTSEntryFinal =
          matchingTimeStampEntry.isNotEmpty ? matchingTimeStampEntry.first.value as Map<String, dynamic> : {};
      /*  selectedDayPlusXHourToInt <= convertedTimesSet.last && matchingTimeStampEntry.isNotEmpty
          ? debugPrint("MATCHINGOO $matchingTSEntryFinal")
          : null; */
      return selectedDayPlusXHourToInt > convertedTimesSet.last && matchingTimeStampEntry.isNotEmpty
          ? matchingTSEntryFinal['BookingEnd'] >= selectedDayToInt &&
              matchingTSEntryFinal['BookingEnd'] <= selectedDayPlusXHourToInt
          : selectedDayPlusXHourToInt <= convertedTimesSet.last && matchingTimeStampEntry.isNotEmpty
              ? matchingTSEntryFinal['BookingEnd'] >= selectedDayToInt &&
                      matchingTSEntryFinal['BookingEnd'] >= selectedDayPlusXHourToInt ||
                  matchingTSEntryFinal['BookingStart'] >= selectedDayToInt ||
                  matchingTSEntryFinal['BookingEnd'] > selectedDayToInt
              //&&matchingTSEntryFinal['BookingEnd'] >= selectedDayPlusXHourToInt
              : false;
    });
    debugPrint("WORK $work ___ $selectedDayToInt _ ");
    for (var element in work) {
      Set<String> ok = {element.value['SlotID']};
      spotIDsWithinXHoursBookedNotOccupied.any((element) {
        debugPrint("DIFF IS $element _______ ${element.difference(ok)}");
        return false;
      });

      /* spotIDsWithinXHoursBookedNotOccupied.remove(spotIDsWithinXHoursBookedNotOccupied.where((element) =>
          element ==
          element.difference(
              ok))); */ //check if Spot is booked many times in the same day like A5 8H10H and then 10H20 11H   AND YOU SELECT DAY AT 8H
      //withinXHoursParkingSpotIDsToShow []} may need to remove that entry from here too
    }
    debugPrint("HERE YOU GO $spotIDsWithinXHoursBookedNotOccupied");
    return work;
  }

  batchWriteInsideParkingInfo(int total) async {
    currentlySignedInUser = firebaseService.auth.currentUser;
    CollectionReference collectionRef = myDB.collection("locations/${widget.receivedID}/insideParkingInfo");
    WriteBatch batch = myDB.batch();
    List allBatchSpotIDs = <String>[], specialAvailableShuffle = <String>[], regAvailableShuffle = <String>[];
    int totalForParking = total;
    for (var i = 0; i < totalForParking ~/ 2; i++) {
      allBatchSpotIDs.add('A$i');
      allBatchSpotIDs.add('B$i');
    }

    debugPrint("TOTAL DIV 3 ${total - (total ~/ 3)}");
    for (var i = 0; i < totalForParking ~/ 3; i++) {
      var theFirstShuffle = (allBatchSpotIDs..shuffle()).first;
      specialAvailableShuffle.contains(theFirstShuffle) ? null : specialAvailableShuffle.add(theFirstShuffle);
    }
    debugPrint("ALL SPEC SHUFFLE :$specialAvailableShuffle");
    var specSet = Set.from(specialAvailableShuffle), allBatchSet = Set.from(allBatchSpotIDs);
    regAvailableShuffle = allBatchSet.difference(specSet).toList();

    batch.set(
      collectionRef.doc(),
      {
        'Fee per 30 minutes': 500,
        'Special': {
          'IDs': specialAvailableShuffle,
          'Available': {'IDs': specialAvailableShuffle, 'Total': specialAvailableShuffle.length},
          'Booked': {'IDs': [], 'Total': 0},
          'Occupied': {
            'From Real Parking': {'IDs': [], 'Total': 0},
            'From Booking': {'IDs': [], 'Total': 0},
          },
          'Total': totalForParking ~/ 3,
        },
        'Regular': {
          'IDs': regAvailableShuffle,
          'Available': {'IDs': regAvailableShuffle, 'Total': regAvailableShuffle.length},
          'Booked': {'IDs': [], 'Total': 0},
          'Occupied': {
            'From Real Parking': {'IDs': [], 'Total': 0},
            'From Booking': {'IDs': [], 'Total': 0},
          },
          'Total': totalForParking - (totalForParking ~/ 3),
        },
        'Total': totalForParking
      },
    );

    await batch.commit().whenComplete(() => debugPrint("SUCCESSFULLY WRITTEN INSIDE PARKING TO FIREBASE"));
  }

  void fetchParkingSlotsInfoFromFB() {
    if (insideParkingInfoFetched.isNotEmpty) {
      var regAllIDs = insideParkingInfoFetched['Regular']['IDs'] as List;
      var specAllIDs = insideParkingInfoFetched['Special']['IDs'] as List;
      var cast1 = insideParkingInfoFetched['Regular']['Available'] as Map<String, dynamic>;
      var castedRAvailableSlotsItems = cast1['IDs'] as List;

      var cast2 = insideParkingInfoFetched['Regular']['Booked'] as Map<String, dynamic>;
      var castedRBookedSlotsList = cast2['IDs'] as List;

      var cast3 = insideParkingInfoFetched['Regular']['Occupied'] as Map<String, dynamic>;

      var cast31 = cast3['From Booking'] as Map<String, dynamic>;
      var castedROccupiedAfterBook = cast31['IDs'] as List;

      var cast32 = cast3['From Real Parking'] as Map<String, dynamic>;
      var castedROccupiedNoPriorBooking = cast32['IDs'] as List;

      var cast4 = insideParkingInfoFetched['Special']['Available'] as Map<String, dynamic>;
      var castedSAvailable = cast4['IDs'] as List;

      var cast5 = insideParkingInfoFetched['Special']['Booked'] as Map<String, dynamic>;
      var castedSBookedSlotsList = cast5['IDs'] as List;

      var cast6 = insideParkingInfoFetched['Special']['Occupied'] as Map<String, dynamic>;

      var cast61 = cast6['From Booking'] as Map<String, dynamic>;
      var castedSOccupiedAfterBook = cast61['IDs'] as List;

      var cast62 = cast6['From Real Parking'] as Map<String, dynamic>;
      var castedSOccupiedNoPriorBooking = cast62['IDs'] as List;

      if (selectedDay.year == DateTime.now().year &&
          selectedDay.month == DateTime.now().month &&
          selectedDay.day == DateTime.now().day) {
        rAvailableIDs = castedRAvailableSlotsItems.toSet();
        rBookedIDs = castedRBookedSlotsList.toSet();
        rOccupiedAfterBookedIDs = castedROccupiedAfterBook.toSet();
        rOccupiedNoPriorBookingIDs = castedROccupiedNoPriorBooking.toSet();
        sAvailableIDs = castedSAvailable.toSet();
        sBookedIDs = castedSBookedSlotsList.toSet();
        sOccupiedAfterBookedIDs = castedSOccupiedAfterBook.toSet();
        sOccupiedNoPriorBookingIDs = castedSOccupiedNoPriorBooking.toSet();
        allSpecialSpotsIDs = [sBookedIDs, sAvailableIDs, sOccupiedAfterBookedIDs, sOccupiedNoPriorBookingIDs]
            .expand((element) => element)
            .toSet();

        allRegularSpotsID = [
          rBookedIDs,
          rAvailableIDs,
          rOccupiedAfterBookedIDs,
          rOccupiedNoPriorBookingIDs,
        ].expand((element) => element).toSet();

        specialTotal = allSpecialSpotsIDs.length;
        specialAvailableTotal = sAvailableIDs.length;
        regularTotal = allRegularSpotsID.length;
        regularAvailableTotal = rAvailableIDs.length;
        totalParkingCapacity = insideParkingInfoFetched['Total'];
      } else {
        debugPrint(" NO YOUR HONOR");

        myDB.collection('slotsReservations').get().then((slotRes) {
          rBookedIDs.clear();
          sBookedIDs.clear();
          rOccupiedAfterBookedIDs.clear();
          sOccupiedAfterBookedIDs.clear();
          rOccupiedNoPriorBookingIDs.clear();
          sOccupiedNoPriorBookingIDs.clear();
          allRegularSpotsID = regAllIDs.toSet();
          allSpecialSpotsIDs = specAllIDs.toSet();

          if (slotRes.size != 0) {
            var ok = slotRes.docs.where((element) {
              var timeStamp = element.data()['BookingStart'] as Timestamp;
              return DateFormat.yMEd().format(timeStamp.toDate()) == DateFormat.yMEd().format(selectedDay) &&
                  element.data()['ParkingID'] == widget.receivedID;
            });
            ok.isNotEmpty
                ? ok.forEach((element) {
                    if (regAllIDs.contains('${element.data()['SlotID']}')) {
                      rBookedIDs.add(element.data()['SlotID']);
                    } else {
                      sBookedIDs.add(element.data()['SlotID']);
                    }
                  })
                : null;

            sAvailableIDs = specAllIDs.toSet().difference(sBookedIDs);
            rAvailableIDs = regAllIDs.toSet().difference(rBookedIDs);

            specialTotal = allSpecialSpotsIDs.length;
            specialAvailableTotal = sAvailableIDs.length;
            regularTotal = allRegularSpotsID.length;
            regularAvailableTotal = rAvailableIDs.length;
            totalParkingCapacity = insideParkingInfoFetched['Total'];
          }
        });
      }
    }
    debugPrint(
        "rAvailable $rAvailableIDs \t rBooked $rBookedIDs \t rOccupiedAfterBook $rOccupiedAfterBookedIDs \t SPECIAL rOccupiedNoPriorBooking $rOccupiedNoPriorBookingIDs \n sAvailable $sAvailableIDs \t sBooked $sBookedIDs \t sOccupiedAfterBooked $sOccupiedAfterBookedIDs \t sOccupiedNoPriorBooking $sOccupiedNoPriorBookingIDs \n specialTotal $specialTotal \t specialAvailableTotal $specialAvailableTotal \t regularTotal $regularTotal \t regularAvailableTotal $regularAvailableTotal \t totalParkingCapacity $totalParkingCapacity");
  }

  void createAlleysMappingWithIDs(int alleyBindexStart, int j) {
    debugPrint("CREATEALLEYSMAPPING $spotIDsWithinXHoursBookedNotOccupied");
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
                "isBookedWithinXHours": spotIDsWithinXHoursBookedNotOccupied.any((element) => element.contains("A$i"))
                    ? true
                    : false, // comeback
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
                    spotIDsWithinXHoursBookedNotOccupied.any((element) => element.contains("B${i - alleyBindexStart}"))
                        ? true
                        : false,

                "highlightColor": Colors.transparent
              })
            };
    }
    debugPrint("ALLEY A : $alleyA ______________ ALLEY B : $alleyB");
    mappedAlleysAndSlotIds.addAll({
      'Alley A': alleyA,
      'Alley B': alleyB,
    });
  }

  void allListeners() {
    listeningToSlotsReservationsRealTime();
    listeningToInsideParkingRealTime();
  }

  void listeningToSlotsReservationsRealTime() {
    FirebaseFirestore.instance
        .collection("slotsReservations")
        .where("ParkingID", isEqualTo: widget.receivedID)
        .snapshots()
        .listen((event) {
      //by default, someone who books will not be parked yet. so VEHICULESTATUS will be not yet parked
      for (var change in event.docChanges) {
        switch (change.type) {
          case DocumentChangeType.added:
            //debugPrint("Slots Reservations Document Just Loaded: ${change.doc.data()}");
            debugPrint("REAL TIME CHECK __ ${change.doc.data()!['BookingStart']} __ ${change.doc.id}");
            break;
          case DocumentChangeType.modified:
            //debugPrint("Slots Reservations Document Just EDITED: ${change.doc.data()}");
            var baba =
                allReservationsSameDaySameParkingWithKey.entries.where((element) => element.key == change.doc.id);
            debugPrint("THE KEY IS: ${baba.first.value['BookingStart']}");

            debugPrint("CHECK BS ${change.doc.data()!['BookingStart']} _ __ ${change.doc.id}");
            if (change.doc.data()!['BookingStart'] != baba.first.value['BookingStart']) {
              debugPrint("NEED UPDATE");
              baba.first.value['BookingStart'] = change.doc.data()!['BookingStart'];
            }

            if (change.doc.data()!['VehiculeStatus']['Status'] == 'Parked') {
              spotIDsWithinXHoursBookedNotOccupied.remove(change.doc.data()!['SlotID']);
            }
            if (change.doc.data()!['VehiculeStatus']['Status'] == 'Gone') {
              //Deal with the car leaving

            }
            break;
          case DocumentChangeType.removed:
            debugPrint("Reservation DONE SO Archived: ${change.doc.data()}");
            break;
        }
      }
    });
  }

  void listeningToInsideParkingRealTime() {
    FirebaseFirestore.instance
        .collection("locations/${widget.receivedID}/insideParkingInfo")
        .where("Fee per 30 minutes", isGreaterThan: 10)
        .snapshots()
        .listen((event) {
//DO NOT REMOVE THIS WHOLE SECTION as it updates the "within x hours list"
      var withinXHoursEntriesFetched = getWithinXHoursAvailabalitySatus(3);
      debugPrint("MAGS $withinXHoursEntriesFetched ");

      correspondingStartandEndIndexes.entries.forEach((indexEntries) {
        var castIndexEntries = indexEntries.value as Map<String, dynamic>;

        allReservationsExistingSameTimeAsNowDifferentDay.entries.isNotEmpty
            ? allReservationsExistingSameTimeAsNowDifferentDay.entries.any((allHoursEntries) {
                var castAllHoursValues;
                allHoursEntries.key ==
                        indexEntries.key //AND THE of withinXhours IDS ARE DIFF then update withinXhoursParking
                    ? {
                        castAllHoursValues = allHoursEntries.value as Map<String, dynamic>,
                        //debugPrint("LOLO $castXHoursValues \t $castIndexEntries \t $count"),
                        if (allHoursParkingSpotInfosNeeded.length < correspondingStartandEndIndexes.length)
                          {
                            allHoursParkingSpotInfosNeeded.add({
                              'SlotID': castAllHoursValues['SlotID'],
                              'indexes': [castIndexEntries['startIndex'], castIndexEntries['endIndex']],
                            }),
                            //withinXHoursParkingSpotInfosNeeded FIND A WQAY TO UPDATE THE LIST TH THE NEWLY ADDED VALUE WHICH IS B1 IN THIS CASE
                            allSpotIDsAllHoursBookedNotOccupied.add({castAllHoursValues['SlotID']}),
                          }
                        else if (allHoursParkingSpotInfosNeeded.length == correspondingStartandEndIndexes.length)
                          {
                            allHoursParkingSpotInfosNeeded.forEach((element) {
                              debugPrint("WOODZ: ${listEquals(element.values.last, [
                                    castIndexEntries['startIndex'],
                                    castIndexEntries['endIndex']
                                  ])}");
                              listEquals(element.values.last,
                                              [castIndexEntries['startIndex'], castIndexEntries['endIndex']]) ==
                                          true &&
                                      element.values.first != castAllHoursValues['SlotID']
                                  ? element.update('SlotID', (value) => castAllHoursValues['SlotID'])
                                  : null;
                            })
                          }
                      }
                    : null;
                return allHoursEntries.key == indexEntries.key;
              })
            : allHoursParkingSpotInfosNeeded.clear();

        withinXHoursEntriesFetched.isNotEmpty
            ? withinXHoursEntriesFetched.any((xHoursEntries) {
                var castXHoursValues;
                Iterable<Map<String, dynamic>> themappedElement;
                xHoursEntries.key ==
                        indexEntries.key //AND THE of withinXhours IDS ARE DIFF then update withinXhoursParking
                    ? {
                        castXHoursValues = xHoursEntries.value as Map<String, dynamic>,
                        //debugPrint("LOLO $castXHoursValues \t $castIndexEntries \t $count"),
                        if (withinXHoursParkingSpotInfosNeeded.length < correspondingStartandEndIndexes.length)
                          {
                            withinXHoursParkingSpotInfosNeeded.add({
                              'SlotID': castXHoursValues['SlotID'],
                              'indexes': [castIndexEntries['startIndex'], castIndexEntries['endIndex']],
                            }),
                            indexesToDisplayWithnXHours
                                .add([castIndexEntries['startIndex'], castIndexEntries['endIndex']]),
                            spotIDsWithinXHoursBookedNotOccupied.add({castXHoursValues['SlotID']}),
                            themappedElement = mappedSelectedSlotAlley
                                .where((element) => element.values.first == castXHoursValues['SlotID']),
                            debugPrint("THEMAPPEDELEMENET :$themappedElement"),
                            themappedElement.isNotEmpty
                                ? themappedElement.forEach((element) {
                                    element.update('isBookedWithinXHours', (value) => true);
                                  })
                                : null
                          }
                        else if (withinXHoursParkingSpotInfosNeeded.length == correspondingStartandEndIndexes.length)
                          {
                            withinXHoursParkingSpotInfosNeeded.forEach((element) {
                              debugPrint("WOODZ: ${listEquals(element.values.last, [
                                    castIndexEntries['startIndex'],
                                    castIndexEntries['endIndex']
                                  ])}");
                              listEquals(element.values.last,
                                              [castIndexEntries['startIndex'], castIndexEntries['endIndex']]) ==
                                          true &&
                                      element.values.first != castXHoursValues['SlotID']
                                  ? element.update('SlotID', (value) => castXHoursValues['SlotID'])
                                  : null;
                            })
                          }
                      }
                    : null;
                return xHoursEntries.key == indexEntries.key;
              })
            : withinXHoursParkingSpotInfosNeeded.clear();
      });

      withinXHoursEntriesFetched.isEmpty ? withinXHoursParkingSpotInfosNeeded.clear() : null;
      debugPrint(
          "withinXHoursParkingSpotIDsToShow $withinXHoursParkingSpotInfosNeeded __ $allHoursParkingSpotInfosNeeded }");
      debugPrint(
          "spotIDsWithinXHoursBookedNotOccupied $spotIDsWithinXHoursBookedNotOccupied __ $allHoursParkingSpotInfosNeeded }");
//DO NOT REMOVE THIS WHOLE SECTION ------------ END

      for (var change in event.docChanges) {
        switch (change.type) {
          case DocumentChangeType.added:
            debugPrint("Inside Parking Info Document Just Loaded: ${change.doc.data()}"); //rt for realTime
            /*   var rTrBookedIDs = change.doc.data()!['Regular']['Booked']['IDs'] as List;

            var theID;
            listEquals(rTrBookedIDs, rBookedIDs.toList()) == true //need precisely this one
                ? {
                    for (var singleAlleyInfo in mappedSelectedSlotAlley)
                      {
                        theID = singleAlleyInfo.values.first as String,
                        singleAlleyInfo.update(
                          'isSlotBooked',
                          (value) => rBookedIDs.contains('$theID') || sBookedIDs.contains('$theID') ? true : false,
                        ),
                        singleAlleyInfo["isSlotOccupied"] = {
                          "AfterBooked":
                              rOccupiedAfterBookedIDs.contains('$theID') || sOccupiedAfterBookedIDs.contains('$theID')
                                  ? true
                                  : false,
                          'NoPriorBooking': rOccupiedNoPriorBookingIDs.contains('$theID') ||
                                  sOccupiedNoPriorBookingIDs.contains('$theID')
                              ? true
                              : false,
                        },
                        singleAlleyInfo.update(
                          "isSlotFree",
                          (value) =>
                              rAvailableIDs.contains('$theID') || sAvailableIDs.contains('$theID') ? true : false,
                        ),
                        singleAlleyInfo.update(
                          "isSpecialSpot",
                          (value) => allSpecialSpotsIDs.contains('$theID') ? true : false,
                        ),
                        singleAlleyInfo.update(
                          "isBookedWithinXHours",
                          (value) => spotIDsWithinXHoursBookedNotOccupied.any((element) => element.contains('$theID'))
                              ? true
                              : false, //NO NEED TP ADD BOOKEDANDOCCUPIED BECAUSE IT'S IN SLOT OCCUPIED ALREADY
                        ),
                      }
                  }
                : null;
            debugPrint("IS IT EQUAL AFTER ADDED $rBookedIDs ______ $allRegularSpotsID"); */
            break;

          case DocumentChangeType.modified:
            debugPrint("Inside Parking Info Document Just EDITED: ${change.doc.data()}");

            /*    var rTrAvailableIDs = change.doc.data()!['Regular']['Available']['IDs'] as List;
            var rTrBookedIDs = change.doc.data()!['Regular']['Booked']['IDs'] as List;
            var rTrOccupiedAfterBookedIDs = change.doc.data()!['Regular']['Occupied']['From Booking']['IDs'] as List;
            var rTrOccupiedNoPriorBookingIDs =
                change.doc.data()!['Regular']['Occupied']['From Real Parking']['IDs'] as List;

            var rTsAvailableIDs = change.doc.data()!['Regular']['Available']['IDs'] as List;
            var rTsBookedIDs = change.doc.data()!['Regular']['Available']['IDs'] as List;
            var rTsOccupiedAfterBookedIDs = change.doc.data()!['Regular']['Available']['IDs'] as List;
            var rTsOccupiedNoPriorBookingIDs = change.doc.data()!['Regular']['Available']['IDs'] as List;

            Set itemToRemove = {}, concernedSet = {};
            List rTconcernedSetAsList = [];

            listEquals(rTrAvailableIDs, rAvailableIDs.toList()) == false
                ? {concernedSet = rAvailableIDs, rTconcernedSetAsList = rTrAvailableIDs}
                : listEquals(rTrBookedIDs, rBookedIDs.toList()) == false
                    ? {concernedSet = rBookedIDs, rTconcernedSetAsList = rTrBookedIDs}
                    : listEquals(rTrOccupiedAfterBookedIDs, rOccupiedAfterBookedIDs.toList()) == false
                        ? {concernedSet = rOccupiedAfterBookedIDs, rTconcernedSetAsList = rTrOccupiedAfterBookedIDs}
                        : listEquals(rTrOccupiedNoPriorBookingIDs, rOccupiedNoPriorBookingIDs.toList()) == false
                            ? {
                                concernedSet = rOccupiedNoPriorBookingIDs,
                                rTconcernedSetAsList = rTrOccupiedNoPriorBookingIDs
                              }
                            : listEquals(rTrOccupiedNoPriorBookingIDs, rOccupiedNoPriorBookingIDs.toList()) == false
                                ? {
                                    concernedSet = rOccupiedNoPriorBookingIDs,
                                    rTconcernedSetAsList = rTrOccupiedNoPriorBookingIDs
                                  }
                                : listEquals(rTsAvailableIDs, sAvailableIDs.toList()) == false
                                    ? {concernedSet = sAvailableIDs, rTconcernedSetAsList = rTsAvailableIDs}
                                    : listEquals(rTsBookedIDs, sBookedIDs.toList()) == false
                                        ? {concernedSet = sBookedIDs, rTconcernedSetAsList = rTsBookedIDs}
                                        : listEquals(rTsOccupiedAfterBookedIDs, sOccupiedAfterBookedIDs.toList()) ==
                                                false
                                            ? {
                                                concernedSet = sOccupiedAfterBookedIDs,
                                                rTconcernedSetAsList = rTsOccupiedAfterBookedIDs
                                              }
                                            : listEquals(rTsOccupiedNoPriorBookingIDs,
                                                        sOccupiedNoPriorBookingIDs.toList()) ==
                                                    false
                                                ? {
                                                    concernedSet = sOccupiedNoPriorBookingIDs,
                                                    rTconcernedSetAsList = rTsOccupiedNoPriorBookingIDs
                                                  }
                                                : listEquals(rTsOccupiedNoPriorBookingIDs,
                                                            sOccupiedNoPriorBookingIDs.toList()) ==
                                                        false
                                                    ? {
                                                        concernedSet = sOccupiedNoPriorBookingIDs,
                                                        rTconcernedSetAsList = rTsOccupiedNoPriorBookingIDs
                                                      }
                                                    : null;
            listEquals(rTconcernedSetAsList, concernedSet.toList()) == false
                ? {
                    debugPrint("REBUILLIST $rebuildIDLists"),
                    concernedSet.removeWhere((element) {
                      itemToRemove = concernedSet.difference(rTconcernedSetAsList.toSet());
                      //debugPrint ItemToRemove will only show the difference if the item is deleted from its location in fb. otherwise, it will edit it where it's supposed to be. Do not worry about it
                      var equal = itemToRemove.isNotEmpty == true && element == itemToRemove.first ? true : false;

                      return equal;
                    }),
                    debugPrint("IS concenerdSret $concernedSet _ rTconcernedSetAsList $rTconcernedSetAsList")
                  }
                : null;

          */
            break;
          case DocumentChangeType.removed:
            debugPrint("Reservation DONE SO Archived: ${change.doc.data()}");
            break;
        }
      }
    });
  }

  displayAvailabilityForWholeDay(int tappedOnSpotIndex, String whichAlley, int timeSlotIndex) {
    whichAlley.contains('B') ? tappedOnSpotIndex = tappedOnSpotIndex + parkingSlotsTotal ~/ 2 : null;
    debugPrint(
        "THE INDEX $tappedOnSpotIndex _____ alley: $whichAlley ${mappedSelectedSlotAlley.elementAt(tappedOnSpotIndex)} _ $doDisplayAvailabilityForWholeDay __ $tappedOnParkingSpotID");

    if (selectedDay.year == DateTime.now().year &&
        selectedDay.month == DateTime.now().month &&
        selectedDay.day == DateTime.now().day) {
      if (mappedSelectedSlotAlley.elementAt(tappedOnSpotIndex)['isBookedWithinXHours'] == true ||
          mappedSelectedSlotAlley.elementAt(tappedOnSpotIndex)['isSlotOccupied']['AfterBooked'] == true) {
        List<List> wholeDayStatusForSpecificSpot = [];
        testallBookedTimeSlotsInMinutes.isEmpty ? wholeDayStatusForSpecificSpot.clear() : null;
        debugPrint("castIndexEntries $testallBookedTimeSlotsInMinutes");

        correspondingStartandEndIndexes.entries.forEach((indexEntries) {
          var castIndexEntries = indexEntries.value as Map<String, dynamic>;
          testallBookedTimeSlotsInMinutes.isNotEmpty
              ? testallBookedTimeSlotsInMinutes.entries.any((allBookedHoursEntries) {
                  var castAllHoursValues;
                  Iterable<Map<String, dynamic>> babs = {};
                  allBookedHoursEntries.key == indexEntries.key
                      ? {
                          withinXHoursParkingSpotInfosNeeded.isNotEmpty
                              ? babs = withinXHoursParkingSpotInfosNeeded.where((element) {
                                  var ok = element['indexes'] as List;
                                  return castIndexEntries.values.first == ok.first;
                                })
                              : null,
                          castAllHoursValues = allBookedHoursEntries.value as Map<String, dynamic>,
                          //debugPrint("LOLOI $castAllHoursValues \t $castIndexEntries \t $babs"),
                          babs.isNotEmpty
                              ? babs.forEach((element) {
                                  element['SlotID'] == mappedSelectedSlotAlley.elementAt(tappedOnSpotIndex).values.first
                                      ? {
                                          wholeDayStatusForSpecificSpot += ([
                                            [castIndexEntries['startIndex'], castIndexEntries['endIndex']]
                                          ])
                                        }
                                      : null;
                                })
                              : null,
                        }
                      : null;
                  return allBookedHoursEntries.key == indexEntries.key;
                })
              : wholeDayStatusForSpecificSpot.clear();
        });
        debugPrint(" wholeDayStatus $wholeDayStatusForSpecificSpot");
        return wholeDayStatusForSpecificSpot.any((element) {
                  return element.first <= timeSlotIndex &&
                      element.last >= timeSlotIndex &&
                      timeSlotIndex >= selectedDayIndex;
                }) ==
                true
            ? getTimeSpotIcon('booked')
            : wholeDayStatusForSpecificSpot.any((element) {
                      return timeSlotIndex < selectedDayIndex;
                    }) ==
                    true
                ? getTimeSpotIcon('unbookable')
                : getTimeSpotIcon('available'); /*  ? Colors.orange
          : Colors.green; */
      } else if (mappedSelectedSlotAlley.elementAt(tappedOnSpotIndex)['isSlotOccupied']['NoPriorBooking'] == true) {
        return timeSlotIndex >= selectedDayIndex &&
                allConvertedTimesOfDayToInt.elementAt(timeSlotIndex * 2) <= selectedDayToInt &&
                allConvertedTimesOfDayToInt.elementAt((timeSlotIndex * 2) + 1) >= selectedDayToInt
            ? getTimeSpotIcon('occupied')
            : timeSlotIndex < selectedDayIndex == true
                ? getTimeSpotIcon('unbookable')
                : getTimeSpotIcon('available'); //getTimeSpotIcon('unBookable') if today'sdateis = selectedDay
        /*   ? Color.fromARGB(255, 202, 24, 21)
          : Colors.green; */
      } else {
        return timeSlotIndex < selectedDayIndex == true
            ? getTimeSpotIcon('unbookable')
            : getTimeSpotIcon('available'); //Container(width: 15, height: 15, color: Colors.amber);
      }
    } else {
      //OCCUPIED CANNOT BE SHOWN BECAUSE THE DAY HAS NOT COME YET! JUST TAKE CARE OF BOOKED AND AVAILABLE
      if (mappedSelectedSlotAlley.elementAt(tappedOnSpotIndex)['isSlotBooked'] == true) {
        List<List> wholeDayStatusForSpecificSpotSelectedDaySupToToday = [];
        testallBookedTimeSlotsInMinutes.isEmpty ? wholeDayStatusForSpecificSpotSelectedDaySupToToday.clear() : null;

        correspondingStartandEndIndexes.entries.forEach((indexEntries) {
          var castIndexEntries = indexEntries.value as Map<String, dynamic>;
          testallBookedTimeSlotsInMinutes.isNotEmpty
              ? testallBookedTimeSlotsInMinutes.entries.any((allBookedHoursEntries) {
                  var castAllHoursValues;
                  Iterable<Map<String, dynamic>> babs = {};
                  allBookedHoursEntries.key == indexEntries.key
                      ? {
                          allHoursParkingSpotInfosNeeded.isNotEmpty
                              ? babs = allHoursParkingSpotInfosNeeded.where((element) {
                                  var ok = element['indexes'] as List;
                                  return castIndexEntries.values.first == ok.first;
                                })
                              : null,
                          castAllHoursValues = allBookedHoursEntries.value as Map<String, dynamic>,
                          //debugPrint("MALADADA $castAllHoursValues \t $castIndexEntries \t $babs"),
                          babs.isNotEmpty
                              ? babs.forEach((element) {
                                  element['SlotID'] == mappedSelectedSlotAlley.elementAt(tappedOnSpotIndex).values.first
                                      ? {
                                          wholeDayStatusForSpecificSpotSelectedDaySupToToday += ([
                                            [castIndexEntries['startIndex'], castIndexEntries['endIndex']]
                                          ])
                                        }
                                      : null;
                                })
                              : null,
                        }
                      : null;
                  return allBookedHoursEntries.key == indexEntries.key;
                })
              : wholeDayStatusForSpecificSpotSelectedDaySupToToday.clear();
        });
        debugPrint(" wholeDayStatusSUP $wholeDayStatusForSpecificSpotSelectedDaySupToToday");

        return wholeDayStatusForSpecificSpotSelectedDaySupToToday.any((element) {
                  return element.first <= timeSlotIndex && element.last >= timeSlotIndex
                      /* &&
                      timeSlotIndex >= selectedDayIndex */
                      ;
                }) ==
                true
            ? getTimeSpotIcon('booked')
            : wholeDayStatusForSpecificSpotSelectedDaySupToToday.any((element) {
                      return timeSlotIndex > selectedDayIndex;
                    }) ==
                    true
                ? getTimeSpotIcon('available')
                : getTimeSpotIcon('available');
      }
      return getTimeSpotIcon('available');
    }
  }

  checkWallet(num bookingTotalToPay, BookingStateManagement stateManagerRead) {
    String content = stateManagerRead.buildingBookingText;
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return AlertDialog(
            content: SingleChildScrollView(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              content == 'Registering your booking...'
                  ? SpinKitFadingCircle(
                      size: 50,
                      itemBuilder: (BuildContext context, int index) {
                        return const DecoratedBox(
                          decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                        );
                      },
                    )
                  : const Icon(Icons.cancel_outlined, size: 35, color: Colors.red),
              const SizedBox(height: 10),
              FittedBox(child: Text(content)),
              SizedBox(height: content == 'Registering your booking...' ? 40 : 20),
            ])),
            actions: content == 'Registering your booking...'
                ? []
                : [
                    TextButton(
                        onPressed: () {
                          Future.delayed(const Duration(seconds: 4)).then((value) {
                            if (mounted) {
                              return Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (context) => const Home(
                                          fromLoginView: true,
                                          parkingToNavigateTo: {},
                                          newIndex: 0,
                                          timeUntilResStarts: 0,
                                        )),
                              );
                            }
                          });
                        },
                        child: FittedBox(
                            child: Text(
                          "OK, Back to dashboard!",
                          style: TextStyle(fontSize: 12, color: Colors.red.shade400),
                        ))),
                  ],
          );
        }).then((value) {
      debugPrint('VALUE POP WALLET $value');
    });
  }

  createBookingItem(
      linkedParkingNameAndInsideInfo,
      String receivedID,
      User? currentlySignedInUser,
      Map<String, dynamic> selectedVehiculeInfoMappedFromSelectVehicule,
      TimeRange finallyBookedTimeRange,
      DateTime selectedDay) {
    var bookingEndTS = Timestamp.fromDate(DateTime(selectedDay.year, selectedDay.month, selectedDay.day,
        finallyBookedTimeRange.endTime.hour, finallyBookedTimeRange.endTime.minute));
    var bookingStartTS = Timestamp.fromDate(DateTime(selectedDay.year, selectedDay.month, selectedDay.day,
        finallyBookedTimeRange.startTime.hour, finallyBookedTimeRange.startTime.minute));

    WriteBatch slotsResBatch = myDB.batch();
    CollectionReference slotsReservationsCollection = myDB.collection("slotsReservations");
    myDB
        .collection("users/${currentlySignedInUser?.uid}/vehicules")
        .where('Specs.License Plate N°',
            isEqualTo: selectedVehiculeInfoMappedFromSelectVehicule['Specs']['License Plate N°'])
        .get()
        .then((value) async {
      debugPrint("SPEC CHECK :${value.docs.first.data()}");

      slotsResBatch.set(slotsReservationsCollection.doc(), {
        'BookingEnd': bookingEndTS,
        'BookingStart': bookingStartTS,
        'ClientID': currentlySignedInUser?.uid,
        'ParkingID': widget.receivedID,
        'ReservationStatus': <String, bool>{
          'Added Time': false,
          'Canceled Before Start': false,
          'Completed Before End': false,
          'Completed On Time': false,
          'Started': false,
        },
        'SlotID': bookerTimeAndSpotInfoMapped['Selected Parking Spot'],
        'VehiculeID': value.docs.first.id,
        'VehiculeStatus': <String, dynamic>{
          'Status': 'Not Yet Parked',
        },
        'TimeStamp': FieldValue.serverTimestamp()
      });
      await slotsResBatch.commit().whenComplete(() => debugPrint("RESERVATION SUCCESSFULLY ADDED"));
    });
  }

  void listeningToDebitsRT(DocumentReference<Map<String, dynamic>> theDocToUpdate) {
    List allWalletDebitIDs = [];
    int totalEntriesDebit = 0;
    String balanceInCFA = '10';

    theDocToUpdate.get().then((value) {
      debugPrint("DATA CHECK: ${value.data()}");
      var debitList = value.data()!['Transactions']['Debits']['IDs'] as List;
      allWalletDebitIDs.length < debitList.length ? allWalletDebitIDs = debitList : null;
      totalEntriesDebit = value.data()!['Transactions']['Debits']['Total Entries'];
      balanceInCFA = value.data()!['Balance'].toString();
    });

    FirebaseFirestore.instance
        .collection("users/${currentlySignedInUser?.uid}/wallet/${theDocToUpdate.id}/debits")
        .where("Debit Amount", isGreaterThan: 0)
        .snapshots()
        .listen((event) {
      for (var change in event.docChanges) {
        switch (change.type) {
          case DocumentChangeType.added:
            debugPrint("FIRESTORESERVICE Document Just Loaded: ${change.doc.data()}");

            break;
          case DocumentChangeType.modified:
            debugPrint("Document Just Modified: ${change.doc.data()}");
            allWalletDebitIDs.length < event.docs.length
                ? {
                    allWalletDebitIDs.add(change.doc.id),
                    theDocToUpdate.update({'Balance': int.parse(balanceInCFA) - change.doc.data()!['Debit Amount']}),
                    theDocToUpdate.update({'Transactions.Debits.IDs': allWalletDebitIDs}),
                    theDocToUpdate.update({'Transactions.Debits.Total Entries': totalEntriesDebit + 1}),
                  }
                : null;

            break;
          case DocumentChangeType.removed:
            debugPrint("Reservation DONE SO Archived: ${change.doc.data()}");
            break;
        }
      }
    });
  }

  void updateParkingSpotsAvailability(String parkingSpotIDBooked) {
    Set theParking = {parkingSpotIDBooked};
    var theDocToUpdate =
        myDB.collection("locations/${widget.receivedID}/insideParkingInfo").doc(insideParkingInfoDocIDNeeded);
    if (sAvailableIDs.contains(parkingSpotIDBooked)) {
      var sAvailableUpdated = sAvailableIDs.difference(theParking).toList();
      sBookedIDs.add(parkingSpotIDBooked);

      theDocToUpdate.update({
        'Special.Available.IDs': sAvailableUpdated,
        'Special.Available.Total': sAvailableUpdated.length,
        'Special.Booked.IDs': sBookedIDs.toList(),
        'Special.Booked.Total': sBookedIDs.length,
      });
    }
    if (rAvailableIDs.contains(parkingSpotIDBooked)) {
      var rAvailableUpdated = rAvailableIDs.difference(theParking).toList();
      rBookedIDs.add(parkingSpotIDBooked);

      theDocToUpdate.update({
        'Regular.Available.IDs': rAvailableUpdated,
        'Regular.Available.Total': rAvailableUpdated.length,
        'Regular.Booked.IDs': rBookedIDs.toList(),
        'Regular.Booked.Total': rBookedIDs.length,
      });
    }
  }

  void redirectingAlert() {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return AlertDialog(
            content: SingleChildScrollView(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
              Icon(Icons.check_circle_outline, size: 45, color: Colors.green),
              SizedBox(height: 10),
              FittedBox(child: Text("Booking successfully validated! \n Redirecting you to your dashboard...")),
              SizedBox(height: 45),
            ])),
          );
        });
  }
}

//CLSOGIN BRACKS

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
