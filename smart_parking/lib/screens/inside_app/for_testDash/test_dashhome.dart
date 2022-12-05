import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:smart_parking/screens/inside_app/for_testDash/test_panel.dart';
import 'package:smart_parking/services/firebase/firebase_service.dart';
import 'package:smart_parking/services/firebase/firestore_service.dart';

class TestDashboardHomePage extends StatefulWidget {
  const TestDashboardHomePage({Key? key}) : super(key: key);

  @override
  State<TestDashboardHomePage> createState() => _TestDashboardHomePageState();
}

class _TestDashboardHomePageState extends State<TestDashboardHomePage> {
  String walletFirstAndOnlyDocID = '';
  late String defaultCarModelDetail = "", defaultCarBrand = 'dacia';
  late User? currentlySignedInUser;
  Set allParkingIDsConcerned = {};
  int count = 0, setStateCount = 0;
  final panelScrollController = ScrollController();
  final dragHandlePanelController = PanelController();
  var myDB = FirebaseFirestore.instance;
  var firebaseService = FirebaseService();
  var firestoreWalletService = FirestoreWalletService();
  bool canUpdateFields = false, userHasNoVehicules = false;
  List<Map<String, dynamic>> allUserBookings = [], allBookedParkingsDetails = [], allUserVehiculesUsedForBooking = [];
  Map<String, dynamic> allReservationInfoNeeded = {}, ok = {};
  final CountDownController _controller = CountDownController();
  int settingState = 0;

  @override
  void initState() {
    firebaseService.auth.currentUser != null
        ? {
            setState(() {
              currentlySignedInUser = firebaseService.auth.currentUser;
            }),
            loadVehiculeInfo(currentlySignedInUser!).whenComplete(() => setState(() {}))
          }
        : currentlySignedInUser = null;

    super.initState();
  }

  @override
  void dispose() {
//  _controller.;
    super.dispose();
  }

