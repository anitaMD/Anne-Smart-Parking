// ignore_for_file: avoid_unnecessary_containers, avoid_function_literals_in_foreach_calls

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:smart_parking/screens/inside_app/for_wallet/light_color.dart';
import 'package:smart_parking/services/firebase/firestore_service.dart';

import '../../services/firebase/firebase_service.dart';
import 'for_wallet/operation_details.dart';

class Wallet extends StatefulWidget {
  const Wallet({Key? key}) : super(key: key);

  @override
  WalletState createState() => WalletState();
}

class WalletState extends State<Wallet> {
  var myDB = FirebaseFirestore.instance;
  var firebaseService = FirebaseService();
  var firestoreWalletService = FirestoreWalletService();
  final CarouselController _controller = CarouselController();
  User? currentlySignedInUser;
  int current = 0, currentIndex = 0, oneSMP = 500;
  double dragExtent = 0;
  bool revealBalance = false, areTimesStampsSorted = false;
  String swipeDirection = '', walletFirstAndOnlyDocID = '', balanceInCFA = '', balanceInSPM = '';
  Map<String, dynamic> initiallyLoadedTransactions = {'TopUps': {}, 'Debits': {}}, walletData = {};
  List<Map<String, dynamic>> allTransactionsWithIDs = [];
  //List allTransactionsTStampsNotSorted = [], sortedAllTransactionsTStamps = <Timestamp>[];

  // Set allTransactionsSortedSet = {};

