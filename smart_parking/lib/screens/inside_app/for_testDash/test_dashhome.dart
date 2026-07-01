// ignore_for_file: unused_local_variable

import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:smart_parking/models/common/theme_helper.dart';
import 'package:smart_parking/notifiers/booking_state_management.dart';
import 'package:smart_parking/screens/inside_app/for_testDash/test_panel.dart';
import 'package:smart_parking/services/firebase/firebase_service.dart';
import 'package:smart_parking/services/firebase/firestore_service.dart';
import 'package:smart_parking/services/local_notifications/notification.dart';
import 'package:time_range_picker/time_range_picker.dart';

import '../../../services/local_notifications/firebase_message_provider.dart';

class TestDashboardHomePage extends StatefulWidget {
  final int timeUntilResStartsFromBookingOverview;
  final Map<String, dynamic> newMoreUrgentBooking;
  final Function(bool canShow) canShowToggle;
  const TestDashboardHomePage(
      {super.key,
      this.timeUntilResStartsFromBookingOverview = 0,
      required this.newMoreUrgentBooking,
      required this.canShowToggle});

  @override
  State<TestDashboardHomePage> createState() => _TestDashboardHomePageState();
}

class _TestDashboardHomePageState extends State<TestDashboardHomePage> {
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  int timeUntilResStarts = 0,
      timeUntilBookingEnds = 0,
      countStop = 0,
      stopSettingStateAfterNewBookingMade = 0;

  String walletFirstAndOnlyDocID = '';
  late String defaultCarModelDetail = "", defaultCarBrand = 'dacia';
  late User? currentlySignedInUser;
  Set allParkingIDsConcerned = {};
  int count = 0, setStateCount = 0, stopDeletingCount = 0;
  final panelScrollController = ScrollController();
  final dragHandlePanelController = PanelController();
  var myDB = FirebaseFirestore.instance;
  var firebaseService = FirebaseService();
  var firestoreWalletService = FirestoreWalletService();
  bool canUpdateFields = false,
      userHasNoVehicules = false,
      minutes5BeforeStartReached = false,
      bookingHasEnded = false,
      bookingHasStarted = false,
      userIsInteractingLive = false,
      canDisplayVehicule = false,
      showBookingDetails = false,
      isReservationCanceled = false;

  List<Map<String, dynamic>> allUserBookings = [],
      allBookedParkingsDetails = [],
      allUserVehiculesUsedForBooking = [];
  List<TimeOfDay> fetchedParkingTimeSlots = [];
  Map<String, dynamic> allReservationInfoNeeded = {};
  final CountDownController _countdownController = CountDownController();
  ScrollController bookingInfoScrollController = ScrollController(),
      singleChildScrollController = ScrollController();
  int settingState = 0, bookingDuration = 0, infSliverCount = 3;
  late ValueNotifier<bool> bookingOnGoingListenable = ValueNotifier(false);
  Map<String, dynamic> latestQuerySnapshotCarriedInMapAfterArchive = {},
      newDocsAfterNewBookingMade = {};
  Color modelDetailColor = Colors.black,
      infSliverCardColor = Colors.white; //.grey[300]!;
  Timestamp bookingEndTS = Timestamp.now(), bookingStartTS = Timestamp.now();
  final sliverkEY = GlobalKey();
  double infSliverHeight = 50, infSliverSpace = 10;
  //var previousBooking

