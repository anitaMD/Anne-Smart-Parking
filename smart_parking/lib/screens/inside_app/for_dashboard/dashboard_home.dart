// ignore_for_file: avoid_print, prefer_typing_uninitialized_variables

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:smart_parking/screens/inside_app/for_dashboard/dashb_panel.dart';
import 'package:smart_parking/screens/inside_app/for_dashboard/reservation_countdown.dart';
import 'package:smart_parking/services/firebase/firestore_service.dart';

import '../../../services/firebase/firebase_service.dart';

class DashboardHomePage extends StatefulWidget {
  const DashboardHomePage({
    Key? key,
  }) : super(key: key);

  @override
  DashboardHomePageState createState() => DashboardHomePageState();
}

class DashboardHomePageState extends State<DashboardHomePage> {
  final panelScrollController = ScrollController();
  final dragHandlePanelController = PanelController();
  var myDB = FirebaseFirestore.instance;
  var firebaseService = FirebaseService();
  var firestoreWalletService = FirestoreWalletService();
  String walletFirstAndOnlyDocID = '';
  User? currentlySignedInUser;
  bool canUpdateFields = false;
  int count = 0;

  @override
  void initState() {
    User? currentlySignedInUser = firebaseService.auth.currentUser;
    myDB.collection("users/${currentlySignedInUser?.uid}/wallet").get().then((value) async {
      value.docs.isEmpty
          ? {
              await firestoreWalletService.addUserWalletInfoToFirebase(currentlySignedInUser).then((value) {
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
    FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    FocusNode().dispose();
    super.dispose();
  }

  updateWalletFields(QuerySnapshot<Map<String, dynamic>> walletCollection, String walletFirstAndOnlyDocID) {
    CollectionReference debitsCollection =
        myDB.collection("users/${currentlySignedInUser?.uid}/wallet/$walletFirstAndOnlyDocID/debits");
    CollectionReference topUpsCollection =
        myDB.collection("users/${currentlySignedInUser?.uid}/wallet/$walletFirstAndOnlyDocID/topUps");

    debugPrint("WALLETDOCS :${walletCollection.docs.first.id}");
    final theDocToUpdate =
        myDB.collection("users/${currentlySignedInUser?.uid}/wallet").doc(walletCollection.docs.first.id);

    var ok = walletCollection.docs.first.data()['Transactions']['Top Ups'] as Map<String, dynamic>;
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
                    myDB.collection("users/${currentlySignedInUser?.uid}/wallet").get().then((value) async {
                      debugPrint("CHECK MIC: ${value.docs.length}");
                    }),
                    firestoreWalletService
                        .initializeWalletDebitTopUp(currentlySignedInUser, walletFirstAndOnlyDocID)
                        .whenComplete(() => {
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
                                  : null,
                              count += 1,
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
        : myDB.collection("users/${currentlySignedInUser?.uid}/wallet").get().then((value) async {
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

  Future<QuerySnapshot<Map<String, dynamic>>> addDebitTopUp(User? currentlySIUser, String walletCollId) {
    //creating debits collection
    CollectionReference walletDebitCollection =
        myDB.collection("users/${currentlySIUser?.uid}/wallet/$walletCollId/debits");
    WriteBatch batchDebit = myDB.batch(), batchTopUp = myDB.batch();

    myDB.collection("users/${currentlySIUser?.uid}/wallet/$walletCollId/debits").get().then((value) async {
      if (value.docs.isEmpty) {
        myDB.doc("users/${currentlySIUser?.uid}/wallet/$walletCollId").collection("debits").add({'initialized': true});
      }

      batchDebit.set(
          //maybe add timestamp later to know when the car was added
          walletDebitCollection.doc(),
          {
            'Debit Amount': 0,
            'RecipientParking ID': '',
            'TimeStamp': FieldValue.serverTimestamp()
          }); //{'Debit Amount': 0, 'RecipientParking ID': '', 'TimeStamp': FieldValue.serverTimestamp()});
      await batchDebit.commit().whenComplete(() => debugPrint("DEBIT SUCCESSFULLY ADDED"));
      await myDB.collection("users/${currentlySIUser?.uid}/wallet/$walletCollId/debits").get().then((value) async {
        var firstInitializedDoc = value.docs.where((element) => element.data().keys.contains('initialized'));
        firstInitializedDoc.isNotEmpty ? await walletDebitCollection.doc(firstInitializedDoc.first.id).delete() : null;
      });
    });

    //CreatingTopUp collection

    CollectionReference walletTopUpCollection =
        myDB.collection("users/${currentlySIUser?.uid}/wallet/$walletCollId/topUps");
    myDB.collection("users/${currentlySIUser?.uid}/wallet/$walletCollId/topUps").get().then((value) async {
      if (value.docs.isEmpty) {
        myDB.doc("users/${currentlySIUser?.uid}/wallet/$walletCollId").collection("topUps").add({'initialized': true});
      }

      batchTopUp.set(
          //maybe add timestamp later to know when the car was added
          walletTopUpCollection.doc(),
          {
            'TopUp Amount': 5000,
            'From': 'Your Smart Parking',
            'Type': 'Welcome Gift',
            'TimeStamp': FieldValue.serverTimestamp()
          });

      await batchTopUp.commit().whenComplete(() => debugPrint("DEBIT SUCCESSFULLY ADDED"));

      await myDB.collection("users/${currentlySIUser?.uid}/wallet/$walletCollId/topUps").get().then((value) async {
        var firstInitializedDoc = value.docs.where((element) => element.data().keys.contains('initialized'));
        firstInitializedDoc.isNotEmpty ? await walletTopUpCollection.doc(firstInitializedDoc.first.id).delete() : null;
      });
    });

    return myDB.collection("users/${currentlySIUser?.uid}/wallet").get();
  }

  /*  Future<QuerySnapshot<Map<String, dynamic>>> test(User? currentlySIUser, String walletID) {
    CollectionReference walletCollection = myDB.collection("users/${currentlySIUser?.uid}/wallet/$walletID/debit");
    WriteBatch batchWallet = myDB.batch();

    myDB.collection("users/${currentlySIUser?.uid}/wallet/$walletID/debit").get().then((value) async {
      if (value.docs.isEmpty) {
        myDB.doc("users/${currentlySIUser?.uid}/wallet/$walletID").collection("debit").add({'initialized': true});
      }

      batchWallet.set(
          //maybe add timestamp later to know when the car was added
          walletCollection.doc(),
          {
            'DebitsTest': {'Total Entries': 0, 'Items': {}},
          });
      await batchWallet.commit().whenComplete(() => debugPrint("WALLET SUCCESSFULLY ADDED"));
      await myDB.collection("users/${currentlySIUser?.uid}/wallet/$walletID/debit").get().then((value) async {
        var firstInitializedDoc = value.docs.where((element) => element.data().keys.contains('initialized'));

        firstInitializedDoc.isNotEmpty ? await walletCollection.doc(firstInitializedDoc.first.id).delete() : null;
      });
    });

    return myDB.collection("users/${currentlySIUser?.uid}/wallet").get();
  }
 */
  Future<QuerySnapshot<Map<String, dynamic>>> addUserWalletInfoToFirebase(User? currentlySIUser) {
    myDB.collection("users/${currentlySIUser?.uid}/wallet").get().then((value) async {
      if (value.docs.isEmpty) {
        myDB.doc("users/${currentlySIUser?.uid}").collection("wallet").add({
          'Balance': 5000,
          'Transactions': {
            'Top Ups': {'Total Entries': 1, 'IDs': <String>[]},
            'Debits': {'Total Entries': 0, 'IDs': <String>[]},
          },
        });
      }
    });

    return myDB.collection("users/${currentlySIUser?.uid}/wallet").get();
  }

  SlidingUpPanel dashBSlidingUpPanel(double panelHeightClosed, double panelHeightOpened) {
    return SlidingUpPanel(
      renderPanelSheet: true,
      margin: EdgeInsets.zero,
      panel: DashBoardPanel(
          panelScrollController: panelScrollController, dragHandlePanelController: dragHandlePanelController),
      minHeight: panelHeightClosed,
      maxHeight: panelHeightOpened,
      parallaxEnabled: true,
      parallaxOffset: .5,
      panelBuilder: (panelScrollController) => DashBoardPanel(
        panelScrollController: panelScrollController,
        dragHandlePanelController: dragHandlePanelController,
      ),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      /*   panelBuilder: (panelScrollController) => RefreshAndSlideUp(
                    notifyParent: refresh,
                    mappedMarkers: myMapMarkers,
                    panelScrollController: panelScrollController,
                    dragHandlePanelController: drangHandlePanelController,
                  ), */ //MAKE THE BLACK CONTAINER The draggable tiroir hand icon
      body: Column(
        children: const [
          ReservationCountdown(),
        ],
      ),
    );
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