  @override
  void initState() {
    User? currentlySignedInUser = firebaseService.auth.currentUser;
    myDB.collection("users/${currentlySignedInUser?.uid}/wallet").get().then((value1) async {
      value1.docs.isEmpty
          ? null
          : {
              myDB
                  .collection("users/${currentlySignedInUser?.uid}/wallet")
                  .get()
                  .then((value1) => value1.docs.first.id)
                  .then(
                (walletID) {
                  //start
                  debugPrint("WALLET ID: $walletID}");
                  setState(() {
                    walletFirstAndOnlyDocID = walletID;
                  });
                  //topUps
                  myDB
                      .collection("users/${currentlySignedInUser?.uid}/wallet")
                      .doc(walletID)
                      .collection('topUps')
                      .get()
                      .then((value) {
                    Map<String, dynamic> topUpEntries = {};
                    for (var element in value.docs) {
                      debugPrint("element: ${element.data()}");

                      topUpEntries.addAll({'ID': element.id, 'Operation': element.data()});
                    }
                    initiallyLoadedTransactions.update('TopUps', (value) => topUpEntries);
                    debugPrint("INITALLYLOADED :$initiallyLoadedTransactions ");
                  });

                  //debits
                  myDB
                      .collection("users/${currentlySignedInUser?.uid}/wallet")
                      .doc(walletID)
                      .collection('debits')
                      .get()
                      .then((value) {
                    Map<String, dynamic> debitEntries = {};
                    for (var element in value.docs) {
                      debugPrint("element: ${element.data()}");
                      element.data()['Debit Amount'] == 0
                          ? null
                          : debitEntries.addAll({'ID': element.id, 'Operation': element.data()});
                    }
                    initiallyLoadedTransactions.update('Debits', (value) => debitEntries);
                    debugPrint("INITALLYLOADED debi :$initiallyLoadedTransactions ");
                  });

                  //end
                },
              ).whenComplete(() => setState(
                        () {}, //do NOT REMOVE THIS EVER
                      ))
            };
    });

    myDB.collection("users/${currentlySignedInUser?.uid}/wallet").get().then((value) => {
          setState(
            () {
              balanceInCFA = value.docs.first.data()['Balance'].toString();
              balanceInSPM = (int.parse(balanceInCFA) ~/ oneSMP).toString();
            },
          )
        });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // ADD TWO CARDS (show wallet card && showtransactions which will both ask you to input some code and then display the current getWallet and panelBody
    // function getTransparentWallet will be like a transparent card or blurred )
    double panelHeightClosed = MediaQuery.of(context).size.height * 0.1;
    double panelHeightOpened = MediaQuery.of(context).size.height * 0.5;
    currentlySignedInUser = firebaseService.auth.currentUser;
    //initiallyLoadedTransactions.values.where
    debugPrint("TOLISTED $walletFirstAndOnlyDocID");
    return Scaffold(
        backgroundColor: Colors.white,
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection("users/${currentlySignedInUser?.uid}/wallet").snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Text('');
              } else {
                //String source = snapshot.data!.metadata.hasPendingWrites ? "Local" : "Server";
                // insideParkingInfoFetched.clear();
                walletData = snapshot.data!.docs[0].data();

                String walletIDTest = snapshot.data!.docs[0].id;
                balanceInCFA = walletData['Balance'].toString();
                balanceInSPM = (int.parse(balanceInCFA) ~/ oneSMP).toString();

                listeningToWalletsRT(walletIDTest);

                var okDebit = myDB
                    .collection("users/${currentlySignedInUser?.uid}/wallet/$walletIDTest/debits")
                    .snapshots()
                    .where((event) {
                  return event.docs.any((element) => element.data()['Debit Amount'] != 0);
                });
                int debitEntriesTotal = 0;

                okDebit.first.then((value) => value.docs.forEach((element) {
                      allTransactionsWithIDs.length < value.docs.length
                          ? {
                              allTransactionsWithIDs.addAll([
                                {element.id: element.data()}
                              ]),
                              debitEntriesTotal += 1
                            }
                          : null;
                      /*  allTransactionsWithIDs.length == allTransactionsTStampsNotSorted .length
                          ? null
                          : allTransactionsTStampsNotSorted.add([element.id, element.data()['TimeStamp']]); */
                    }));

                var okTopUp = myDB
                    .collection("users/${currentlySignedInUser?.uid}/wallet/$walletIDTest/topUps")
                    .snapshots()
                    .where((event) {
                  return event.docs.any((element) => element.data().containsKey('TopUp Amount'));
                });

                okTopUp.first.then((value) => value.docs.forEach((element) {
                      allTransactionsWithIDs.length < value.docs.length + debitEntriesTotal
                          ? allTransactionsWithIDs.addAll([
                              {element.id: element.data()}
                            ])
                          : null;
                    }));

                areTimesStampsSorted == false
                    ? debugPrint("allTransactionsWithIDs BEFORE SORTED: $allTransactionsWithIDs")
                    : debugPrint("allTransactionsWithIDs AFTER SORTED: $allTransactionsWithIDs");

                allTransactionsWithIDs.sort(
                  (a, b) {
                    var aValuesData = a.values.first as Map<String, dynamic>;
                    var bValuesData = b.values.first as Map<String, dynamic>;

                    var aTS = aValuesData['TimeStamp'] as Timestamp;
                    var bTS = bValuesData['TimeStamp'] as Timestamp;
                    return bTS.compareTo(aTS);
                  },
                );
                areTimesStampsSorted = true;

                return SlidingUpPanel(
                  parallaxEnabled: true,
                  renderPanelSheet: false,
                  maxHeight: panelHeightOpened,
                  minHeight: panelHeightClosed,
                  margin: const EdgeInsets.fromLTRB(10, 100, 10, 0),
                  panelBuilder: (ScrollController sc) => _scrollingList(sc),
                  body: Column(children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(8, 50, 8, 0),
                      child: Text(
                        'YOUR WALLET',
                        style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: LightColor.black),
                      ),
                    ),
                    getWalletCard(),
                    ElevatedButton(
                        onPressed: () => topUp(currentlySignedInUser, walletFirstAndOnlyDocID),
                        /* firestoreWalletService.topUp(currentlySignedInUser,
                            walletFirstAndOnlyDocID), */ //topUp(currentlySignedInUser, walletFirstAndOnlyDocID),
                        child: const Text('Top Up'))
                  ]),
                );
              }
            }));
  }

  getContainerLeft() {
    return Container(
        child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(25)),
            child: Container(
              width: 400,
              height: 200,
              color: LightColor.navyBlue1,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        'Current Balance,',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: LightColor.lightNavyBlue),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            revealBalance == true ? balanceInSPM : '****',
                            style: GoogleFonts.mulish(
                                textStyle: Theme.of(context).textTheme.headline4,
                                fontSize: 35,
                                fontWeight: FontWeight.w800,
                                color: LightColor.yellow2),
                          ),
                          Text(
                            ' SMP',
                            style: TextStyle(
                                fontSize: 35, fontWeight: FontWeight.w500, color: LightColor.yellow.withAlpha(200)),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            'Eq:',
                            style: GoogleFonts.mulish(
                                textStyle: Theme.of(context).textTheme.headline4,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: LightColor.lightNavyBlue),
                          ),
                          Text(
                            revealBalance == true ? ' $balanceInCFA CFA' : ' * * * * * CFA',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Container(
                          width: 55,
                          height: 40,
                          //padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(Radius.circular(12)),
                              border: Border.all(color: Colors.white, width: 1)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              IconButton(
                                style: const ButtonStyle(),
                                icon: Icon(revealBalance == false ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.white, size: 20),
                                highlightColor: Colors.green,
                                onPressed: () {
                                  setState(() {
                                    revealBalance == false ? revealBalance = true : revealBalance = false;
                                  });
                                },
                              ),
                              // SizedBox(width: 5),
                              //Text(" ", style: TextStyle(color: Colors.white)),
                            ],
                          ))
                    ],
                  ),
                  const Positioned(
                    left: -170,
                    top: -170,
                    child: CircleAvatar(
                      radius: 130,
                      backgroundColor: LightColor.lightBlue2,
                    ),
                  ),
                  const Positioned(
                    left: -160,
                    top: -190,
                    child: CircleAvatar(
                      radius: 130,
                      backgroundColor: LightColor.lightBlue1,
                    ),
                  ),
                  const Positioned(
                    right: -170,
                    bottom: -170,
                    child: CircleAvatar(
                      radius: 130,
                      backgroundColor: LightColor.yellow2,
                    ),
                  ),
                  const Positioned(
                    right: -160,
                    bottom: -190,
                    child: CircleAvatar(
                      radius: 130,
                      backgroundColor: LightColor.yellow,
                    ),
                  )
                ],
              ),
            )));
  }

  getContainerRight() {
    return Container(
        child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(25)),
            child: Container(
              width: 400,
              height: 200,
              color: LightColor.navyBlue1,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Center(
                    child: QrImage(
                      gapless: true,
                      padding: const EdgeInsets.all(20),
                      embeddedImage: const AssetImage('assets/images/logo.png'),
                      embeddedImageStyle: QrEmbeddedImageStyle(color: Colors.yellow, size: const Size(130, 130)),
                      data: "1234567890",
                      version: QrVersions.auto,
                      //size: 200.0,
                      foregroundColor: const Color.fromARGB(187, 255, 255, 255),
                    ),
                  ),
                  const Positioned(
                    left: -170,
                    top: -170,
                    child: CircleAvatar(
                      radius: 130,
                      backgroundColor: LightColor.lightBlue2,
                    ),
                  ),
                  const Positioned(
                    left: -160,
                    top: -190,
                    child: CircleAvatar(
                      radius: 130,
                      backgroundColor: LightColor.lightBlue1,
                    ),
                  ),
                  const Positioned(
                    right: -170,
                    bottom: -170,
                    child: CircleAvatar(
                      radius: 130,
                      backgroundColor: LightColor.yellow2,
                    ),
                  ),
                  const Positioned(
                    right: -160,
                    bottom: -190,
                    child: CircleAvatar(
                      radius: 130,
                      backgroundColor: LightColor.yellow,
                    ),
                  )
                ],
              ),
            )));
  }

  getWalletCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 50, 10, 50),
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: LightColor.lightNavyBlue,
            blurRadius: 5.0, // soften the shadow
            spreadRadius: 3.0, //extend the shadow
            offset: Offset(
              5.0, // Move to right 5  horizontally
              5.0, // Move to bottom 5 Vertically
            ),
          ),
        ],
        borderRadius: BorderRadius.all(Radius.circular(25)),
        color: LightColor.lightNavyBlue,
      ),
      child: SingleChildScrollView(
        child: GestureDetector(
            onHorizontalDragStart: ((details) {
              setState(() {
                dragExtent = 0;
              });
            }),
            onHorizontalDragUpdate: (details) {
              dragExtent += details.primaryDelta!;
              setState(() {});
            },
            onHorizontalDragEnd: (details) {
              if (dragExtent < 0) {
                currentIndex < 1
                    ? setState(() {
                        swipeDirection = 'next';
                        currentIndex = 1;
                      })
                    : null;
              } else {
                currentIndex > 0
                    ? setState(() {
                        swipeDirection = 'prev';
                        currentIndex = 0;
                      })
                    : null;

                debugPrint("SWIPE DIRECTION: $swipeDirection _ _ currentIndex $currentIndex");
              }
            },
            child: swipeDirection == 'next' ? getContainerRight() : getContainerLeft()

            /* SlidableWalletCard(
            childLeft: getContainerLeft(),
            childRight: getContainerRight(),
            onSlided: updateIndex,
          ) */
            ),
      ),
    );
  }

  _scrollingList(ScrollController sc) {
    return Container(
      decoration: const BoxDecoration(
          color: LightColor.navyBlue1,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24.0), topRight: Radius.circular(24.0)),
          boxShadow: [
            BoxShadow(
              blurRadius: 5.0,
              color: Colors.grey,
              spreadRadius: 3.0, //extend the shadow
              offset: Offset(
                0.0, // Move to right 5  horizontally
                5.0, // Move to bottom 5 Vertically
              ),
            ),
          ]),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 18, bottom: 18),
            decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                border: Border.all(color: Colors.white, width: 1)),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                "TRANSACTIONS HISTORY",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              controller: sc,
              itemCount: allTransactionsWithIDs.length,
              itemBuilder: (BuildContext context, int i) {
                var values = allTransactionsWithIDs.elementAt(i).values.first as Map<String, dynamic>;
                bool isTopUpOperation = values.containsKey('TopUp Amount') ? true : false;
                var timeStamp = values['TimeStamp'] as Timestamp;
                var timeStampToDate = timeStamp.toDate();
                return Container(
                  padding: const EdgeInsets.all(12.0),
                  // height: 50,
                  color: Colors.green,
                  child: Material(
                    child: InkWell(
                        onTap: () {
                          debugPrint("PRESSED ON INKWELL");
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ShowOperationDetails(
                                      transactionData: allTransactionsWithIDs.elementAt(i),
                                      transactionType: isTopUpOperation ? 'TopUp' : 'Debit',
                                    )),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(isTopUpOperation ? 'Received' : "Paid"),
                                Text(isTopUpOperation
                                    ? '${values['TopUp Amount']} CFA'
                                    : "-${values['TopUp Amount']} CFA"),
                              ],
                            ),
                            Text(DateFormat.yMMMd().format(timeStampToDate)),
                          ],
                        )),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<QuerySnapshot<Map<String, dynamic>>> topUp(User? currentlySIUser, String walletCollId) {
    WriteBatch batchTopUp = myDB.batch();

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
            'TopUp Amount': 8500,
            'From': 'Agent',
            'Type': 'Top Up From Agent',
            'TimeStamp': FieldValue.serverTimestamp(),
            'New Balance': int.parse(balanceInCFA) + 8500
          });

      await batchTopUp.commit().whenComplete(() => debugPrint("TOP UP SUCCESSFULLY ADDED"));

      await myDB.collection("users/${currentlySIUser?.uid}/wallet/$walletCollId/topUps").get().then((value) async {
        var firstInitializedDoc = value.docs.where((element) => element.data().keys.contains('initialized'));
        firstInitializedDoc.isNotEmpty ? await walletTopUpCollection.doc(firstInitializedDoc.first.id).delete() : null;
      });
    });

    return myDB.collection("users/${currentlySIUser?.uid}/wallet").get();
  }

  void listeningToWalletsRT(String walletIDTest) {
    List allWalletTopUpIDs = [], allWalletDebitIDs = [];
    int totalEntriesTopUps = 0, totalEntriesDebit = 0;
    final theDocToUpdate = myDB.collection("users/${currentlySignedInUser?.uid}/wallet").doc(walletIDTest);
    theDocToUpdate.get().then((value) {
      var topUpList = value.data()!['Transactions']['Top Ups']['IDs'] as List;
      allWalletTopUpIDs.length < topUpList.length ? allWalletTopUpIDs = topUpList : null;

      var debitList = value.data()!['Transactions']['Debits']['IDs'] as List;
      allWalletDebitIDs.length < debitList.length ? allWalletDebitIDs = debitList : null;

      totalEntriesTopUps = value.data()!['Transactions']['Top Ups']['Total Entries'];
      totalEntriesDebit = value.data()!['Transactions']['Debits']['Total Entries'];
    });
    FirebaseFirestore.instance
        .collection("users/${currentlySignedInUser?.uid}/wallet/$walletIDTest/topUps")
        .where("TopUp Amount", isGreaterThan: 10)
        .snapshots()
        .listen((event) {
      for (var change in event.docChanges) {
        switch (change.type) {
          case DocumentChangeType.added:
            debugPrint("Document Just Loaded: ${change.doc.data()}");
            //  debugPrint("REAL TIME CHECK __ ${change.doc.data()!['BookingStart']} __ ${change.doc.id}");
            //sortedAllTransactionsTStamps = allTransactionsTStampsNotSorted.sort();

            break;
          case DocumentChangeType.modified:
            debugPrint("Document Just Modified: ${change.doc.data()}");
            allTransactionsWithIDs.length < event.docs.length
                ? {
                    allTransactionsWithIDs.addAll([
                      {
                        change.doc.id: change.doc.data(),
                      }
                    ]),
                    allWalletTopUpIDs.add(change.doc.id),
                    theDocToUpdate.update({'Balance': int.parse(balanceInCFA) + change.doc.data()!['TopUp Amount']}),
                    theDocToUpdate.update({'Transactions.Top Ups.IDs': allWalletTopUpIDs}),
                    theDocToUpdate.update({'Transactions.Top Ups.Total Entries': totalEntriesTopUps + 1}),
                  }
                : null;
            debugPrint("alltransactionsAFTER LISTEN $allTransactionsWithIDs ___ ${allTransactionsWithIDs.length}");

            break;
          case DocumentChangeType.removed:
            debugPrint("Reservation DONE SO Archived: ${change.doc.data()}");
            break;
        }
      }
    });

    //debits
    FirebaseFirestore.instance
        .collection("users/${currentlySignedInUser?.uid}/wallet/$walletIDTest/debits")
        .where("Debit Amount", isGreaterThan: 0)
        .snapshots()
        .listen((event) {
      for (var change in event.docChanges) {
        switch (change.type) {
          case DocumentChangeType.added:
            debugPrint("Document Just Loaded: ${change.doc.data()}");

            break;
          case DocumentChangeType.modified:
            debugPrint("Document Just Modified: ${change.doc.data()}");
            allTransactionsWithIDs.length < event.docs.length
                ? {
                    allTransactionsWithIDs.addAll([
                      {change.doc.id: change.doc.data()}
                    ]),
                    theDocToUpdate.update({'Balance': int.parse(balanceInCFA) - change.doc.data()!['Debit Amount']}),
                    allWalletTopUpIDs.add(change.doc.id),
                    theDocToUpdate.update({'Transactions.Debits.IDs': allWalletDebitIDs}),
                    theDocToUpdate.update({'Transactions.Debits.Total Entries': totalEntriesDebit + 1}),
                  }
                : null;
            debugPrint("alltransactionsAFTER LISTEN $allTransactionsWithIDs ____ ${allTransactionsWithIDs.length}");

            break;
          case DocumentChangeType.removed:
            debugPrint("Reservation DONE SO Archived: ${change.doc.data()}");
            break;
        }
      }
    });
  }

