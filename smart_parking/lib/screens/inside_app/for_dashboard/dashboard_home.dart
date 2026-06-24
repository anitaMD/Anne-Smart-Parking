// ignore_for_file: avoid_print, prefer_typing_uninitialized_variables, avoid_function_literals_in_foreach_calls

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:smart_parking/screens/inside_app/for_dashboard/dashb_panel.dart';
import 'package:smart_parking/screens/inside_app/for_dashboard/reservation_countdown.dart';
import 'package:smart_parking/services/firebase/firestore_service.dart';

import '../../../services/firebase/firebase_service.dart';

class DashboardHomePage extends StatefulWidget {
  final Function(bool canShow) canShowToggle;
  final void Function(int selectedIndex) getIndex;
  final int timeUntilResStartsFromBookingOverview;
  const DashboardHomePage(
      {Key? key,
      required this.canShowToggle,
      required this.getIndex,
      required this.timeUntilResStartsFromBookingOverview})
      : super(key: key);

  @override
  DashboardHomePageState createState() => DashboardHomePageState();
}

class DashboardHomePageState extends State<DashboardHomePage> {
  String walletFirstAndOnlyDocID = '';
  User? currentlySignedInUser;
  Set allParkingIDsConcerned = {};
  int count = 0, setStateCount = 0;
  final panelScrollController = ScrollController();
  final dragHandlePanelController = PanelController();
  var myDB = FirebaseFirestore.instance;
  var firebaseService = FirebaseService();
  var firestoreWalletService = FirestoreWalletService();
  bool canUpdateFields = false, userHasNoVehicules = false;
  List<Map<String, dynamic>> allUserBookings = [],
      allBookedParkingsDetails = [],
      allUserVehiculesUsedForBooking = [];
  Map<String, dynamic> allReservationInfoNeeded = {}, ok = {};