  Future<void> loadVehiculeInfo(User currentlySignedInUser) async {
    await FirebaseFirestore.instance.collection("users/${currentlySignedInUser.uid}/vehicules").get().then((value) {
      if (value.docs.isNotEmpty) {
        var ok = value.docs.where(
          (element) {
            return element.data()['Currently Selected'] == true;
          },
        );
        ok.isNotEmpty
            ? setState(() {
                defaultCarModelDetail = ok.first.data()['Specs']['Model Detail'].toString();
                defaultCarBrand = ok.first.data()['Specs']['Brand'].toString().toLowerCase();
              })
            : setState(() {
                defaultCarModelDetail = "";
                defaultCarBrand = "dacia";
              });
      }

      debugPrint("THE FIRST : $defaultCarModelDetail");
    });
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

  updateDashboardCar(String carModelFromPanel, String carBrandFromPanel) {
    settingState = 0;
    defaultCarModelDetail = carModelFromPanel;
    defaultCarBrand = carBrandFromPanel;
    setState(() {});
  }

  dashBSlidingUpPanel(double panelHeightClosed, double panelHeightOpened) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection("slotsReservations").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Text(''); //Text('Loading brand logos');
          } else {
            //;
            /*   debugPrint("FOUND ONE :$allUserBookings");
            debugPrint("FOUND TWO :$allBookedParkingsDetails");
            debugPrint("FOUND THREE :$allUserVehiculesUsedForBooking");
            debugPrint("FOUND 4 :$allReservationInfoNeeded");
            debugPrint("FOUND 5 :$userHasNoVehicules"); */
            var doesUserHaveAnyReservation = false;

            var reservationsSnapshotsData = snapshot.data!;
            if (reservationsSnapshotsData.docs.isNotEmpty) {
              doesUserHaveAnyReservation =
                  getUserReservationDetails(currentlySignedInUser, myDB, reservationsSnapshotsData.docs);
            }
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
              /* parallaxEnabled: true,
              parallaxOffset: .5, */
              panelBuilder: (panelScrollController) => TestDashBoardPanel(
                  panelScrollController: panelScrollController,
                  dragHandlePanelController: dragHandlePanelController,
                  updateDashboardCar: updateDashboardCar),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              body: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: !doesUserHaveAnyReservation
                    ? [
                        noBookingSoFar()
                        /* Container(
                          height: 400,
                          color: Colors.yellow,
                        ) */
                      ]
                    : [
                        /*  ReservationCountdown(
                      allReservationInfoNeeded: allReservationInfoNeeded,
                      currentlySignedInUser: currentlySignedInUser,
                      userHasVehicules: !userHasNoVehicules,
                      timeUntilResFetchedFromBookingOverview: widget.timeUntilResStartsFromBookingOverview,
                      canShowToggle: widget.canShowToggle,
                      getIndex: widget.getIndex) */
                      ],
              ),
            );
          }
        });
  }

  noBookingSoFar() {
    const timeLeftHeaderText =
        TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'OpenSans');
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
            backgroundColor: Colors.grey,
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
                    "NO BOOKING SO FAR",
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
                          image: AssetImage('assets/images/carRep/$defaultCarBrand.png'),
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
              defaultCarModelDetail.isNotEmpty
                  ? FittedBox(
                      child: Text(
                        defaultCarModelDetail,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700, color: Color.fromARGB(255, 82, 35, 35)),
                      ),
                    )
                  : Container(
                      child: const Text("No default car selected so far."),
                    ),
            ],
          )
        ],
      ),
    );
  }

  bool getUserReservationDetails(
      User? currentlySignedInUser, FirebaseFirestore myDB, List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    var userHasBooking = docs.any((element) => element.data()['ClientID'] == currentlySignedInUser?.uid);
    if (userHasBooking) {
      var userBookings = docs.where((element) => element.data()['ClientID'] == currentlySignedInUser?.uid);
      allUserBookings.length < userBookings.length
          ?

          // ignore: avoid_function_literals_in_foreach_calls
          userBookings.forEach((element) {
              debugPrint("FOUND ONE :${element.id}");
              allUserBookings.add({element.id: element.data()});
            })
          : null;

      allUserBookings.sort(
        (aData, bData) {
          var a = aData.values.first as Map<String, dynamic>;
          var b = bData.values.first as Map<String, dynamic>;

          var aBookingStart = a['BookingStart'] as Timestamp;
          var bBookingStart = b['BookingStart'] as Timestamp;
          return aBookingStart.compareTo(bBookingStart);
        },
      );

      //
      if (allParkingIDsConcerned.length < allUserBookings.length) {
        for (var element in allUserBookings) {
          var reservationData = element.values.first as Map<String, dynamic>;
          allParkingIDsConcerned.add(reservationData['ParkingID']);
          DocumentReference parkingsCollection = myDB.collection("locations").doc(reservationData['ParkingID']);
          parkingsCollection.get().then((value) {
            allBookedParkingsDetails.add({value.id: value.data()});
            debugPrint("SORTED : ____ ${value.data()} ____ ${allBookedParkingsDetails.length}");
          }).whenComplete(() => setState(() {}));
        }
      }
      Set allVehiculesUsedIDs = {};
      for (var element in docs) {
        allVehiculesUsedIDs.add(element.data()['VehiculeID']);
      }

      myDB.collection('users/${currentlySignedInUser?.uid}/vehicules').get().then((vehiculesDocs) {
        if (vehiculesDocs.size != 0) {
          for (var vehiculeID in allVehiculesUsedIDs) {
            var matchingVehiculeDocList = vehiculesDocs.docs.where((element) => element.id == vehiculeID);
            allUserVehiculesUsedForBooking
                .add({matchingVehiculeDocList.first.id: matchingVehiculeDocList.first.data()});
          }
        } else {
          userHasNoVehicules = true;
        }
        allReservationInfoNeeded = {
          'allUserBookings': allUserBookings,
          'allBookedParkingsDetails': allBookedParkingsDetails,
          'allUserVehiculesUsedForBooking': allUserVehiculesUsedForBooking,
        };

        debugPrint(" allReservationInfoNeeded $allReservationInfoNeeded ");
      }).whenComplete(() {
        setStateCount < 1
            ? {
                setState(
                  () {},
                ),
                setStateCount += 1
              }
            : null;
      });
    } else {
      debugPrint("NO BOOKINGS FOR THIS USER");
    }

    return userHasBooking;
  }

//closinbrac
}