//
}
  /*   return Container(
        margin: const EdgeInsets.fromLTRB(10, 50, 10, 50),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SingleChildScrollView(
            child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          CarouselSlider.builder(
            carouselController: _controller,
            itemCount: 2,
            itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) {
              return Container(
                  child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(25)),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        height: MediaQuery.of(context).size.width * 0.9 / 2,
                        color: LightColor.navyBlue1,
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                const Text(
                                  'Current Balance,',
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w500, color: LightColor.lightNavyBlue),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      '6,354',
                                      style: GoogleFonts.mulish(
                                          textStyle: Theme.of(context).textTheme.headline4,
                                          fontSize: 35,
                                          fontWeight: FontWeight.w800,
                                          color: LightColor.yellow2),
                                    ),
                                    Text(
                                      ' SMP',
                                      style: TextStyle(
                                          fontSize: 35,
                                          fontWeight: FontWeight.w500,
                                          color: LightColor.yellow.withAlpha(200)),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      'Eq:',
                                      style: GoogleFonts.mulish(
                                          textStyle: Theme.of(context).textTheme.headline4,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: LightColor.lightNavyBlue),
                                    ),
                                    const Text(
                                      ' 10.000 CFA',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Container(
                                    width: 85,
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                                    decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.all(Radius.circular(12)),
                                        border: Border.all(color: Colors.white, width: 1)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const <Widget>[
                                        Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        SizedBox(width: 5),
                                        Text("Top up", style: TextStyle(color: Colors.white)),
                                      ],
                                    ))
                              ],
                            ),
                            const Positioned(
                              left: -170,
                              top: -170,
                              child: CircleAvatar(
                                radius: 130,
                                backgroundColor: LightColor.lightBlue2,
                              ),
                            ),
                            const Positioned(
                              left: -160,
                              top: -190,
                              child: CircleAvatar(
                                radius: 130,
                                backgroundColor: LightColor.lightBlue1,
                              ),
                            ),
                            const Positioned(
                              right: -170,
                              bottom: -170,
                              child: CircleAvatar(
                                radius: 130,
                                backgroundColor: LightColor.yellow2,
                              ),
                            ),
                            const Positioned(
                              right: -160,
                              bottom: -190,
                              child: CircleAvatar(
                                radius: 130,
                                backgroundColor: LightColor.yellow,
                              ),
                            )
                          ],
                        ),
                      )));
            },
            options: CarouselOptions(
              onPageChanged: (index, reason) {
                setState(() {
                  current = index;
                });
              },
              height: MediaQuery.of(context).size.width * 0.9 / 2,
              pageSnapping: false,
              // aspectRatio: 16 / 9,
              viewportFraction: 0.8,
              initialPage: 0,
              enableInfiniteScroll: false,
              reverse: false,
              enlargeCenterPage: true,
              scrollDirection: Axis.horizontal,
            ),
          ),
          //
          AnimatedSmoothIndicator(
            activeIndex: current,
            duration: const Duration(milliseconds: 400),
            count: 2,
            effect: const WormEffect(
                type: WormType.normal,
                spacing: 5.0,
                radius: 20.0,
                dotWidth: 10.0,
                dotHeight: 10.0,
                paintStyle: PaintingStyle.stroke,
                strokeWidth: 1.5,
                dotColor: Colors.black,
                activeDotColor: Colors.indigo),
          ),
        ])));
  */ 