  @override
  void initState() {
    User? currentlySignedInUser = firebaseService.auth.currentUser;
    myDB
        .collection("users/${currentlySignedInUser?.uid}/wallet")
        .get()
        .then((value) async {
      value.docs.isEmpty
          ? {
              await firestoreWalletService
                  .addUserWalletInfoToFirebase(currentlySignedInUser)
                  .then((value) {
                myDB
                    .collection("users/${currentlySignedInUser?.uid}/wallet")
                    .get()
                    .then((value) => value.docs.first.id)
                    .then(
                  (value) {
                    debugPrint("WALLET ID: $value}");
                    setState(() {
                      walletFirstAndOnlyDocID = value;
                    });
                  },
                ).whenComplete(() => setState(
                          () {}, //do NOT REMOVE THIS EVER
                        ));
              })

              /*   await addUserWalletInfoToFirebase(currentlySignedInUser).then((value) {
                myDB
                    .collection("users/${currentlySignedInUser?.uid}/wallet")
                    .get()
                    .then((value) => value.docs.first.id)
                    .then(
                  (value) {
                    debugPrint("WALLET ID: $value}");
                    setState(() {
                      walletFirstAndOnlyDocID = value;
                    });
                  },
                ).whenComplete(() => setState(
                          () {}, //do NOT REMOVE THIS EVER
                        ));
              })
            */
            }
          : debugPrint('XROTE WRITE');
    });

    myDB.collection("slotsReservations").get().then(
      (value) {
        if (value.docs.isNotEmpty) {
          //
          var userBookings = value.docs.where((element) =>
              element.data()['ClientID'] == currentlySignedInUser?.uid);
          userBookings.isNotEmpty &&
                  allUserBookings.length < userBookings.length
              ? userBookings.forEach((element) {
                  // debugPrint("FOUND ONE :${element.doc.id}");
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

          if (allParkingIDsConcerned.length < allUserBookings.length) {
            for (var element in allUserBookings) {
              var reservationData =
                  element.values.first as Map<String, dynamic>;
              allParkingIDsConcerned.add(reservationData['ParkingID']);
              DocumentReference parkingsCollection = myDB
                  .collection("locations")
                  .doc(reservationData['ParkingID']);
              parkingsCollection.get().then((value) {
                allBookedParkingsDetails.add({value.id: value.data()});
                debugPrint(
                    "SORTED : ____ ${value.data()} ____ ${allBookedParkingsDetails.length}");
              }).whenComplete(() => setState(() {}));
            }
          }
          Set allVehiculesUsedIDs = {};
          for (var element in value.docs) {
            allVehiculesUsedIDs.add(element.data()['VehiculeID']);
          }

          myDB
              .collection('users/${currentlySignedInUser?.uid}/vehicules')
              .get()
              .then((vehiculesDocs) {
            if (vehiculesDocs.size != 0) {
              for (var vehiculeID in allVehiculesUsedIDs) {
                var matchingVehiculeDocList = vehiculesDocs.docs
                    .where((element) => element.id == vehiculeID);
                allUserVehiculesUsedForBooking.add({
                  matchingVehiculeDocList.first.id:
                      matchingVehiculeDocList.first.data()
                });
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
          //
        }

        return allReservationInfoNeeded;
      },
    );

    FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    FocusNode().dispose();
    super.dispose();
  }

  void updateWalletFields(QuerySnapshot<Map<String, dynamic>> walletCollection,
      String walletFirstAndOnlyDocID) {
    // ignore: unused_local_variable
    CollectionReference debitsCollection = myDB.collection(
        "users/${currentlySignedInUser?.uid}/wallet/$walletFirstAndOnlyDocID/debits");
    CollectionReference topUpsCollection = myDB.collection(
        "users/${currentlySignedInUser?.uid}/wallet/$walletFirstAndOnlyDocID/topUps");

    debugPrint("WALLETDOCS :${walletCollection.docs.first.id}");
    final theDocToUpdate = myDB
        .collection("users/${currentlySignedInUser?.uid}/wallet")
        .doc(walletCollection.docs.first.id);

    var ok = walletCollection.docs.first.data()['Transactions']['Top Ups']
        as Map<String, dynamic>;
    topUpsCollection.get().then((value) {
      List allIDList = [];
      for (var element in value.docs) {
        allIDList.add(element.id);
        debugPrint("YOURE HERE _ $ok _ _ $allIDList");
      }

      theDocToUpdate.update({'Transactions.Top Ups.IDs': allIDList});
    });
  }

  @override
  Widget build(BuildContext context) {
    currentlySignedInUser = firebaseService.auth.currentUser;
    debugPrint("THE WALLET ID: $walletFirstAndOnlyDocID ");

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
                      debugPrint("CHECK MIC: ${value.docs.length}");
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
                    /*  addDebitTopUp(currentlySignedInUser, walletFirstAndOnlyDocID).whenComplete(() => {
                          count < 1
                              ? Future.delayed(Duration(seconds: 2)).then(
                                  (value) {
                                    setState(
                                      () {
                                        canUpdateFields = true;
                                      },
                                    );
                                  },
                                )
                              : null,
                          count += 1,
                        }) */
                  }
          };
    canUpdateFields == false
        ? null
        : myDB
            .collection("users/${currentlySignedInUser?.uid}/wallet")
            .get()
            .then((value) async {
            updateWalletFields(value, walletFirstAndOnlyDocID);
            debugPrint("DOUBLE MIC: ${value.docs.length}");
          });
    double panelHeightClosed = MediaQuery.of(context).size.height * 0.1;
    double panelHeightOpened = MediaQuery.of(context).size.height * 0.55;

    return Scaffold(
        //backgroundColor: const Color(0xff392850),
        //backgroundColor: Colors.white,
        body: dashBSlidingUpPanel(panelHeightClosed, panelHeightOpened));
  }

  /*  Future<Map<String, dynamic>> getUserReservationDetails(User? currentlySignedInUser, FirebaseFirestore myDB,
      List<DocumentChange<Map<String, dynamic>>> allVehiculesTypesLogosFetched) async {
    //debugPrint("SLOTSRES :${value.docs.length}");
    if (allVehiculesTypesLogosFetched.isNotEmpty) {
      //
      var userBookings = allVehiculesTypesLogosFetched
          .where((element) => element.doc.data()!['ClientID'] == currentlySignedInUser?.uid);
      userBookings.isNotEmpty && allUserBookings.length < userBookings.length
          ? userBookings.forEach((element) {
              // debugPrint("FOUND ONE :${element.doc.id}");
              allUserBookings.add({element.doc.id: element.doc.data()!});
            })
          : null;

      allUserBookings.sort(
        (aData, bData) {
          var a = aData.values.first as Map<String, dynamic>;
          var b = bData.values.first as Map<String, dynamic>;

          var aBookingStart = a['BookingStart'] as Timestamp;
          var bBookingStart = b['BookingStart'] as Timestamp;
          return bBookingStart.compareTo(aBookingStart);
        },
      );

      if (allParkingIDsConcerned.length < allUserBookings.length) {
        for (var element in allUserBookings) {
          var reservationData = element.values.first as Map<String, dynamic>;
          allParkingIDsConcerned.add(reservationData['ParkingID']);
          DocumentReference parkingsCollection = myDB.collection("locations").doc(reservationData['ParkingID']);
          parkingsCollection.get().then((value) {
            allBookedParkingsDetails.add({value.id: value.data()});
            //debugPrint("SORTED : ____ ${value.data()} ____ ${allBookedParkingsDetails.length}");
          }).whenComplete(() => debugPrint("SORTEDLENGTH ${allBookedParkingsDetails.length}"));
        }
      }
      Set allVehiculesUsedIDs = {};
      for (var element in allVehiculesTypesLogosFetched) {
        allVehiculesUsedIDs.add(element.doc.data()!['VehiculeID']);
      }

      myDB.collection('users/${currentlySignedInUser?.uid}/vehicules').get().then((vehiculesDocs) {
        if (vehiculesDocs.size != 0) {
          allVehiculesUsedIDs.forEach((vehiculeID) {
            var matchingVehiculeDocList = vehiculesDocs.docChanges.where((element) => element.doc.id == vehiculeID);
            allUserVehiculesUsedForBooking
                .add({matchingVehiculeDocList.first.doc.id: matchingVehiculeDocList.first.doc.data()});
          });
        }

        allReservationInfoNeeded = {
          'allUserBookings': allUserBookings,
          'allBookedParkingsDetails': allBookedParkingsDetails,
          'allUserVehiculesUsedForBooking': allUserVehiculesUsedForBooking
        };
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
      //
    }

    debugPrint(" allReservationInfoNeeded $allReservationInfoNeeded ");

    return allReservationInfoNeeded;
  }
 */

  StreamBuilder<QuerySnapshot<Map<String, dynamic>>> dashBSlidingUpPanel(
      double panelHeightClosed, double panelHeightOpened) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection("slotsReservations")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Text(''); //Text('Loading brand logos');
          } else {
            //getUserReservationDetails(currentlySignedInUser, myDB, allVehiculesTypesLogosFetched);
            debugPrint("FOUND ONE :$allUserBookings");
            debugPrint("FOUND TWO :$allBookedParkingsDetails");
            debugPrint("FOUND THREE :$allUserVehiculesUsedForBooking");
            debugPrint("FOUND 4 :$allReservationInfoNeeded");
            debugPrint("FOUND 5 :$userHasNoVehicules");

            return SlidingUpPanel(
              renderPanelSheet: true,
              margin: EdgeInsets.zero,
              panel: DashBoardPanel(
                  panelScrollController: panelScrollController,
                  dragHandlePanelController: dragHandlePanelController),
              minHeight: panelHeightClosed,
              maxHeight: panelHeightOpened,
              /* parallaxEnabled: true,
              parallaxOffset: .5, */
              panelBuilder: (panelScrollController) => DashBoardPanel(
                panelScrollController: panelScrollController,
                dragHandlePanelController: dragHandlePanelController,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              body: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ReservationCountdown(
                      allReservationInfoNeeded: allReservationInfoNeeded,
                      currentlySignedInUser: currentlySignedInUser,
                      userHasVehicules: !userHasNoVehicules,
                      timeUntilResFetchedFromBookingOverview:
                          widget.timeUntilResStartsFromBookingOverview,
                      canShowToggle: widget.canShowToggle,
                      getIndex: widget.getIndex)
                ],
              ),
            );
          }
        });
  }
}

