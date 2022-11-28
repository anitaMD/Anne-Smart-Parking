// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'dart:async';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:smart_parking/screens/inside_app/for_dashboard/badges_notifications.dart';
import 'package:smart_parking/services/firebase/firestore_service.dart';
import 'package:time_range_picker/time_range_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../services/local_notifications/firebase_message_provider.dart';
import '../../../services/local_notifications/notification.dart';

class ReservationCountdown extends StatefulWidget {
  final User? currentlySignedInUser;
  final Map<String, dynamic> allReservationInfoNeeded;
  final Function(bool canShow) canShowToggle;
  final void Function(int selectedIndex) getIndex;
  final bool userHasVehicules;
  final int timeUntilResFetchedFromBookingOverview;

  const ReservationCountdown(
      {Key? key,
      required this.currentlySignedInUser,
      required this.allReservationInfoNeeded,
      required this.canShowToggle,
      required this.getIndex,
      required this.userHasVehicules,
      required this.timeUntilResFetchedFromBookingOverview})
      : super(key: key);

  @override
  State<ReservationCountdown> createState() => _ReservationCountdownState();
}

class _ReservationCountdownState extends State<ReservationCountdown> {
  var appBarHeight = 95.61904761904762;
  int time = 29;
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  var firestoreResService = FirestoreReservationService();
  var myDB = FirebaseFirestore.instance;
  List<Map<String, dynamic>> allUserBookings = [];
  Timer? countdownTimer;
  final CountDownController _controller = CountDownController();
  int bookingDuration = -1;
  bool minutes5BeforeStartReached = false, bookingHasEnded = false, bookingHasStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.canShowToggle(true));
    NotificationListenerProvider().getMessage(context);
    debugPrint("INITIALIZING NOTIF LISTENER FROM MAIN");
    getToken();
  }

  void getToken() async {
    final token = await firebaseMessaging.getToken();
    debugPrint("THE TOKEN $token");
  }

  void showNotification(String title, String messagebody) {
    //setState(() {});

    sendNotification(title: title, body: messagebody);
  }

  @override
  Widget build(BuildContext context) {
    /*  double panelBodyHeight =
        MediaQuery.of(context).size.height - MediaQuery.of(context).size.height * 0.1 - appBarHeight; */
    CollectionReference okeeee = myDB.collection("users");
    okeeee.get().then((value) => debugPrint("CHECH ${value.size}"));
    String durationToString(int minutes) {
      var d = Duration(minutes: minutes);
      List<String> parts = d.toString().split(':');
      return '${parts[0].padLeft(2, '0')}h ${parts[1].padLeft(2, '0')}mn';
    }

    int timeUntilResStarts = 0, timeUntilBookingEnds = 0;
    TimeRange selectedTimeInterval;
    Timestamp bookingEndTS, bookingStartTS;
    allUserBookings =
        widget.allReservationInfoNeeded.isNotEmpty ? widget.allReservationInfoNeeded['allUserBookings'] : [];
    List<Map<String, dynamic>> userResEntries, userCarsEntries;
    Map<String, dynamic> moreUrgentReservationInfo, moreUrgentParkingInfo = {};

    if (widget.allReservationInfoNeeded.isNotEmpty) {
      //widget.canShowToggle(true);

      userResEntries = widget.allReservationInfoNeeded.entries.first.value;
      moreUrgentReservationInfo = userResEntries.first.values.first as Map<String, dynamic>;
      bookingEndTS = moreUrgentReservationInfo['BookingEnd'] as Timestamp;
      bookingStartTS = moreUrgentReservationInfo['BookingStart'] as Timestamp;
      selectedTimeInterval = TimeRange(
          startTime: TimeOfDay.fromDateTime(bookingStartTS.toDate()),
          endTime: TimeOfDay.fromDateTime(bookingEndTS.toDate()));
      bookingDuration = (selectedTimeInterval.endTime.hour * 60 + selectedTimeInterval.endTime.minute) -
          (selectedTimeInterval.startTime.hour * 60 + selectedTimeInterval.startTime.minute);
      (bookingStartTS.toDate().difference(DateTime.now())).inSeconds > 0
          ? timeUntilResStarts = (bookingStartTS.toDate().difference(DateTime.now())).inSeconds
          : null;
      (bookingEndTS.toDate().difference(DateTime.now())).inSeconds > 0
          ? timeUntilBookingEnds = (bookingEndTS.toDate().difference(DateTime.now())).inSeconds
          : null;

      userCarsEntries = widget.allReservationInfoNeeded.entries.elementAt(1).value;
      //userCarsEntries.first.values.where((element) => element)
      // moreUrgentReservationInfo
      Iterable<Map<String, dynamic>> moreUrentResMatchingParkingIDInfo = userCarsEntries.where((element) {
        var ok = element.keys.first;
        ok == userResEntries.first.keys.first;

        return ok == moreUrgentReservationInfo['ParkingID'];
      });

      moreUrgentParkingInfo =
          moreUrentResMatchingParkingIDInfo.isNotEmpty ? moreUrentResMatchingParkingIDInfo.first : {};
      // ignore: unnecessary_brace_in_string_interps
      debugPrint(
          "AZERTY $moreUrgentParkingInfo _ ${moreUrgentReservationInfo['ParkingID']}  ___ ${widget.currentlySignedInUser?.displayName}");
      //
      timeUntilBookingEnds == 1150 ? debugPrint("28 MINUTES LEFT") : null;
      /* timeUntilResStarts == const Duration(seconds: 20).inSeconds && timeUntilBookingEnds == 0
          ? {
              debugPrint('starts soon'),
              showNotification('Booking starting soon.',
                  'Hello ${widget.currentlySignedInUser?.displayName}, Your booking in ${moreUrgentParkingInfo.values.first['Name']} starts in 5 minutes!')
            }
          : timeUntilResStarts == 0 && timeUntilBookingEnds == 500
              ? showNotification('Booking ends soon.',
                  'Hello ${widget.currentlySignedInUser?.displayName}, Your booking in ${moreUrgentParkingInfo.values.first['Name']} ends in 5 minutes!')
              : null; */
      //
      if (mounted) {
        setState(
          () {},
        );
      }
    }

    debugPrint(
        "bookingdur $bookingDuration __ timeUntilBookingEnds $timeUntilBookingEnds _____ timeUntilResStarts $timeUntilResStarts");

    return SingleChildScrollView(
      child: Column(children: [
        bookingDuration == -1
            ? Container()
            : /* widget.allReservationInfoNeeded.isEmpty
                ? noBookingSoFar()
                : */
            bookingDuration > 0 && timeUntilResStarts > 0
                ? bookingStartsIn(
                    bookingDuration, durationToString(bookingDuration), timeUntilResStarts, moreUrgentParkingInfo)
                : bookingHasStarted == true ||
                        bookingDuration > 0 && timeUntilBookingEnds > 0 && timeUntilResStarts == 0
                    ? bookingTimeLeft(
                        timeUntilBookingEnds, bookingDuration, durationToString(bookingDuration), moreUrgentParkingInfo)
                    : noBookingSoFar(),
        /*  buttonsRow
        
         Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 30,
              ),
              _button(
                title: "Start",
                onPressed: () => _controller.start(),
              ),
              const SizedBox(
                width: 10,
              ),
              _button(
                title: "Pause",
                onPressed: () => _controller.pause(),
              ),
              const SizedBox(
                width: 10,
              ),
              _button(
                title: "Resume",
                onPressed: () => _controller.resume(),
              ),
              const SizedBox(
                width: 10,
              ),
              _button(
                title: "Restart",
                onPressed: () => _controller.restart(duration: _duration),
              ),
            ],
          ),
        */
        FloatingActionButton(
          onPressed: () => showNotification('Hello Maguy', 'Notifications Finally working'),
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        )
      ]),
    );
  }

  Widget button({required String title, VoidCallback? onPressed}) {
    return Expanded(
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.purple),
        ),
        onPressed: onPressed,
        child: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  bookingStartsIn(int bd, String durationToString, int timeUntilResStarts, Map<String, dynamic> moreUrgentParkingInfo) {
    const timeLeftHeaderText =
        TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'OpenSans');

    debugPrint(
        "TIME UNTIL STARTS $timeUntilResStarts _______ ${widget.timeUntilResFetchedFromBookingOverview}  ___ minutes5Reached $minutes5BeforeStartReached");
    return Padding(
      padding: const EdgeInsets.only(left: 22, right: 20),
      child: Stack(
        alignment: Alignment.bottomCenter,
        fit: StackFit.passthrough,
        children: [
          CircularCountDownTimer(
            duration: //timeUntilResStarts,
                timeUntilResStarts < widget.timeUntilResFetchedFromBookingOverview
                    ? timeUntilResStarts
                    : widget.timeUntilResFetchedFromBookingOverview == 0
                        ? timeUntilResStarts
                        : widget.timeUntilResFetchedFromBookingOverview,
            isReverse: true,
            initialDuration: 0,
            controller: _controller,
            width: 400,
            height: 400,
            ringColor: Colors.grey[300]!,
            ringGradient: null,
            fillColor: Colors.purpleAccent[100]!,
            fillGradient: null,
            backgroundColor: Colors.purple[500],
            backgroundGradient: null,
            strokeWidth: 20.0,
            strokeCap: StrokeCap.round,
            textStyle: const TextStyle(fontSize: 33.0, color: Colors.white, fontWeight: FontWeight.bold, height: -3.5),
            textFormat: CountdownTextFormat.HH_MM_SS,
            isReverseAnimation: true,
            isTimerTextShown: true,
            autoStart: true,
            onStart: () {
              debugPrint('Countdown Started');
            },
            onComplete: () {
              debugPrint('Countdown Ended');
              minutes5BeforeStartReached == true
                  ? {
                      showNotification('Booking just started!',
                          'Hello ${widget.currentlySignedInUser?.displayName}, Your booking in ${moreUrgentParkingInfo.values.first['Name']} just started!'),
                      bookingHasStarted = true,
                      debugPrint('just started'),
                      const BadgesNotifications(),
                    }
                  : null;
            },
            onChange: (String timeStamp) {
              debugPrint('Countdown Changed $timeStamp ______ ${timeStamp.split(':').elementAt(0).trim()}');
              (int.parse(timeStamp.split(':').elementAt(0).trim()) * 3600 +
                          int.parse(timeStamp.split(':').elementAt(1).trim()) * 60 +
                          int.parse(timeStamp.split(':').elementAt(2).trim())) ==
                      300
                  ? {
                      debugPrint('starts soon'),
                      minutes5BeforeStartReached = true,
                      minutes5BeforeStartReached == true
                          ? showNotification('Booking starting soon.',
                              'Hello ${widget.currentlySignedInUser?.displayName}, Your booking in ${moreUrgentParkingInfo.values.first['Name']} starts in 5 minutes!')
                          : null,
                      /*   showNotification('Booking starting soon.',
                          'Hello ${widget.currentlySignedInUser?.displayName}, Your booking in ${moreUrgentParkingInfo.values.first['Name']} starts in 5 minutes!') */
                    }
                  : null;
            },
          ),
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: FittedBox(
                  child: Text(
                    "UNTIL BOOKING STARTS",
                    style: timeLeftHeaderText,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15, right: 10, bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        /* const Icon(
                          Icons.location_pin,
                          size: 20,
                        ),
                        const SizedBox(
                          width: 15,
                        ), */
                        TextButton.icon(
                            style: TextButton.styleFrom(backgroundColor: Colors.black.withOpacity(0.5), elevation: 5),
                            onPressed: () {
                              var ok = moreUrgentParkingInfo.values.first as Map<String, dynamic>;

                              var infos = ok['Positions'] as GeoPoint;

                              setState(() {
                                widget.canShowToggle(false);
                              });
                              MapsLauncher.launchCoordinates(infos.latitude, infos.longitude);

                              //widget.getIndex(1);

                              /*  setState(() {
                                BookingPage(parkingToNavigateTo: moreUrgentParkingInfo);
                              }); */
                              /* if (!mounted) return;
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Home(
                                            fromLoginView: true,
                                            parkingToNavigateTo: moreUrgentParkingInfo,
                                            newIndex: 1,
                                          ))); */
                            },
                            label: SizedBox(
                              width: 100,
                              child: Text('Navigate to ${moreUrgentParkingInfo.values.first['Name']}',
                                  style: const TextStyle(
                                      overflow: TextOverflow.fade,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Color.fromARGB(255, 242, 242, 242))),
                            ),
                            icon: const Icon(Icons.navigation_rounded)),
                      ],
                    ),
                    /* const Padding(
                      padding: EdgeInsets.only(left: 10, top: 3),
                      child: FittedBox(
                        child: Text("Daker, Senegal",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w900, color: Color.fromARGB(255, 236, 255, 240))),
                      ),
                    ), */
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      fit: StackFit.passthrough,
                      children: [
                        Positioned(
                          right: 15,
                          top: 10,
                          child: Card(
                            //color: Colors.orange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 20,
                            child: Container(
                              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)),
                              height: 50,
                              width: 80,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const FittedBox(
                                    child: Text(
                                      'Duration',
                                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          style: const TextStyle(
                                              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                                          children: [
                                            TextSpan(
                                              text: durationToString.substring(0, 2),
                                            ),
                                            WidgetSpan(
                                              child: Transform.translate(
                                                offset: const Offset(0.0, -7.0),
                                                child: const Text(
                                                  'H',
                                                  style: TextStyle(
                                                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
                                                ),
                                              ),
                                            ),
                                            TextSpan(
                                              text: ' ${durationToString.substring(4, 6)}',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Image(
                          image: const AssetImage('assets/images/carRep/dacia.png'),
                          // width: 400,
                          height: MediaQuery.of(context).size.height / 3 -
                              120, //50 is toolbar height and 10 is the padding above bottombar
                          fit: BoxFit.scaleDown,
                        )
                      ],
                    ),
                  ),
                ],
              ),
              const FittedBox(
                child: Text(
                  "PEUGEOT MODEL 2008",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color.fromARGB(255, 82, 35, 35)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  bookingTimeLeft(int timeUntilBookingEnds, int bookingDuration, String durationToString,
      Map<String, dynamic> moreUrgentParkingInfo) {
    const timeLeftHeaderText =
        TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'OpenSans');
    debugPrint("TIME UNTIL ENDS $timeUntilBookingEnds  ___ ");
    return Padding(
      padding: const EdgeInsets.only(left: 22, right: 20),
      child: Stack(
        alignment: Alignment.bottomCenter,
        fit: StackFit.passthrough,
        children: [
          CircularCountDownTimer(
            duration: timeUntilBookingEnds,
            isReverse: true,
            initialDuration: 0,
            controller: _controller,
            width: 400,
            height: 400,
            ringColor: Colors.grey[300]!,
            ringGradient: null,
            fillColor: Colors.purpleAccent[100]!,
            fillGradient: null,
            backgroundColor: Colors.green[500],
            backgroundGradient: null,
            strokeWidth: 20.0,
            strokeCap: StrokeCap.round,
            textStyle: const TextStyle(fontSize: 33.0, color: Colors.white, fontWeight: FontWeight.bold, height: -3.5),
            textFormat: CountdownTextFormat.HH_MM_SS,
            isReverseAnimation: true,
            isTimerTextShown: true,
            autoStart: true,
            onStart: () {
              debugPrint('Countdown Started');
            },
            onComplete: () {
              debugPrint('Countdown Ended');
              showNotification('Booking just ended!',
                  'Hello ${widget.currentlySignedInUser?.displayName}, Your booking in ${moreUrgentParkingInfo.values.first['Name']} has just ended!');
              bookingHasEnded = true;
              debugPrint('just ended');
            },
            onChange: (String timeStamp) {
              debugPrint('Countdown Changed $timeStamp  ______ ${timeStamp.split(':').elementAt(0).trim()}');
              (int.parse(timeStamp.split(':').elementAt(0).trim()) * 3600 +
                          int.parse(timeStamp.split(':').elementAt(1).trim()) * 60 +
                          int.parse(timeStamp.split(':').elementAt(2).trim())) ==
                      300
                  ? {
                      debugPrint('ends soon'),
                      minutes5BeforeStartReached = true,
                      minutes5BeforeStartReached == true
                          ? showNotification('Booking ends soon.',
                              'Hello ${widget.currentlySignedInUser?.displayName}, Your booking in ${moreUrgentParkingInfo.values.first['Name']} ends in 5 minutes!')
                          : null,
                    }
                  : null;
            },
          ),
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: FittedBox(
                  child: Text(
                    "UNTIL BOOKING END",
                    style: timeLeftHeaderText,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15, right: 10, bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                            style: TextButton.styleFrom(backgroundColor: Colors.black.withOpacity(0.5), elevation: 5),
                            onPressed: () {
                              var ok = moreUrgentParkingInfo.values.first as Map<String, dynamic>;

                              var infos = ok['Positions'] as GeoPoint;
                              MapsLauncher.launchCoordinates(infos.latitude, infos.longitude);
                            },
                            label: const SizedBox(
                              width: 100,
                              child: Text('Navigate to ECPI Smart Parking',
                                  style: TextStyle(
                                      overflow: TextOverflow.fade,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Color.fromARGB(255, 242, 242, 242))),
                            ),
                            icon: const Icon(Icons.navigation_rounded)),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      fit: StackFit.passthrough,
                      children: [
                        Positioned(
                          right: 15,
                          top: 10,
                          child: Card(
                            //color: Colors.orange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 20,
                            child: Container(
                              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)),
                              height: 50,
                              width: 80,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const FittedBox(
                                    child: Text(
                                      'Duration',
                                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          style: const TextStyle(
                                              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                                          children: [
                                            TextSpan(
                                              text: durationToString.substring(0, 2),
                                            ),
                                            WidgetSpan(
                                              child: Transform.translate(
                                                offset: const Offset(0.0, -7.0),
                                                child: const Text(
                                                  'H',
                                                  style: TextStyle(
                                                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
                                                ),
                                              ),
                                            ),
                                            TextSpan(
                                              text: ' ${durationToString.substring(4, 6)}',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Image(
                          image: const AssetImage('assets/images/carRep/dacia.png'),
                          // width: 400,
                          height: MediaQuery.of(context).size.height / 3 -
                              120, //50 is toolbar height and 10 is the padding above bottombar
                          fit: BoxFit.scaleDown,
                        )
                      ],
                    ),
                  ),
                ],
              ),
              const FittedBox(
                child: Text(
                  "PEUGEOT MODEL 2008",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color.fromARGB(255, 82, 35, 35)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  noBookingSoFar() {
    const timeLeftHeaderText =
        TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'OpenSans');

    debugPrint("NO BOOKING SO FAR");
    return Padding(
      padding: const EdgeInsets.only(left: 22, right: 20),
      child: Stack(
        alignment: Alignment.bottomCenter,
        fit: StackFit.passthrough,
        children: [
          CircularCountDownTimer(
            duration: 0,
            isReverse: true,
            initialDuration: 0,
            controller: _controller,
            width: 400,
            height: 400,
            ringColor: Colors.grey[300]!,
            ringGradient: null,
            fillColor: Colors.purpleAccent[100]!,
            fillGradient: null,
            backgroundColor: Colors.transparent,
            backgroundGradient: null,
            strokeWidth: 20.0,
            strokeCap: StrokeCap.round,
            textStyle: const TextStyle(fontSize: 33.0, color: Colors.white, fontWeight: FontWeight.bold, height: -3.5),
            textFormat: CountdownTextFormat.HH_MM_SS,
            isReverseAnimation: true,
            isTimerTextShown: true,
            autoStart: true,
            onStart: () {
              debugPrint('Countdown Started');
            },
            onComplete: () {
              debugPrint('Countdown Ended');
            },
            onChange: (String timeStamp) {
              debugPrint('Countdown Changed $timeStamp');
            },
          ),
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: FittedBox(
                  child: Text(
                    "UNTIL BOOKING STARTS",
                    style: timeLeftHeaderText,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15, right: 10, bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        /*      TextButton.icon(
                            style: TextButton.styleFrom(backgroundColor: Colors.black.withOpacity(0.5), elevation: 5),
                            onPressed: () {
                           
                              setState(() {
                                widget.canShowToggle(false);
                              });
                          

                              widget.getIndex(1);

                              /*  setState(() {
                                BookingPage(parkingToNavigateTo: moreUrgentParkingInfo);
                              }); */
                              if (!mounted) return;
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Home(
                                            fromLoginView: true,
                                            parkingToNavigateTo: {},
                                            newIndex: 1, timeUntilResStarts: 0,

                                          )));
                            },
                            label: const SizedBox(
                              width: 100,
                              child: Text('Navigate to ECPI Smart Parking',
                                  style: TextStyle(
                                      overflow: TextOverflow.fade,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Color.fromARGB(255, 242, 242, 242))),
                            ),
                            icon: const Icon(Icons.navigation_rounded)),
                  */
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      fit: StackFit.passthrough,
                      children: [
                        Positioned(
                          right: 15,
                          top: 10,
                          child: Card(
                            //color: Colors.orange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 20,
                            child: Container(
                              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)),
                              height: 50,
                              width: 80,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const FittedBox(
                                    child: Text(
                                      'Duration',
                                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          style: const TextStyle(
                                              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                                          children: [
                                            const TextSpan(
                                              text: "00",
                                            ),
                                            WidgetSpan(
                                              child: Transform.translate(
                                                offset: const Offset(0.0, -7.0),
                                                child: const Text(
                                                  'H',
                                                  style: TextStyle(
                                                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
                                                ),
                                              ),
                                            ),
                                            const TextSpan(
                                              text: '00',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Image(
                          image: const AssetImage('assets/images/carRep/dacia.png'),
                          // width: 400,
                          height: MediaQuery.of(context).size.height / 3 -
                              120, //50 is toolbar height and 10 is the padding above bottombar
                          fit: BoxFit.scaleDown,
                        )
                      ],
                    ),
                  ),
                ],
              ),
              const FittedBox(
                child: Text(
                  "PEUGEOT MODEL 2008",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color.fromARGB(255, 82, 35, 35)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  /*  bookingCountdown(days, hours, minutes, seconds) {
    var hasResStarted = allUserBookings.any((element) {
      var reservationInfo = element.values.first as Map<String, dynamic>;
      return reservationInfo['ReservationStatus']['Started'] == true;
    });

    debugPrint('hasResStarted $hasResStarted');
    return hasResStarted == true ? bookingTimeLeft() : bookingStartsIn(bookingDuration);
  } */
}

/* 


// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'dart:async';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_parking/services/firebase/firestore_service.dart';
import 'package:smart_parking/styling/styling.dart';

class ReservationCountdown extends StatefulWidget {
  final User? currentlySignedInUser;
  final Map<String, dynamic> allReservationInfoNeeded;

  const ReservationCountdown({Key? key, required this.currentlySignedInUser, required this.allReservationInfoNeeded})
      : super(key: key);

  @override
  State<ReservationCountdown> createState() => _ReservationCountdownState();
}

class _ReservationCountdownState extends State<ReservationCountdown> {
  var appBarHeight = 95.61904761904762;
  int time = 29;
  var firestoreResService = FirestoreReservationService();
  var myDB = FirebaseFirestore.instance;
  List<Map<String, dynamic>> allUserBookings = [], allBookedParkingsDetails = [], allUserVehiculesUsedForBooking = [];
  Map<String, dynamic> allReservationInfoNeeded = {}, ok = {};
  Set allParkingIDsConcerned = {};
  Timer? countdownTimer;
  Duration myDuration = const Duration(minutes: 400);
  final CountDownController _controller = CountDownController();
  int _duration = 10;
  String display = '00:00:00';

  @override
  void initState() {
    // startTimer();
    super.initState();
  }

  //var counter = 3;
  void setCountDown() {
    const reduceSecondsBy = 1;
    if (mounted) {
      final seconds = myDuration.inSeconds - reduceSecondsBy;
      if (seconds < 0) {
        countdownTimer!.cancel();
      } else {
        myDuration = Duration(seconds: seconds);
      }
    }
  }

  void startTimer() {
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => setCountDown());
  }

  // Step 4
  void stopTimer() {
    setState(() => countdownTimer!.cancel());
  }

  // Step 5
  void resetTimer() {
    stopTimer();
    setState(() => myDuration = const Duration(days: 5));
  }
  // Step 6

  @override
  Widget build(BuildContext context) {
    String strDigits(int n) => n.toString().padLeft(2, '0');
    final days = strDigits(myDuration.inDays);
    final hours = strDigits(myDuration.inHours.remainder(24));
    final minutes = strDigits(myDuration.inMinutes.remainder(60));
    final seconds = strDigits(myDuration.inSeconds.remainder(60));

    double panelBodyHeight =
        MediaQuery.of(context).size.height - MediaQuery.of(context).size.height * 0.1 - appBarHeight;

    allUserBookings =
        widget.allReservationInfoNeeded.isNotEmpty ? widget.allReservationInfoNeeded['allUserBookings'] : [];
    debugPrint("allUserBookings $allUserBookings");
    return SingleChildScrollView(
      child: Column(children: [
        allUserBookings.isEmpty
            ? noBookingSoFar()
            : bookingCountdown(
                days,
                hours,
                minutes,
                seconds,
              ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 30,
            ),
            _button(
              title: "Start",
              onPressed: () => _controller.start(),
            ),
            const SizedBox(
              width: 10,
            ),
            _button(
              title: "Pause",
              onPressed: () => _controller.pause(),
            ),
            const SizedBox(
              width: 10,
            ),
            _button(
              title: "Resume",
              onPressed: () => _controller.resume(),
            ),
            const SizedBox(
              width: 10,
            ),
            _button(
              title: "Restart",
              onPressed: () => _controller.restart(duration: _duration),
            ),
          ],
        ),
      ]),
    );
  }

  Widget _button({required String title, VoidCallback? onPressed}) {
    return Expanded(
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.purple),
        ),
        onPressed: onPressed,
        child: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  bookingStartsIn(
    days,
    hours,
    minutes,
    seconds,
  ) {
    const timeLeftHeaderText =
        TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'OpenSans');

    return Stack(
      alignment: Alignment.center,
      fit: StackFit.passthrough,
      children: [
        CircularCountDownTimer(
          duration: 400,
          isReverse: true,
          initialDuration: 0,
          controller: _controller,
          width: 400,
          height: 400,
          ringColor: Colors.grey[300]!,
          ringGradient: null,
          fillColor: Colors.purpleAccent[100]!,
          fillGradient: null,
          backgroundColor: Colors.purple[500],
          backgroundGradient: null,
          strokeWidth: 20.0,
          strokeCap: StrokeCap.round,
          textStyle: const TextStyle(fontSize: 33.0, color: Colors.white, fontWeight: FontWeight.bold, height: -3),
          textFormat: CountdownTextFormat.HH_MM_SS,
          isReverseAnimation: true,
          isTimerTextShown: true,
          autoStart: false,
          onStart: () {
            debugPrint('Countdown Started');
          },
          onComplete: () {
            debugPrint('Countdown Ended');
          },
          onChange: (String timeStamp) {
            debugPrint('Countdown Changed $timeStamp');
            showText(timeStamp);
          },
        ),
        Positioned(
            top: 150,
            child: Column(
              children: [
                Image(
                  image: const AssetImage('assets/images/carRep/dacia.png'),
                  width: 400,
                  height: MediaQuery.of(context).size.height / 3 -
                      50, //50 is toolbar height and 10 is the padding above bottombar
                  fit: BoxFit.scaleDown,
                ),
              ],
            ))
      ],
    );

    /*  Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: FittedBox(
            child: Text(
              "YOUR BOOKING STARTS IN",
              style: timeLeftHeaderText,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 15,
              width: 15,
              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(6)),
            ),
            const SizedBox(
              width: 15,
            ),
            Flexible(
              child: FittedBox(
                child: Text(
                  '$hours:$minutes:$seconds',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 40),
                ),
              ),
            ),
          ],
        ),

        Row(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                fit: StackFit.passthrough,
                children: [
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Card(
                      //color: Colors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 20,
                      child: Container(
                        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(15)),
                        height: 60,
                        width: 100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900),
                                children: [
                                  const TextSpan(
                                    text: '2',
                                  ),
                                  WidgetSpan(
                                    child: Transform.translate(
                                      offset: const Offset(0.0, -12.0),
                                      child: Text(
                                        'H',
                                        style:
                                            TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' 30',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Image(
                    image: const AssetImage('assets/images/carRep/dacia.png'),
                    width: 400,
                    height: MediaQuery.of(context).size.height / 3 -
                        50, //50 is toolbar height and 10 is the padding above bottombar
                    fit: BoxFit.scaleDown,
                  )
                ],
              ),
            ),
          ],
        ),

        const FittedBox(
          child: Text(
            "PEUGEOT MODEL 2008",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.grey),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 15, right: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_pin,
                    size: 25,
                  ),
                  const SizedBox(
                    width: 15,
                  ),
                  FittedBox(
                    child: Text('ECPI Smart Parking',
                        style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Colors.black)),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 10, top: 5),
                child: FittedBox(
                  child: Text("Daker, Senegal",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color.fromARGB(169, 99, 15, 15))),
                ),
              ),
            ],
          ),
        ),

        //Container(height: 100, color: Colors.green),
      ],
    ); */
  }

  bookingTimeLeft(days, hours, minutes, seconds) {
    return Container(height: 100, color: Colors.orange);
  }

  noBookingSoFar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
      child: Column(
        children: [
          Container(height: 100, color: Colors.purple),
        ],
      ),
    );
  }

  bookingCountdown(days, hours, minutes, seconds) {
    var hasResStarted = allUserBookings.any((element) {
      var reservationInfo = element.values.first as Map<String, dynamic>;
      return reservationInfo['ReservationStatus']['Started'] == true;
    });

    debugPrint('hasResStarted $hasResStarted');
    return hasResStarted == true
        ? bookingTimeLeft(days, hours, minutes, seconds)
        : bookingStartsIn(days, hours, minutes, seconds);
  }

  showText(String timeStamp) {
    return display = timeStamp;
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

 */