  @override
  void initState() {
    //CHECK CONNEXION STATUS
    NotificationListenerProvider().getMessage(context);
    getToken();
    widget.timeUntilResStartsFromBookingOverview != 0
        ? canDisplayVehicule = true
        : null;
    firebaseService.auth.currentUser != null
        ? {
            setState(() {
              currentlySignedInUser = firebaseService.auth.currentUser;
            }),
            /*  checkForOutdatedReservations(currentlySignedInUser!), */
            initializeWalletForUser(currentlySignedInUser!),
            widget.timeUntilResStartsFromBookingOverview != 0
                ? getNewSlotsReservationsData(currentlySignedInUser!)
                : null,
            loadVehiculeInfo(currentlySignedInUser!)
                .whenComplete(() => setState(() {}))
          }
        : currentlySignedInUser = null;

    super.initState();
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
  void dispose() {
    super.dispose();
  }

  void updateWalletFields(QuerySnapshot<Map<String, dynamic>> walletCollection,
      String walletFirstAndOnlyDocID) {
    CollectionReference debitsCollection = myDB.collection(
        "users/${currentlySignedInUser?.uid}/wallet/$walletFirstAndOnlyDocID/debits");
    CollectionReference topUpsCollection = myDB.collection(
        "users/${currentlySignedInUser?.uid}/wallet/$walletFirstAndOnlyDocID/topUps");

    debugPrint("WALLETDOCS :${walletCollection.docs.first.id}");
    final theDocToUpdate = myDB
        .collection("users/${currentlySignedInUser?.uid}/wallet")
        .doc(walletCollection.docs.first.id);

    /*  var ok = walletCollection.docs.first.data()['Transactions']['Top Ups'] as Map<String, dynamic>; */
    /*  var ok = walletCollection.docs.first.data()['Transactions']['Top Ups'] as Map<String, dynamic>; */
    topUpsCollection.get().then((value) {
      List allIDList = [];
      for (var element in value.docs) {
        allIDList.add(element.id);
        //debugPrint("YOURE HERE _ $ok _ _ $allIDList");
      }

      theDocToUpdate.update({'Transactions.Top Ups.IDs': allIDList});
    });
  }

  Future<void> initializeWalletForUser(User currentlySignedInUser) async {
    myDB
        .collection("users/${currentlySignedInUser.uid}/wallet")
        .get()
        .then((value) async {
      value.docs.isEmpty
          ? {
              await firestoreWalletService
                  .addUserWalletInfoToFirebase(currentlySignedInUser)
                  .then((value) {
                myDB
                    .collection("users/${currentlySignedInUser.uid}/wallet")
                    .get()
                    .then((value) => value.docs.first.id)
                    .then(
                  (value) {
                    debugPrint("WALLET ID: $value}");
                    setState(() {
                      walletFirstAndOnlyDocID = value;
                    });
                  },
                );
              })
            }
          : debugPrint('XROTE WRITE');
    });
  }

  Future<void> loadVehiculeInfo(User currentlySignedInUser) async {
    var hasUserAnyRes = false;
    try {
      await myDB.collection("slotsReservations").get().then((value) {
        if (value.docs.isNotEmpty) {
          var docs = value.docs;

          hasUserAnyRes = getUserReservationDetails(
              currentlySignedInUser, myDB, docs, value,
              forInitiState: true);
        }
      });
      debugPrint("FROM INITSATAE $hasUserAnyRes");
      await FirebaseFirestore.instance
          .collection("users/${currentlySignedInUser.uid}/vehicules")
          .get()
          .then((value) {
        if (!hasUserAnyRes) {
          if (value.docs.isNotEmpty) {
            var ok = value.docs.where(
              (element) {
                return element.data()['Currently Selected'] == true;
              },
            );
            ok.isNotEmpty
                ? setState(() {
                    defaultCarModelDetail =
                        ok.first.data()['Specs']['Model Detail'].toString();
                    defaultCarBrand = ok.first
                        .data()['Specs']['Brand']
                        .toString()
                        .toLowerCase();
                  })
                : setState(() {
                    defaultCarModelDetail = "";
                    defaultCarBrand = "dacia";
                  });
            setState(() {
              canDisplayVehicule = true;
            });
          }
        } else {
          if (allUserBookings.isNotEmpty &&
              allUserVehiculesUsedForBooking.isNotEmpty &&
              allBookedParkingsDetails.isNotEmpty) {
            var moreUrgentReservationInfo = fetchMoreUrgentReservationInfo();
            var moreUrgentResCarInfo =
                fetchMoreUrgentResCarInfo(moreUrgentReservationInfo);
            //  var moreUrgentResParkingInfo = fetchMoreUrgentResParkingInfo(moreUrgentReservationInfo);
            setState(() {
              defaultCarModelDetail =
                  moreUrgentResCarInfo['Specs']['Model Detail'].toString();
              defaultCarBrand = moreUrgentResCarInfo['Specs']['Brand']
                  .toString()
                  .toLowerCase();
              canDisplayVehicule = true;
            });
          }
        }

        debugPrint("THE FIRST : $defaultCarModelDetail");
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    double panelHeightClosed =
        kToolbarHeight /* MediaQuery.of(context).size.height * 0.05 */;
    double panelHeightOpened = MediaQuery.of(context).size.height * 0.4;

    //testForWalletInit
    walletFirstAndOnlyDocID == ''
        ? null
        : {
            canUpdateFields == true
                ? null
                : {
                    myDB
                        .collection(
                            "users/${currentlySignedInUser?.uid}/wallet")
                        .get()
                        .then((value) async {
                      //debugPrint("CHECK MIC: ${value.docs.length}");
                    }),
                    firestoreWalletService
                        .initializeWalletDebitTopUp(
                            currentlySignedInUser, walletFirstAndOnlyDocID)
                        .whenComplete(() {
                      count < 1
                          ? Future.delayed(const Duration(seconds: 2)).then(
                              (value) {
                                setState(
                                  () {
                                    canUpdateFields = true;
                                  },
                                );
                              },
                            )
                          : null;
                      count += 1;
                    })
                  }
          };
    canUpdateFields == false && countStop < 1
        ? null
        : {
            myDB
                .collection("users/${currentlySignedInUser?.uid}/wallet")
                .get()
                .then((value) async {
              updateWalletFields(value, walletFirstAndOnlyDocID);
              //debugPrint("DOUBLE MIC: ${value.docs.length}");
            }),
            countStop += 1
          };

    /* widget.timeUntilResStartsFromBookingOverview != 0
        ? stopSettingStateAfterNewBookingMade < 1
            ? {
                Future.delayed(Duration(seconds: 1), () {
                  // bookingOnGoingListenable.value = true;
                  //widget.
                  setState(
                    () {},
                  );
                }),
                stopSettingStateAfterNewBookingMade += 1
              }
            : null
        : null; */
    return GestureDetector(
      onTap: () => setState(() {
        userIsInteractingLive = true;
      }),
      onVerticalDragStart: (details) => setState(() {
        userIsInteractingLive = true;
      }),
      child: Scaffold(
          //backgroundColor: const Color(0xff392850),
          //backgroundColor: Colors.white,
          body: dashBSlidingUpPanel(panelHeightClosed, panelHeightOpened)),
    );
  }

  void updateDashboardCar(String carModelFromPanel, String carBrandFromPanel) {
    settingState = 0;
    defaultCarModelDetail = carModelFromPanel;
    defaultCarBrand = carBrandFromPanel;
    setState(() {});
  }

  StreamBuilder<QuerySnapshot<Map<String, dynamic>>> dashBSlidingUpPanel(
      double panelHeightClosed, double panelHeightOpened) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection("slotsReservations")
            .snapshots(includeMetadataChanges: true),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Text(''); //Text('Loading brand logos');
          } else {
            var doesUserHaveAnyReservation = false;
            var reservationsSnapshotsData = snapshot.data!;
            if (latestQuerySnapshotCarriedInMapAfterArchive.isNotEmpty) {
              QuerySnapshot<Map<String, dynamic>> latest =
                  latestQuerySnapshotCarriedInMapAfterArchive.values.first
                      as QuerySnapshot<Map<String, dynamic>>;
              for (var element in latest.docs) {
                debugPrint("UPDATE : ${element.id}");
              }
              reservationsSnapshotsData = latest;
            }

            if (newDocsAfterNewBookingMade.isNotEmpty && !bookingHasEnded) {
              QuerySnapshot<Map<String, dynamic>> latest =
                  newDocsAfterNewBookingMade.values.elementAt(0)
                      as QuerySnapshot<Map<String, dynamic>>;
              for (var element in latest.docs) {
                debugPrint("SUITE A RES : ${element.id}");
              }
              reservationsSnapshotsData = latest;
            } else {
              debugPrint("SUITE A RES empty");
            }
            var allReservationsFromAllAppUsers = reservationsSnapshotsData;

            debugPrint(
                "ALL RES LENGTH : ${allReservationsFromAllAppUsers.docs.length}");
            if (reservationsSnapshotsData.docs.isNotEmpty &&
                widget.newMoreUrgentBooking.isEmpty) {
              doesUserHaveAnyReservation = getUserReservationDetails(
                  currentlySignedInUser,
                  myDB,
                  reservationsSnapshotsData.docs,
                  reservationsSnapshotsData,
                  forInitiState: false);
            }
            // if(aReservationJustEnded)
            return SlidingUpPanel(
              renderPanelSheet: true,
              margin: EdgeInsets.zero,
              panel: TestDashBoardPanel(
                panelScrollController: panelScrollController,
                dragHandlePanelController: dragHandlePanelController,
                updateDashboardCar: updateDashboardCar,
              ),
              minHeight: panelHeightClosed,
              maxHeight: panelHeightOpened,
              parallaxEnabled: true,
              parallaxOffset: .5,
              panelBuilder: (panelScrollController) => TestDashBoardPanel(
                  panelScrollController: panelScrollController,
                  dragHandlePanelController: dragHandlePanelController,
                  updateDashboardCar: updateDashboardCar),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              body:
                  Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                welcomeToDashboardCard(currentlySignedInUser!.displayName),
                !doesUserHaveAnyReservation
                    ? noBookingSoFar()
                    : reservationHappening(allReservationsFromAllAppUsers),
                !doesUserHaveAnyReservation
                    ? Container()
                    : bookingInfoListView(
                        allUserBookings.first.values.elementAt(0))
              ]),
            );
          }
        });
  }

  Container welcomeToDashboardCard(String? displayName) {
    var dashboardWelcomeTextStyle = const TextStyle(
        fontSize: 15, color: Colors.black, fontWeight: FontWeight.bold);

    return Container(
      margin: const EdgeInsets.all(15),
      height: 100,
      width: double.infinity,
      child: Card(
        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
        // shadowColor: const Color(0xff7986CB),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 15,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          width: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.waving_hand_rounded,
                    size: 15,
                    color: Colors.blue,
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Text("Hi $displayName,", style: dashboardWelcomeTextStyle),
                ],
              ),
              Text(
                  "Here, you can visualize your upcoming or ongoing booking's details anytime.",
                  style: dashboardWelcomeTextStyle.copyWith(
                      fontWeight: FontWeight.w500)),
              /*    Row(
                children: [
                  const Icon(
                    Icons.visibility,
                    size: 15,
                    color: Colors.blue,
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Text("Click on the clicking for more details", style: dashboardWelcomeTextStyle),
                ],
              ),
         */
            ],
          ),
        ),
        //color: Colors.grey,
        //shadowColor: Colors.blue,
      ),
    );
  }

  Column noBookingSoFar() {
    const timeLeftHeaderText = TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w900,
        fontFamily: 'OpenSans');
    var ringFillGradientResStartsIn = LinearGradient(
        colors: [
          Theme.of(context).primaryColor.withValues(alpha: 0.4),

          Theme.of(context).colorScheme.secondary, //this one do not touch
        ],
        begin: const FractionalOffset(0.0, 0.0),
        end: const FractionalOffset(1.0, 0.0),
        stops: const [0.0, 1.0],
        tileMode: TileMode.clamp);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
          child: Stack(
            alignment: Alignment.bottomCenter,
            fit: StackFit.passthrough,
            children: [
              CircularCountDownTimer(
                duration: 0,
                isReverse: true,
                initialDuration: 0,
                width: 350,
                height: 350,
                ringColor: Colors.grey[300]!,
                ringGradient: null,
                fillColor: Colors.purpleAccent[100]!,
                fillGradient: null,
                backgroundColor: Colors.grey,
                backgroundGradient: null,
                strokeWidth: 18.0,
                strokeCap: StrokeCap.butt,
                textStyle: const TextStyle(
                    fontSize: 25.0,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    height: -3.5),
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
                  /*  GestureDetector(
                    onTap: () {
                      debugPrint("YUUUU");
                      showDialog(
                          context: context,
                          builder: (context) {
                            return ThemeHelper().alartDialog(
                                'Show/Hide Details',
                                'LongPress on me to display or hide your upcoming/ongoing reservation details.',
                                context);
                          });
                    },
                    onLongPress: () {
                      setState(() {
                        showBookingDetails ? showBookingDetails = false : showBookingDetails = true;
                      });
                    },
                    child: Icon(showBookingDetails ? Icons.visibility_off : Icons.visibility),
                  ), */
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Visibility(
                      visible: canDisplayVehicule ? true : false,
                      child: const FittedBox(
                        child: Text(
                          "NO BOOKING SO FAR",
                          style: timeLeftHeaderText,
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 15, right: 10, bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [],
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
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                elevation: 20,
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(10)),
                                  height: 50,
                                  width: 80,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const FittedBox(
                                        child: Text(
                                          'Duration',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          RichText(
                                            text: TextSpan(
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w900),
                                              children: [
                                                const TextSpan(
                                                  text: "00",
                                                ),
                                                WidgetSpan(
                                                  child: Transform.translate(
                                                    offset:
                                                        const Offset(0.0, -7.0),
                                                    child: const Text(
                                                      'H',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w900),
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
                            Visibility(
                              visible: canDisplayVehicule ? true : false,
                              child: GestureDetector(
                                child: Image(
                                  image: AssetImage(
                                      'assets/images/carRep/$defaultCarBrand.png'),
                                  // width: 400,
                                  height: MediaQuery.of(context).size.height /
                                          3.2 -
                                      120, //50 is toolbar height and 10 is the padding above bottombar
                                  fit: BoxFit.scaleDown,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        defaultCarModelDetail.isNotEmpty
            ? FittedBox(
                child: Text(
                  "${defaultCarBrand.toUpperCase()} $defaultCarModelDetail",
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: modelDetailColor),
                ),
              )
            : const SizedBox(
                child: Text("No default car selected so far."),
              ),
      ],
    );
  }

  bool getUserReservationDetails(
      User? currentlySignedInUser,
      FirebaseFirestore myDB,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> resDocs,
      QuerySnapshot<Map<String, dynamic>> value,
      {required bool forInitiState}) {
    var userHasBooking = resDocs.any(
        (element) => element.data()['ClientID'] == currentlySignedInUser?.uid);
    if (userHasBooking) {
      var tempOutadedRes = resDocs.where((element) {
        var bookingEndTS = element.data()['BookingEnd'] as Timestamp;
        /*  int deleteCount = 0;
        if (bookingEndTS.toDate().difference(DateTime.now()).inSeconds < 0) && deleteCount < 1 > {
          debugPrint("THE SINGLE OUTDATED : ${element.id} _____ $stopDeletingCount");
          var resThatJustEndedEntries = {element.id: element.data()};
          var moreUrgentReservationInfo = fetchMoreUrgentReservationInfo();
          var moreUrgentResParkingInfo = fetchMoreUrgentResParkingInfo(moreUrgentReservationInfo);
          var castedMoreUrgentParkingInfo = moreUrgentResParkingInfo;
          archiveResThatJustEnded(castedMoreUrgentParkingInfo, resThatJustEndedEntries, value,
              action: 'completed', fromInitiState: forInitiState);
              deleteCount += 1;
        } */
        /*  int deleteCount = 0;
        if (bookingEndTS.toDate().difference(DateTime.now()).inSeconds < 0) && deleteCount < 1 > {
          debugPrint("THE SINGLE OUTDATED : ${element.id} _____ $stopDeletingCount");
          var resThatJustEndedEntries = {element.id: element.data()};
          var moreUrgentReservationInfo = fetchMoreUrgentReservationInfo();
          var moreUrgentResParkingInfo = fetchMoreUrgentResParkingInfo(moreUrgentReservationInfo);
          var castedMoreUrgentParkingInfo = moreUrgentResParkingInfo;
          archiveResThatJustEnded(castedMoreUrgentParkingInfo, resThatJustEndedEntries, value,
              action: 'completed', fromInitiState: forInitiState);
              deleteCount += 1;
        } */
        return bookingEndTS.toDate().difference(DateTime.now()).inSeconds < 0;
      });
      debugPrint("tempOutadedRes length: ${tempOutadedRes.length}");
      if (tempOutadedRes.isNotEmpty &&
          allUserBookings.isNotEmpty &&
          allUserVehiculesUsedForBooking.isNotEmpty &&
          allBookedParkingsDetails.isNotEmpty) {
        for (var singleOutdatedRes in tempOutadedRes) {
          if (stopDeletingCount < tempOutadedRes.length) {
            debugPrint(
                "THE SINGLE OUTDATED : ${singleOutdatedRes.id} _____ $stopDeletingCount");
            var resThatJustEndedEntries = {
              singleOutdatedRes.id: singleOutdatedRes.data()
            };
            var moreUrgentReservationInfo = fetchMoreUrgentReservationInfo();
            var moreUrgentResParkingInfo =
                fetchMoreUrgentResParkingInfo(moreUrgentReservationInfo);
            var castedMoreUrgentParkingInfo = moreUrgentResParkingInfo;
            archiveResThatJustEnded(
                castedMoreUrgentParkingInfo, resThatJustEndedEntries, value,
                action: 'completed', fromInitiState: forInitiState);
            stopDeletingCount += 1;
          }
        }
      }

      var userBookings = resDocs.where((element) =>
          element.data()['ClientID'] == currentlySignedInUser?.uid);
      debugPrint(
          "ALL USER BOOKINGS ${allUserBookings.length} _____ ${userBookings.length}");

      //IHAVE TO REMOVE THE ENTRY IN HERE BY UPDATING ALL USERBOOKINGS, ALLPARKINGIDSCONCERNED AND ALLVEHICULESUSEDFORBOOKING
      if (allUserBookings.length < userBookings.length) {
        for (var element in userBookings) {
          //debugPrint("FOUND ONE :${element.id}");
          allUserBookings.add({element.id: element.data()});
        }
      }

      allUserBookings.length > 1
          ? {
              allUserBookings.sort(
                (aData, bData) {
                  var a = aData.values.first as Map<String, dynamic>;
                  var b = bData.values.first as Map<String, dynamic>;

                  var aBookingStart = a['BookingStart'] as Timestamp;
                  var bBookingStart = b['BookingStart'] as Timestamp;
                  return aBookingStart.compareTo(bBookingStart);
                },
              ),
              debugPrint("LENGTH AFTER SORTED ${allUserBookings.length}")

              //FIND A WAY TO COMPARE THE BOOKINGS.FIRST BY STORING THEM SOMEWHERE. IF THEY ARE EQUAL, DO NOTHING ELSE set a new variable called bookingHasBennUpdated to true and if that var is true then bookingStatrsIn else showTheCircularThing
            }
          : null;
      if (allUserBookings.length > userBookings.length) {
        allUserBookings.removeAt(0);
      }

      if (allParkingIDsConcerned.length < allUserBookings.length) {
        for (var element in allUserBookings) {
          var reservationData = element.values.first as Map<String, dynamic>;
          allParkingIDsConcerned.add(reservationData['ParkingID']);
          DocumentReference parkingsCollection =
              myDB.collection("locations").doc(reservationData['ParkingID']);
          parkingsCollection.get().then((value) {
            allBookedParkingsDetails.add({value.id: value.data()});
            debugPrint(
                "SORTED : ____ ${value.data()} ____ ${allBookedParkingsDetails.length}");
          }) /* .whenComplete(() => setState(() {})) */;
        }
      }

      if (allParkingIDsConcerned.length > allUserBookings.length) {
        debugPrint(
            "ALL PARKINGIDCONCERNED first ID : ${allParkingIDsConcerned.length}");
        for (var element in allUserBookings) {
          var reservationData = element.values.first as Map<String, dynamic>;
          var ok =
              allParkingIDsConcerned.difference({reservationData['ParkingID']});
          //debugPrint("THE DIFFERENCE $ok");
          ok.isNotEmpty
              ? allParkingIDsConcerned
                  .removeWhere((element) => element == ok.first)
              : null;
          /* .whenComplete(() => setState(() {})) */
        }
      }

      Set allVehiculesUsedIDs = {};
      for (var element in resDocs) {
        allVehiculesUsedIDs.add(element.data()['VehiculeID']);
      }
      debugPrint("ALL Set allVehiculesUsedIDs : ${allVehiculesUsedIDs.length}");

      myDB
          .collection('users/${currentlySignedInUser?.uid}/vehicules')
          .get()
          .then((vehiculesDocs) {
        if (vehiculesDocs.size != 0) {
          debugPrint("vehiculesDocs ${vehiculesDocs.size}");
          for (var vehiculeID in allVehiculesUsedIDs) {
            var matchingVehiculeDocList =
                vehiculesDocs.docs.where((element) => element.id == vehiculeID);
            allUserVehiculesUsedForBooking.length < allVehiculesUsedIDs.length
                ? allUserVehiculesUsedForBooking.add({
                    matchingVehiculeDocList.first.id:
                        matchingVehiculeDocList.first.data()
                  })
                : null;
          }
          debugPrint(
              "ALL allUserVehiculesUsedForBooking ${allUserVehiculesUsedForBooking.length}");
        } else {
          userHasNoVehicules = true;
        }
      }).whenComplete(() {
        setStateCount < 1
            ? {
                /*  setState(
                  () {},
                ), */
                setStateCount += 1
              }
            : null;
      });
    } else {
      debugPrint("NO BOOKINGS FOR THIS USER");
    }

    return userHasBooking;
  }

  ValueListenableBuilder<bool> reservationHappening(
      QuerySnapshot<Map<String, dynamic>> allReservationsFromAllAppUsers) {
    TimeRange selectedTimeInterval;
    // Timestamp bookingEndTS, bookingStartTS;
    Map<String, dynamic> moreUrgentReservationInfo = {},
        moreUrgentResParkingInfo = {},
        moreUrgentResCarInfo = {};

    //debugPrint("ALL USER BOOKINGS $allUserBookings");
    if (allUserBookings.isNotEmpty &&
        allUserVehiculesUsedForBooking.isNotEmpty &&
        allBookedParkingsDetails.isNotEmpty) {
      // listeningToReservationsRT(allReservationsFromAllAppUsers);
      moreUrgentReservationInfo = fetchMoreUrgentReservationInfo();
      moreUrgentResCarInfo =
          fetchMoreUrgentResCarInfo(moreUrgentReservationInfo);
      moreUrgentResParkingInfo =
          fetchMoreUrgentResParkingInfo(moreUrgentReservationInfo);

      bookingEndTS = moreUrgentReservationInfo['BookingEnd'] as Timestamp;
      bookingStartTS = moreUrgentReservationInfo['BookingStart'] as Timestamp;

      debugPrint("___BOOKINGEND_____ ${bookingEndTS.toDate()}");

      selectedTimeInterval = TimeRange(
          startTime: TimeOfDay.fromDateTime(bookingStartTS.toDate()),
          endTime: TimeOfDay.fromDateTime(bookingEndTS.toDate()));

      bookingDuration = (selectedTimeInterval.endTime.hour * 60 +
              selectedTimeInterval.endTime.minute) -
          (selectedTimeInterval.startTime.hour * 60 +
              selectedTimeInterval.startTime.minute);

      (bookingStartTS.toDate().difference(DateTime.now())).inSeconds > 0
          ? timeUntilResStarts =
              (bookingStartTS.toDate().difference(DateTime.now())).inSeconds
          : null;
      (bookingEndTS.toDate().difference(DateTime.now())).inSeconds > 0
          ? timeUntilBookingEnds =
              (bookingEndTS.toDate().difference(DateTime.now())).inSeconds
          : null;
      if (widget.timeUntilResStartsFromBookingOverview != 0) {
        debugPrint(
            " widget.timeUntilResStartsFromBookingOverviewtimeUntilResStarts $timeUntilResStarts _ timeUntilResStarts $timeUntilBookingEnds  ongoinvalue ${bookingOnGoingListenable.value} hasStarted $bookingHasStarted hasEnded $bookingHasEnded");
      }

      if (bookingHasEnded) {
        //DO NOT ABSOLUTELY REMOVE EVER
        /*   debugPrint("bookingHasEnded timeUntilResStarts $timeUntilResStarts _ timeUntilResStarts $timeUntilBookingEnds"); */

        if (timeUntilResStarts != 0) {
          newDocsAfterNewBookingMade.clear();
          timeUntilResStarts > 0
              ? {
                  _countdownController.restart(duration: timeUntilResStarts),
                  bookingHasStarted = false,
                  bookingHasEnded = false,
                  bookingOnGoingListenable.value = false,
                }
              : {
                  _countdownController.restart(duration: timeUntilBookingEnds),
                  bookingHasStarted = true,
                  bookingHasEnded = false,
                  bookingOnGoingListenable.value = true
                };
        }
      }
    } //if closing brack

    debugPrint(
        "Durations: booking : $bookingDuration __ timeUntilBookingEndsSeconds $timeUntilBookingEnds _ timeUntilResStartsSeconds $timeUntilResStarts");
    bookingDuration > 0 && timeUntilBookingEnds > 0 && timeUntilResStarts == 0
        ? bookingOnGoingListenable.value = true
        : null;

    return ValueListenableBuilder<bool>(
        valueListenable: bookingOnGoingListenable,
        builder: (context, bookingOnGoingValue, child) {
          debugPrint(
              "LISTENABLE VALUE $bookingOnGoingValue _ $timeUntilBookingEnds _ $bookingHasStarted }");

          return (!bookingOnGoingValue && timeUntilResStarts > 0)
              ? bookingStartsIn(
                  bookingDuration,
                  durationToString(bookingDuration),
                  timeUntilResStarts,
                  moreUrgentResParkingInfo,
                  moreUrgentResCarInfo,
                  timeUntilBookingEnds,
                  allReservationsFromAllAppUsers)
              : bookingHasStarted == true ||
                      bookingOnGoingValue ||
                      bookingDuration > 0 &&
                          timeUntilBookingEnds > 0 &&
                          timeUntilResStarts == 0
                  ? bookingTimeLeft(
                      timeUntilBookingEnds,
                      bookingDuration,
                      durationToString(bookingDuration),
                      moreUrgentResCarInfo,
                      moreUrgentResParkingInfo,
                      timeUntilResStarts,
                      allReservationsFromAllAppUsers)
                  : widget.newMoreUrgentBooking.isNotEmpty
                      ? freshlyCreatedRes()
                      : const Align(
                          child: CircularProgressIndicator(
                            color: Colors.orange,
                          ),
                        );
        });
  }

  Map<String, dynamic> fetchMoreUrgentReservationInfo() {
    var result = widget.newMoreUrgentBooking.isNotEmpty
        ? widget.newMoreUrgentBooking
        : allUserBookings.elementAt(0).values.first as Map<String, dynamic>;
    var ok = result['BookingEnd'] as Timestamp;
    debugPrint(
        "more urgent reservation info : $result ________ ${ok.toDate()}");
    return result; // needed values.first because the res_id is the first key
  }

  Map<String, dynamic> fetchMoreUrgentResCarInfo(
      Map<String, dynamic> moreUrgentReservationInfo) {
    allUserVehiculesUsedForBooking.where(
      (element) {
        var b = element.values.first as Map<String, dynamic>;
        String bVehiculeID = b.keys.first;
        return bVehiculeID == moreUrgentReservationInfo['ParkingID'];
      },
    ); //puts the more uregtn res's car first

    var result = allUserVehiculesUsedForBooking.elementAt(0).values.first
        as Map<String, dynamic>;
    debugPrint("MORE URGENT RES VEHICULE INFO: _____ $result");
    return result; //data without the car id as key
  }

  Map<String, dynamic> fetchMoreUrgentResParkingInfo(
      Map<String, dynamic> moreUrgentReservationInfo) {
    var result = allBookedParkingsDetails.where((singleParkingDetail) {
      return singleParkingDetail.keys.first ==
          moreUrgentReservationInfo['ParkingID'];
    }).first;
    debugPrint("MORE URGENT PARKING INFO: __ $result");

    return result;
  }

  String durationToString(int minutes) {
    var d = Duration(minutes: minutes).abs();
    List<String> parts = d.toString().split(':');
    //debugPrint("éTHE DURATION: ${parts[0].padLeft(2, '0')}h ${parts[1].padLeft(2, '0')}mn}");
    //debugPrint("éTHE DURATION: ${parts[0].padLeft(2, '0')}h ${parts[1].padLeft(2, '0')}mn}");
    return '${parts[0].padLeft(2, '0')}h ${parts[1].padLeft(2, '0')}mn';
  }

  dynamic bookingStartsIn(
      int bookingDur,
      String durationToString,
      int timeUntilResStarts,
      Map<String, dynamic> moreUrgentResParkingInfo,
      Map<String, dynamic> moreUrgentResCarInfo,
      int timeUntilBookingEnds,
      QuerySnapshot<Map<String, dynamic>> allReservationsFromAllAppUsers) {
    const timeLeftHeaderText = TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w900,
        fontFamily: 'OpenSans');
    return countDownTemplate(
        countdownDuration: bookingDuration,
        timeUntilBookingStarts: timeUntilResStarts,
        timeUntilBookingEnds: timeUntilBookingEnds,
        durationToString: durationToString,
        moreUrgentResCarInfo: moreUrgentResCarInfo,
        moreUrgentResParkingInfo: moreUrgentResParkingInfo,
        templateTextStyle: timeLeftHeaderText,
        bookingOnGoingListenValue: bookingOnGoingListenable.value,
        ringBackgroundColor: Colors.grey.shade800,
        allReservationsFromAllAppUsers: allReservationsFromAllAppUsers);
  }

  Padding countDownTemplate(
      {required int countdownDuration,
      required int timeUntilBookingStarts,
      required int timeUntilBookingEnds,
      required String durationToString,
      required Map<String, dynamic> moreUrgentResCarInfo,
      required Map<String, dynamic> moreUrgentResParkingInfo,
      required TextStyle templateTextStyle,
      required bool bookingOnGoingListenValue,
      required Color ringBackgroundColor,
      required QuerySnapshot<Map<String, dynamic>>
          allReservationsFromAllAppUsers}) {
    TextStyle timeLeftHeaderText = templateTextStyle;
    String vehiculeBrand =
            moreUrgentResCarInfo['Specs']['Brand'].toString().toLowerCase(),
        vehiculeModelDetail = moreUrgentResCarInfo['Specs']['Model Detail'];
    debugPrint(bookingOnGoingListenValue
        ? "TIME UNTIL ENDS $timeUntilBookingEnds"
        : "TIME UNTIL STARTS $timeUntilBookingStarts");
    var ringFillGradientResStartsIn = LinearGradient(
        colors: [
          Theme.of(context).primaryColor.withValues(alpha: 0.4),

          Theme.of(context).colorScheme.secondary, //this one do not touch
        ],
        begin: const FractionalOffset(0.0, 0.0),
        end: const FractionalOffset(1.0, 0.0),
        stops: const [0.0, 1.0],
        tileMode: TileMode.clamp);
    var ringFillGradientResStarted = LinearGradient(
        colors: [
          Colors.green.withValues(alpha: 0.6),

          Theme.of(context).colorScheme.secondary, //this one do not touch
        ],
        begin: const FractionalOffset(0.0, 0.0),
        end: const FractionalOffset(1.0, 0.0),
        stops: const [0.0, 1.0],
        tileMode: TileMode.clamp);

    return Padding(
      padding: const EdgeInsets.only(left: 22, right: 20),
      child: Stack(
        alignment: Alignment.bottomCenter,
        fit: StackFit.passthrough,
        children: [
          CircularCountDownTimer(
            duration: bookingOnGoingListenValue
                ? timeUntilBookingEnds
                : timeUntilBookingStarts, //timeUntilBookingEnds,
            isReverse: true,
            initialDuration: 0,
            controller: _countdownController,
            width: 400,
            height: 400,
            ringColor: Colors.grey[300]!,
            ringGradient: null,
            fillColor: bookingOnGoingListenValue
                ? Colors.lightGreen.shade900
                : Colors
                    .orange, //if fillIngredient specified, fillColor won't be taken into account.
            fillGradient: bookingOnGoingListenValue
                ? ringFillGradientResStarted
                : ringFillGradientResStartsIn, //ringFillGradient,
            backgroundColor: ringBackgroundColor,
            backgroundGradient: null,
            strokeWidth: 20.0,
            strokeCap: StrokeCap.square,
            textStyle: const TextStyle(
                fontSize: 33.0,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                height: -3.5),
            textFormat: CountdownTextFormat.HH_MM_SS,
            isReverseAnimation: true,
            isTimerTextShown: true,
            autoStart: bookingHasStarted ? false : true, //,
            onStart: () {
              debugPrint('Countdown Started');
            },
            onComplete: () async {
              debugPrint('Countdown Ended');
              if (bookingOnGoingListenValue) {
                showNotification('Booking just ended!',
                    'Hello ${currentlySignedInUser!.displayName}, Your booking in ${moreUrgentResParkingInfo.values.first['Name']} has just ended!. We hope to see you again soon.');
                bookingHasEnded = true;

                showDialog(
                    context: context,
                    builder: (dialogContext) {
                      return AlertDialog(
                        title: const Text('Booking Status Update'),
                        content: Text(
                            "'Hello ${currentlySignedInUser!.displayName}, Your booking in ${moreUrgentResParkingInfo.values.first['Name']} has just ended! We hope to see you again soon.'"),
                        actions: [
                          TextButton(
                            style: ButtonStyle(
                                backgroundColor:
                                    WidgetStateProperty.all(Colors.black38)),
                            onPressed: () async {
                              final nav = Navigator.of(dialogContext);
                              var castedMoreUrgentParkingInfo =
                                  moreUrgentResParkingInfo;
                              await archiveResThatJustEnded(
                                  castedMoreUrgentParkingInfo,
                                  allUserBookings.first,
                                  allReservationsFromAllAppUsers,
                                  action: 'completed');

                              Future.delayed(const Duration(seconds: 2))
                                  .then((value) {
                                nav.pop();
                              });
                            },
                            child: const Text(
                              "OK",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      );
                    }).then((value) {
                  setState(() {});
                });

                debugPrint('just ended');
              } else {
                showNotification('Booking just started!',
                    'Hello ${currentlySignedInUser!.displayName}, Your booking in ${moreUrgentResParkingInfo.values.first['Name']} just started!');
                bookingHasStarted = true;
                debugPrint('just started');

                showDialog(
                    context: context,
                    builder: (context) {
                      return ThemeHelper().alartDialog(
                          'Booking just started!',
                          "'Hello ${currentlySignedInUser!.displayName}, Your booking in ${moreUrgentResParkingInfo.values.first['Name']} just started!'",
                          context);
                    }).then((value) => setState(() {
                      bookingHasStarted = true;
                      bookingOnGoingListenable.value = true;
                      _countdownController.restart(
                          duration: timeUntilBookingEnds);
                      //updateResdocs and set "ReservationStatus""Started'" to true
                    }));
              }
            },
            onChange: (String timeStamp) {
              debugPrint(
                  'Countdown Changed $timeStamp  ______ ${timeStamp.split(':').elementAt(0).trim()}');
              (int.parse(timeStamp.split(':').elementAt(0).trim()) * 3600 +
                          int.parse(timeStamp.split(':').elementAt(1).trim()) *
                              60 +
                          int.parse(
                              timeStamp.split(':').elementAt(2).trim())) ==
                      300
                  ? {
                      if (bookingOnGoingListenValue)
                        {
                          debugPrint('ends soon'),
                          minutes5BeforeStartReached = true,
                          minutes5BeforeStartReached == true
                              ? showNotification('Booking ends soon.',
                                  'Hello ${currentlySignedInUser!.displayName}, Your booking in ${moreUrgentResParkingInfo.values.first['Name']} ends in 5 minutes!')
                              : null,
                        }
                      else
                        {
                          debugPrint('starts soon'),
                          minutes5BeforeStartReached = true,
                          minutes5BeforeStartReached == true
                              ? showNotification('Booking starting soon.',
                                  'Hello ${currentlySignedInUser!.displayName}, Your booking in ${moreUrgentResParkingInfo.values.first['Name']} starts in 5 minutes!')
                              : null,
                        }
                    }
                  : null;
            },
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 17),
                child: Visibility(
                  visible: canDisplayVehicule ? true : false,
                  child: FittedBox(
                    child: Text(
                      bookingOnGoingListenValue
                          ? "UNTIL BOOKING ENDS"
                          : "UNTIL BOOKING STARTS",
                      style: timeLeftHeaderText,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15, right: 10, bottom: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                            style: TextButton.styleFrom(
                                backgroundColor:
                                    Colors.black.withValues(alpha: 0.5),
                                elevation: 5),
                            onPressed: () {
                              var ok = moreUrgentResParkingInfo.values.first
                                  as Map<String, dynamic>;

                              var infos = ok['Positions'] as GeoPoint;
                              MapsLauncher.launchCoordinates(
                                  infos.latitude, infos.longitude);
                            },
                            label: SizedBox(
                              width: 200,
                              child: FittedBox(
                                child: RichText(
                                  text: TextSpan(
                                      text: "Navigate to ",
                                      children: [
                                        TextSpan(
                                            text: moreUrgentResParkingInfo
                                                .values.first['Name'],
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .primaryColorLight))
                                      ],
                                      style: const TextStyle(
                                          overflow: TextOverflow.fade,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: Color.fromARGB(
                                              255, 242, 242, 242))),
                                ),
                              ),
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
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 20,
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(10)),
                              height: 50,
                              width: 80,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const FittedBox(
                                    child: Text(
                                      'Duration',
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w900),
                                          children: [
                                            TextSpan(
                                              text: durationToString.substring(
                                                  0, 2),
                                            ),
                                            WidgetSpan(
                                              child: Transform.translate(
                                                offset: const Offset(0.0, -7.0),
                                                child: const Text(
                                                  'H',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w900),
                                                ),
                                              ),
                                            ),
                                            TextSpan(
                                              text:
                                                  ' ${durationToString.substring(4, 6)}',
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
                          image: AssetImage(
                              'assets/images/carRep/$vehiculeBrand.png'),
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
              FittedBox(
                child: Text(
                  vehiculeModelDetail,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color.fromARGB(255, 82, 35, 35)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  dynamic bookingTimeLeft(
      int timeUntilBookingEnds,
      int bookingDuration,
      String durationToString,
      Map<String, dynamic> moreUrgentResCarInfo,
      Map<String, dynamic> moreUrgentResParkingInfo,
      int timeUntilResStarts,
      QuerySnapshot<Map<String, dynamic>> allReservationsFromAllAppUsers) {
    const timeLeftHeaderText = TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w900,
        fontFamily: 'OpenSans');
    debugPrint("TIME UNTIL ENDS $timeUntilBookingEnds}");
    return countDownTemplate(
        countdownDuration: bookingDuration,
        timeUntilBookingStarts: timeUntilResStarts,
        timeUntilBookingEnds: timeUntilBookingEnds,
        durationToString: durationToString,
        moreUrgentResCarInfo: moreUrgentResCarInfo,
        moreUrgentResParkingInfo: moreUrgentResParkingInfo,
        templateTextStyle: timeLeftHeaderText,
        bookingOnGoingListenValue: bookingOnGoingListenable.value,
        ringBackgroundColor: Colors.grey.shade800,
        allReservationsFromAllAppUsers: allReservationsFromAllAppUsers);
  }

  Future<void> archiveResThatJustEnded(
      Map<String, dynamic> castedMoreUrgentParkingInfo,
      Map<String, dynamic> resThatJustEndedEntries,
      QuerySnapshot<Map<String, dynamic>> allReservationsFromAllAppUsers,
      {required String action,
      bool fromInitiState = false,
      String bookingEndString = ""}) async {
    //thinkOfAddingButtons to cancel reservation or edit the date of reservation . put thel under the car model and updateResStatus
    var docToArchivedataNotSnapshot =
        resThatJustEndedEntries.values.elementAt(0) as Map<String, dynamic>;
    String theSpotIDConcerned = docToArchivedataNotSnapshot['SlotID'];
    var firebaseResToUpdate = myDB
        .collection('slotsReservations')
        .doc(resThatJustEndedEntries.keys.first);
    try {
      if (action == 'completed') {
        var ok =
            resThatJustEndedEntries.values.elementAt(0) as Map<String, dynamic>;
        var bookingEndTS = ok['BookingEnd'] as Timestamp;
        firebaseResToUpdate.update({
          'ReservationStatus.Completed': {
            'Status': true,
            'TimeStamp':
                fromInitiState ? bookingEndTS : FieldValue.serverTimestamp()
          },
        });
      } else if (action == 'canceled before start') {
        firebaseResToUpdate.update({
          'ReservationStatus.Canceled Before Start': {
            'Status': true,
            'TimeStamp': Timestamp.now()
          }
        });
      } else {
        //timeAdded
        firebaseResToUpdate.update({
          'ReservationStatus.Added Time': {'Status': true, 'Duration': 15}
        });
      }

      var numberOfEntries = allReservationsFromAllAppUsers.docs.where((docu) {
        return docu.data()['SlotID'] == docToArchivedataNotSnapshot['SlotID'] &&
            docu.data()['ParkingID'] ==
                docToArchivedataNotSnapshot['ParkingID'];
      }).length;
      //oneEntryOnlyMeans this was the last res for this spot in the same parking

      debugPrint(
          "numberOfEntries $numberOfEntries _ $castedMoreUrgentParkingInfo");

      if (numberOfEntries == 1) {
        await myDB
            .collection(
                "locations/${castedMoreUrgentParkingInfo.keys.first}/insideParkingInfo")
            .get()
            .then((insideParkingInfo) {
          //debugPrint("ALL REG SPOTS : ${insideParkingInfo.docs.length}");

          if (insideParkingInfo.docs.isNotEmpty) {
            var theInsideParkingDocToUpdateInFirebase = myDB
                .collection(
                    "locations/${castedMoreUrgentParkingInfo.keys.first}/insideParkingInfo")
                .doc(insideParkingInfo.docs.first.id);

            var concernedDoc = insideParkingInfo.docs.first;
            var allRegSpots = concernedDoc.data()['Regular']['IDs'] as List;

            String regularOrSpecialString = 'Regular';
            List updatedBookedList = [];

            if (allRegSpots
                .contains(docToArchivedataNotSnapshot['SlotID'].toString())) {
              debugPrint("BOOKED SPOT WAS A REGULAR ONE");
            } else {
              regularOrSpecialString = 'Special';
              debugPrint("BOOKED SPOT WAS A SPECIAL ONE");
            }

            var bookedIDs = concernedDoc.data()[regularOrSpecialString]
                ['Booked']['IDs'] as List;

            var occupiedFromBookingIDs =
                concernedDoc.data()[regularOrSpecialString]['Occupied']
                    ['From Booking']['IDs'] as List;

            var availableIDs = concernedDoc.data()[regularOrSpecialString]
                ['Available']['IDs'] as List;

            availableIDs.add(theSpotIDConcerned);

            if (docToArchivedataNotSnapshot['VehiculeStatus']['Status']
                    .toString() ==
                "Not Yet Parked") {
              //then the user never came so the ID must be in "booked" . make a booked List. check parkingslots creation and attributions file with the lists and how I updated the doc. update totla bookeds
              updatedBookedList =
                  bookedIDs.toSet().difference({theSpotIDConcerned}).toList();

              theInsideParkingDocToUpdateInFirebase.update({
                "$regularOrSpecialString.Available.IDs": availableIDs,
                '$regularOrSpecialString.Available.Total': availableIDs.length,
                '$regularOrSpecialString.Booked.IDs': updatedBookedList,
                '$regularOrSpecialString.Booked.Total':
                    updatedBookedList.length,
              });
            } else if (docToArchivedataNotSnapshot['VehiculeStatus']['Status']
                    .toString() ==
                "Gone") {
              //gone as soon as the ultrasound doesn't detect the car anymore in there
              updatedBookedList = occupiedFromBookingIDs
                  .toSet()
                  .difference({theSpotIDConcerned}).toList();

              theInsideParkingDocToUpdateInFirebase.update({
                "$regularOrSpecialString.Available.IDs": availableIDs,
                '$regularOrSpecialString.Available.Total': availableIDs.length,
                '$regularOrSpecialString.Occupied.From Booking.IDs':
                    updatedBookedList,
                '$regularOrSpecialString.Occupied.From Booking.Total':
                    updatedBookedList.length,
              });
            } else {
              //meaning 'Parked
            }
          }
        });
      }

      await myDB.collection("slotsReservations").get().then((value) async {
        var finalDocToArchiveWitUpdatedData = value.docs.where(
            (element) => element.id == resThatJustEndedEntries.keys.first);
        await myDB
            .collection('archivedReservations')
            .doc(resThatJustEndedEntries.keys.first)
            .set(finalDocToArchiveWitUpdatedData.first.data())
            .then((value) => debugPrint("ARCHIVED RESERVATION"));

        await myDB
            .collection('slotsReservations')
            .doc(resThatJustEndedEntries.keys.first)
            .delete()
            .whenComplete(() => debugPrint("RESERVATION REMOVED SUCCESSFULLY"));

        await myDB.collection('slotsReservations').get().then((value) {
          debugPrint("NEW LENGTH AFTER DELEEETE ${value.docs.length}");
          latestQuerySnapshotCarriedInMapAfterArchive = {"latesQuery": value};
        });
      });
    } catch (e) {
      debugPrint("exception OCCURED ${e.toString()}");
    }
  }

  /*  void listeningToReservationsRT(QuerySnapshot<Map<String, dynamic>> reservationsSnapshotsData) {
    var moreUrgentReservationInfo = fetchMoreUrgentReservationInfo();
    var moreUrgentResCarInfo = fetchMoreUrgentResCarInfo(moreUrgentReservationInfo);
    var moreUrgentResParkingInfo = fetchMoreUrgentResParkingInfo(moreUrgentReservationInfo);
    FirebaseFirestore.instance
        .collection("slotsReservations")
        .where("ClientID", isEqualTo: currentlySignedInUser!.uid)
        .snapshots()
        .listen((event) {
      debugPrint("THE EVENT ${event.docs}");
      for (var change in event.docChanges) {
        var startStampRT = change.doc.data()!['BookingStart'] as Timestamp;
        var endtStampRT = change.doc.data()!['BookingEnd'] as Timestamp;

        var castedStartRT = startStampRT.toDate();
        var castedEndRT = endtStampRT.toDate();

        var localstartStampRT = moreUrgentReservationInfo['BookingStart'] as Timestamp;
        var localendtStampRT = moreUrgentReservationInfo['BookingEnd'] as Timestamp;

        var localcastedStartRT = localstartStampRT.toDate();
        var localcastedEndRT = localendtStampRT.toDate();
        switch (change.type) {
          case DocumentChangeType.added:
            //debugPrint("Slots Reservations Document Just Loaded: ${change.doc.data()}");
            debugPrint(
                "REAL TIME CHECK __ $castedStartRT _end $castedEndRT _ lcoal $localcastedStartRT $localcastedEndRT __ ${change.doc.id}");

            // updateFromListenSnapshot = change.doc.data();

            break;
          case DocumentChangeType.modified:

            // updateFromListenSnapshot = {change.doc.id: change.doc.data()!};
            /*   var startStamp = change.doc.data()!['BookingStart'] as Timestamp;
            var endtStamp = change.doc.data()!['BookingEnd'] as Timestamp;

            var castedStart = startStamp.toDate();
            var castedEnd = endtStamp.toDate; */
            debugPrint("CHECK BS ${change.doc.data()!['BookingStart']} _ __ ${change.doc.id}");
            /*  if (change.doc.data()!['BookingStart'] != baba.first.value['BookingStart']) {
              debugPrint("NEED UPDATE");
              baba.first.value['BookingStart'] = change.doc.data()!['BookingStart'];
            }

            if (change.doc.data()!['VehiculeStatus']['Status'] == 'Parked') {
              spotIDsWithinXHoursBookedNotOccupied.remove(change.doc.data()!['SlotID']);
            }
            if (change.doc.data()!['VehiculeStatus']['Status'] == 'Gone') {
              //Deal with the car leaving

            } */
            break;
          case DocumentChangeType.removed:
            debugPrint("Reservation DONE SO Archived: ${change.doc.data()}");
            break;
        }
      }
    });
  }
 */
  dynamic freshlyCreatedRes() {
    var moreUrgentResCarInfo = <String, dynamic>{},
        moreUrgentResParkingInfo = <String, dynamic>{},
        bookingEndTS = Timestamp.now(),
        bookingStartTS = Timestamp.now(),
        // ignore: prefer_typing_uninitialized_variables
        allReservationsFromAllAppUsers;

    if (allUserBookings.isNotEmpty &&
        allUserVehiculesUsedForBooking.isNotEmpty &&
        allBookedParkingsDetails.isNotEmpty &&
        widget.newMoreUrgentBooking.isNotEmpty) {
      var theRightDoc = widget.newMoreUrgentBooking;

      myDB
          .collection("slotsReservations")
          .get()
          .then((value) => allReservationsFromAllAppUsers = value);
      moreUrgentResCarInfo = fetchMoreUrgentResCarInfo(theRightDoc);
      moreUrgentResParkingInfo = fetchMoreUrgentResParkingInfo(theRightDoc);
      bookingEndTS = theRightDoc['BookingEnd'] as Timestamp;
      bookingStartTS = theRightDoc['BookingStart'] as Timestamp;

      //debugPrint("___BOOKINGEND_____ ${bookingEndTS.toDate()}");

      var selectedTimeInterval = TimeRange(
          startTime: TimeOfDay.fromDateTime(bookingStartTS.toDate()),
          endTime: TimeOfDay.fromDateTime(bookingEndTS.toDate()));

      bookingDuration = (selectedTimeInterval.endTime.hour * 60 +
              selectedTimeInterval.endTime.minute) -
          (selectedTimeInterval.startTime.hour * 60 +
              selectedTimeInterval.startTime.minute);

      (bookingStartTS.toDate().difference(DateTime.now())).inSeconds > 0
          ? timeUntilResStarts =
              (bookingStartTS.toDate().difference(DateTime.now())).inSeconds
          : null;
      (bookingEndTS.toDate().difference(DateTime.now())).inSeconds > 0
          ? timeUntilBookingEnds =
              (bookingEndTS.toDate().difference(DateTime.now())).inSeconds
          : null;

      if (widget.timeUntilResStartsFromBookingOverview != 0) {
        if (timeUntilResStarts > 0) {
          _countdownController.restart(duration: timeUntilResStarts);
        } else {
          _countdownController.restart(duration: timeUntilBookingEnds);
        }
      }

      return timeUntilResStarts > 0
          ? bookingStartsIn(
              bookingDuration,
              durationToString(bookingDuration),
              timeUntilResStarts,
              moreUrgentResParkingInfo,
              moreUrgentResCarInfo,
              timeUntilBookingEnds,
              allReservationsFromAllAppUsers)
          : bookingTimeLeft(
              timeUntilBookingEnds,
              bookingDuration,
              durationToString(bookingDuration),
              moreUrgentResCarInfo,
              moreUrgentResParkingInfo,
              timeUntilResStarts,
              allReservationsFromAllAppUsers);
    } else {
      return const CircularProgressIndicator(
        color: Colors.pink,
      );
    }
  }

  Column bookingInfoListView(Map<String, dynamic> first) {
    var firstFullIfnfoWithID = allUserBookings.first;
    var castedStartTime = first['BookingStart'] as Timestamp;
    var startTimeToHour = TimeOfDay.fromDateTime(castedStartTime.toDate());

    var castedEndTime = first['BookingEnd'] as Timestamp;
    var endTimeToHour = TimeOfDay.fromDateTime(castedEndTime.toDate());

    var thePSpot = first['SlotID'];

    debugPrint("FIRST INF: $first _ ${startTimeToHour.format(context)}");
    var ringFillGradientResStartsIn = LinearGradient(
        colors: [
          Theme.of(context).primaryColor.withValues(alpha: 0.4),

          Theme.of(context).colorScheme.secondary, //this one do not touch
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 1.0],
        tileMode: TileMode.clamp);
    var ringFillGradientResStarted = LinearGradient(
        colors: [
          Colors.green.withValues(alpha: 0.6),

          Theme.of(context).colorScheme.secondary, //this one do not touch
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        /* begin: const FractionalOffset(0.0, 0.0),
        end: const FractionalOffset(1.0, 0.0), */
        stops: const [0.0, 1.0],
        tileMode: TileMode.clamp);

    return Column(
      children: [
        Card(
          //color: Theme.of(context).primaryColorDark,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          elevation: 10,
          child: Container(
            //padding: EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: bookingHasStarted == true ||
                        bookingOnGoingListenable.value == true
                    ? ringFillGradientResStarted
                    : ringFillGradientResStartsIn),
            child: Container(
              width: (infSliverHeight * infSliverCount) +
                  (infSliverSpace *
                      (infSliverCount -
                          1)), //containerheight * count + (space * count-1)
              margin: const EdgeInsets.symmetric(
                horizontal: 20, /*  vertical: 20 */
              ),
              child: Visibility(
                visible: showBookingDetails ? true : false,
                child: Container(
                  color: Colors.grey[300]!,
                  height: infSliverHeight,
                  child: CustomScrollView(
                    //center: sliverkEY,
                    scrollDirection: Axis.horizontal,
                    controller: bookingInfoScrollController,
                    slivers: [
                      /*     SliverFillRemaining(
                        hasScrollBody: false,
                        child: Container(
                          child: Text(
                            "Some Dummy Text",
                          ),
                        ),
                      ), */
                      SliverGrid.count(
                        crossAxisCount: 1,
                        mainAxisSpacing: 10.0,
                        crossAxisSpacing: 10.0,
                        childAspectRatio: 1,
                        children: [
                          sliverCardTexts(
                              title: "Start",
                              content: startTimeToHour.format(context)),
                          sliverCardTexts(
                              title: "End ",
                              content: endTimeToHour.format(context)),
                          sliverCardTexts(title: "Spot ID", content: thePSpot),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Visibility(
                visible: true,
                child: editingDashBookingButtons(
                  buttonLabel: 'Cancel',
                  buttonIcon: Icons.cancel_outlined,
                  iconColor: Colors.red,
                  concernedBookingWithID: firstFullIfnfoWithID,
                )), //passthevdehicule to edit as an argument with onTap (onTap allows to select a vehicule only)
            editingDashBookingButtons(
              buttonLabel: 'Details',
              buttonIcon:
                  showBookingDetails ? Icons.visibility_off : Icons.visibility,
              iconColor: Colors.green,
              concernedBookingWithID: firstFullIfnfoWithID,
            ),
            Visibility(
              visible: true,
              child: editingDashBookingButtons(
                buttonLabel: 'Edit',
                buttonIcon: Icons.edit,
                iconColor: Colors.blue,
                concernedBookingWithID: firstFullIfnfoWithID,
              ),
            ) //passthevdehicule to edit as an argument for
          ],
        )
      ],
    );
  }

  Future<void> getNewSlotsReservationsData(User currentlySignedInUser) async {
    //debugPrint("CALLED GETNEW");
    try {
      await myDB
          .collection("slotsReservations")
          .where('ClientID', isEqualTo: currentlySignedInUser.uid)
          .get()
          .then((value) => {
                setState(
                  () {
                    newDocsAfterNewBookingMade = {'id': value};
                  },
                )
              });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Column editingDashBookingButtons(
      {required String buttonLabel,
      required IconData buttonIcon,
      required MaterialColor iconColor,
      required Map<String, dynamic> concernedBookingWithID}) {
    return Column(
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            elevation: 5,
            backgroundColor: Colors.grey.shade800,
            shape: const CircleBorder(),
          ),
          onPressed: () async {
            final nav = Navigator.of(context);

            /*   setState(() {
              /*   addCarIconPressed = true;
                    callSelectVehiculeAfterAdd = true; */
            }); */
            buttonLabel == 'Cancel'
                ? {
                    await removeBookingFromFirebase(concernedBookingWithID)
                        .then((carRemoveResult) {
                      isReservationCanceled
                          ? {
                              setState(
                                () => bookingHasEnded = true,
                              ),
                            }
                          : null;
                    }).whenComplete(
                            () => isReservationCanceled ? nav.pop() : null),
                  } //archiverResBlabla with "canceled before end"
                : buttonLabel == 'Details'
                    ? {
                        setState(() {
                          showBookingDetails
                              ? showBookingDetails = false
                              : showBookingDetails = true;
                        })
                      }
                    : editReservation(concernedBookingWithID);
          },
          child: Icon(
            buttonIcon,
            color: iconColor,
            size: buttonLabel == 'Edit' ? 21 : 23,
          ),
        ),
        SizedBox(
          width: 40,
          child: Align(
            child: FittedBox(
                child: Text(
              buttonLabel,
              style: TextStyle(
                color: Colors.black,
                fontSize: buttonLabel == "Edit" ? 13 : 15,
                fontFamily: 'OpenSans',
                fontWeight: FontWeight.bold,
              ),
            )),
          ),
        ),
      ],
    );
  }

  Card sliverCardTexts({required String title, required content}) {
    TextStyle titleTextStyle = TextStyle(
      color: Colors.black,
      fontFamily: 'OpenSans',
      fontSize: title == "Spot ID" ? 10 : 11,
      fontWeight: FontWeight.w800,
    );

    return Card(
        // color: Colors.blue[200],
        color: infSliverCardColor,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 3),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: FittedBox(
                    child: Text(
                      title,
                      style: titleTextStyle,
                    ),
                  ),
                ),
                Flexible(
                  child: FittedBox(
                    child: Text(
                      content,
                      style: titleTextStyle.copyWith(
                          fontSize: 11, fontWeight: FontWeight.w100),
                    ),
                  ),
                ),
              ]),
        ));
  }

  Future<String> removeBookingFromFirebase(
      Map<String, dynamic> concernedBooking) async {
    //var theBookingDocID = concernedBooking.keys.elementAt(0);
    return await showDialog(
      barrierDismissible: false,
      useRootNavigator: false,
      context: context,
      builder: (dialcontext) =>
          StatefulBuilder(builder: (dialcontext, setState) {
        return AlertDialog(
          scrollable: true,
          title: const Text("Cancelation Confirmation"),
          content: const Text(
              "Your current booking will be canceled if you proceed."),
          actions: [
            TextButton(
              style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.black38)),
              onPressed: () {
                Navigator.of(context).pop("REMOVE BOOKING");
              },
              child: const Text(
                "OK",
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.black38)),
              onPressed: () {
                Navigator.of(context).pop('CANCEL REMOVAL');
              },
              child: const Text(
                "CANCEL",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      }),
    ).then((bookingAction) async {
      debugPrint("BOOKING ACTION: $bookingAction");
      if (bookingAction == 'REMOVE BOOKING') {
        awaitActionDialog("Canceling booking, please wait.");

        var moreUrgentReservationInfo = fetchMoreUrgentReservationInfo();
        var moreUrgentResParkingInfo =
            fetchMoreUrgentResParkingInfo(moreUrgentReservationInfo);
        var castedMoreUrgentParkingInfo = moreUrgentResParkingInfo;
        await myDB.collection("slotsReservations").get().then((value) =>
            archiveResThatJustEnded(
                castedMoreUrgentParkingInfo, concernedBooking, value,
                action: 'canceled before start'));
        setState(() {
          isReservationCanceled = true;
        });

        //showSnackBarText('Car successfully removed!');
      }
      String ok = bookingAction as String;
      return ok;
    });
  }

  Future<dynamic> awaitActionDialog(
    String actionTitle,
  ) async {
    return await showDialog(
        barrierDismissible: false,
        useRootNavigator: false,
        context: context,
        builder: (dialcontext) =>
            StatefulBuilder(builder: (dialcontext, setState) {
              /*   isReservationCanceled
                  ? Future.delayed(const Duration(seconds: 5)).then(
                      (value) {
                        Navigator.pop(context);
                      },
                    )
                  : null; */
              return AlertDialog(
                  scrollable: true,
                  title: Center(
                      child: Text(
                    actionTitle,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500),
                  )),
                  content: SpinKitFadingCircle(
                    size: 40,
                    itemBuilder: (BuildContext context, int index) {
                      return const DecoratedBox(
                        decoration: BoxDecoration(
                            color: Colors.green, shape: BoxShape.circle),
                      );
                    },
                  ));
            }));
  }

  Future<dynamic> editReservation(
      Map<String, dynamic> concernedBookingWithID) async {
    bool autoValidate = true;
    bool readOnly = false;
    bool showSegmentedControl = true;
    final formKey = GlobalKey<FormBuilderState>();
    bool genderHasError = false;

    var genderOptions = ['Male', 'Female', 'Other'];

    void onChanged(dynamic val) => debugPrint(val.toString());
    var bookingWOid =
        concernedBookingWithID.values.elementAt(0) as Map<String, dynamic>;
    Timestamp initialValueBookingStart =
        bookingWOid['BookingStart'] as Timestamp;
    Timestamp initialValueBookingEnd = bookingWOid['BookingEnd'] as Timestamp;

    var stateManagerRead = context.read<BookingStateManagement>();
    Map<String, dynamic> theParkingGeneralInfo = {};
    fetchParkingIDforCurrentRes(bookingWOid).then((value) {
      theParkingGeneralInfo = value;
      stateManagerRead.updateOpeningAndClosingHours(
          theParkingGeneralInfo['Opening Hour'],
          theParkingGeneralInfo['Closing Hour']);
    });

    /*  stateManagerRead.updateOpeningAndClosingHours(
        theParkingGeneralInfo['Opening Hour'], theParkingGeneralInfo['Closing Hour']);
 */
    TimeOfDay startTime = TimeOfDay(
            hour: int.parse(context
                .read<BookingStateManagement>()
                .openingHour
                .split(":")[0]),
            minute: int.parse(context
                .read<BookingStateManagement>()
                .openingHour
                .split(":")[1])),
        endTime = TimeOfDay(
            hour: int.parse(context
                .read<BookingStateManagement>()
                .closingHour
                .split(":")[0]),
            minute: int.parse(context
                .read<BookingStateManagement>()
                .closingHour
                .split(":")[1]));

    stateManagerRead
        .getTimeSlotsIntervals(startTime, endTime, const Duration(minutes: 30))
        .toList()
        .then((value) {
      debugPrint("OK LISTENING LIST $value");
      fetchedParkingTimeSlots = value;
    });

    return showDialog(
        barrierDismissible: true,
        useRootNavigator: false,
        context: context,
        builder: (dialcontext) =>
            StatefulBuilder(builder: (dialcontext, setState) {
              return AlertDialog(
                scrollable: true,
                content: SizedBox(
                  width: double.maxFinite,
                  height: 400,
                  child: SingleChildScrollView(
                      child: GestureDetector(
                    onTap: () {
                      FocusScope.of(context).requestFocus(FocusNode());
                    },
                    child: Column(
                      children: <Widget>[
                        FormBuilder(
                          key: formKey,
                          // enabled: false,
                          onChanged: () {
                            formKey.currentState!.save();
                            debugPrint(formKey.currentState!.value.toString());
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
                              /* const SizedBox(height: 100, child: FittedBox(child: Text("Please note that you can only edit the date and time of your booking with no possibility of increasing or decreasing "),),), */
                              FormBuilderDateTimePicker(
                                name: 'bookingStart',
                                initialEntryMode: DatePickerEntryMode.calendar,
                                initialValue: initialValueBookingStart.toDate(),
                                inputType: InputType.both,
                                decoration: InputDecoration(
                                  labelText: 'New Booking Start',
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      formKey
                                          .currentState!.fields['bookingStart']
                                          ?.didChange(null);
                                    },
                                  ),
                                ),
                                initialTime: TimeOfDay.fromDateTime(
                                    initialValueBookingStart.toDate()),
                                // locale: const Locale.fromSubtags(languageCode: 'fr'),
                              ),
                              FormBuilderDateTimePicker(
                                name: 'bookingEnd',
                                initialEntryMode: DatePickerEntryMode.calendar,
                                initialValue: initialValueBookingEnd.toDate(),
                                inputType: InputType.both,
                                decoration: InputDecoration(
                                  labelText: 'New Booking End',
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      formKey.currentState!.fields['bookingEnd']
                                          ?.didChange(null);
                                    },
                                  ),
                                ),
                                initialTime: TimeOfDay.fromDateTime(
                                    initialValueBookingEnd.toDate()),
                                // locale: const Locale.fromSubtags(languageCode: 'fr'),
                              ),
                              FormBuilderDateRangePicker(
                                name: 'date_range',
                                firstDate: DateTime(1970),
                                lastDate: DateTime(2030),
                                format: DateFormat('yyyy-MM-dd'),
                                onChanged: onChanged,
                                decoration: InputDecoration(
                                  labelText: 'Date Range',
                                  helperText: 'Helper text',
                                  hintText: 'Hint text',
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      formKey.currentState!.fields['date_range']
                                          ?.didChange(null);
                                    },
                                  ),
                                ),
                              ),
                              FormBuilderSlider(
                                name: 'timeAdded',
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.min(6),
                                ]),
                                onChanged: onChanged,
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
                              FormBuilderDropdown<String>(
                                // autovalidate: true,
                                name: 'gender',
                                decoration: InputDecoration(
                                  labelText: 'Gender',
                                  suffix: genderHasError
                                      ? const Icon(Icons.error)
                                      : const Icon(Icons.check),
                                  hintText: 'Select Gender',
                                ),
                                validator: FormBuilderValidators.compose(
                                    [FormBuilderValidators.required()]),
                                items: genderOptions
                                    .map((gender) => DropdownMenuItem(
                                          alignment:
                                              AlignmentDirectional.center,
                                          value: gender,
                                          child: Text(gender),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    genderHasError = !(formKey
                                            .currentState?.fields['gender']
                                            ?.validate() ??
                                        false);
                                  });
                                },
                                valueTransformer: (val) => val?.toString(),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (formKey.currentState?.saveAndValidate() ??
                                      false) {
                                    debugPrint(
                                        formKey.currentState?.value.toString());
                                  } else {
                                    debugPrint(
                                        formKey.currentState?.value.toString());
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
                                  formKey.currentState?.reset();
                                },
                                // color: Theme.of(context).colorScheme.secondary,
                                child: Text(
                                  'Reset',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
                ),
              );
            }));
  }

  Future<Map<String, dynamic>> fetchParkingIDforCurrentRes(
      Map<String, dynamic> bookingWOid) async {
    Map<String, dynamic> theParkingGeneralInfo = {};
    await myDB
        .collection("locations")
        .doc(bookingWOid['ParkingID'])
        .get()
        .then((value) {
      debugPrint("CONTEXT READ: ${value.data()}");
      theParkingGeneralInfo = value.data() as Map<String, dynamic>;
    });
    return theParkingGeneralInfo;
  }

//closinbrac
}