/* ////CHECK THESE COMMENTS...............................------------------------
  //LOOK ,!BAR, !Ignor, !notif, !exc!update, !Connectiv, !ViewR , !Toas, !DecorV, !LocalM, !Dialog, !IMM, !InputMe, !IInput, !InsetsC, !Surface, !W/Sys,

  /*  const Text(
                  'hello. THIS IS WHERE IT IS DISPLAYED A SEARCH BAR (maybe above a long height map) FOR nearby parkings (that) THE USERs CURRENT WALLET FUNDS, HIS VEHICLES (whenc clicked on "my vehicles", he can add, delete, edit vehicle info check this video link [https://www.youtube.com/watch?v=pBoyJpliZvQ] ), TIME LEFT BEFORE RESERVATION ENDS LIVE DECOMPTE'), */

/* 

// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_parking/screens/inside_app/testdash/griddashboard.dart';
import 'package:smart_parking/services/firestore_service.dart';

class DashboardHomePage extends StatefulWidget {
  final ScrollController scrollController;
  const DashboardHomePage({Key? key, required this.scrollController})
      : super(key: key);

  @override
  DashboardHomePageState createState() => DashboardHomePageState();
}

class DashboardHomePageState extends State<DashboardHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff392850),
      body: SingleChildScrollView(
        controller: widget.scrollController,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(
                height: 50,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(30, 2, 30, 2),
                child: Container(
                  color: Colors.white,
                  child: Row(
                    children: [
                      IconButton(
                        splashColor: Colors.grey,
                        icon: Icon(Icons.menu),
                        onPressed: () {},
                      ),
                      const Expanded(
                        child: TextField(
                          cursorColor: Colors.black,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.go,
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 15),
                              hintText: "Search parkings..."),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 50,
              ),
              const SizedBox(
                height: 140,
              ),
              const GridDashboard(),
            ],
          ),
        ),
      ),
    );
  }

  /*  const Text(
                  'hello. THIS IS WHERE IT IS DISPLAYED A SEARCH BAR (maybe above a long height map) FOR nearby parkings (that) THE USERs CURRENT WALLET FUNDS, HIS VEHICLES (whenc clicked on "my vehicles", he can add, delete, edit vehicle info check this video link [https://www.youtube.com/watch?v=pBoyJpliZvQ] ), TIME LEFT BEFORE RESERVATION ENDS LIVE DECOMPTE'), */

}
 */
*/
