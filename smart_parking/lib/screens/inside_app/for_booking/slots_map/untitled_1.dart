// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
  @override
  void initState() {
    //getAlleySlotsId(parkingSlotsTotal);
    super.initState();
  }

  void getAlleySlotsId(dynamic parkingSlotsTotal) {
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

  int i = 0;
  List<Map<String, dynamic>> verif = [];
  double alleyHeight = 200,
      singleSpotHeight = 50,
      singleSpotWidth = 120,
      spaceBetweenSlots = 35.0;
  double alleySpotWidthRatio = 1 / 4;
  bool isSelected = false;
  final alleyA = <String>{}, alleyB = <String>{};
  String maguy = '';

  var mappedAlleyASelectedCheck = {}, mappedAlleyBSelectedCheck = {};
  Map<String, dynamic> insideParkingInfoFetched = {};
  List<Map<String, dynamic>> mappedSelectedSlotAlley = [];
  Map<String, dynamic> linkedParkingNameAndInsideInfo = {};
  Map<String, Set> mappedAlleysAndSlotIds = {};

  int parkingSlotsTotal = 10;
  var lili = <String, dynamic>{}, magui = <String, dynamic>{};

  final initialDate = DateTime.now();
  bool isReservationDayPicked = false,
      isReservationStartTimePicked = false,
      isReservationDurationPicked = false,
      firstTimeAskingForDateSelect = true;

  Color slotHighlithgColor = Colors.green;
  Color finalSelectedColorSlot = Colors.transparent;

  DateTime reservedDate = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      0,
      0); //TO BE UPDATED WITH SETSTATE. This is just a random initialization

  void fetchAlleySelectedSlotId(int i, String alley) {
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

  @override
  Widget build(BuildContext context) {
    print(
        "Today : $initialDate ___________ PICKED DATE: $reservedDate ____now ${DateTime.now()}");
    var alleyListViewMinHeightToDisplay = alleyHeight +
        (spaceBetweenSlots * parkingSlotsTotal ~/ (parkingSlotsTotal ~/ 2));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                            .last
                            .split(':')
                            .toList()
                            .elementAt(1)
                            .split('}')
                            .first;
                        linkedParkingNameAndInsideInfo.addAll({
                          'Parking Name': currentlySelectedParkingsName,
                          'Info': insideParkingInfoFetched
                        });

                        snapshot.data!.docs[0]
                            .data()
                            .update('Occupied Slots', (value) => 2);

                        //FIND A WAY TO GET DATA SNAPSHOT: { Another Smart Parking: {Available Slots: 10, Total Slots Number: 10, Occupied Slots: 0}} ___________ SOURCE: Server _ 10, SECOND PARKING TOUCHED, THIRD PARKING TOUCHED,... everytime the user touches oa parking, that parking's info is added to the map or list or whatever so la liste augmente
                      }
                    }
                    parkingSlotsTotal =
                        insideParkingInfoFetched["Total Slots Number"];
                    getAlleySlotsId(parkingSlotsTotal);
                    //insideParkingInfoFetched.update("Occupied Slots", (value) => 5);
                    //getInsideParkingSlotsInfo(insideParkingInfoFetched); STOPPED HERE

                    print(
                        "DATA SNAPSHOT: $linkedParkingNameAndInsideInfo)))) SOURCE: $source _____ ${insideParkingInfoFetched["Available Slots"]}");
                    return Container(
                      color: Colors.transparent,
                      height: MediaQuery.of(context).size.height / 2,
                      child: SingleChildScrollView(
                        child: Container(
                          margin: const EdgeInsets.only(left: 10, right: 10),
                          color: Colors.transparent,
                          width: double.infinity,
                          padding: const EdgeInsets.only(top: 10),
                          child: Column(
                            children: [
                              const SizedBox(
                                height: 20,
                              ),
                              ElevatedButton(
                                  onPressed: () {},
                                  child: const Text('SELECT TIME')),
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                            color: Colors.indigo.withAlpha(10),
                                            border: Border(
                                              left: BorderSide(
                                                  color: Colors.indigo
                                                      .withAlpha(30),
                                                  width: 2),
                                              right: BorderSide(
                                                  color: Colors.indigo
                                                      .withAlpha(30),
                                                  width: 2),
                                            )),
                                        width:
                                            MediaQuery.of(context).size.width *
                                                alleySpotWidthRatio,
                                        height:
                                            alleyListViewMinHeightToDisplay, //otherwise, the slot will appear cutted so I need to show at least half of half the alley number of slots for UI concerns
                                        child: ListView.separated(
                                          shrinkWrap: false,
                                          itemCount: parkingSlotsTotal ~/ 2,
                                          itemBuilder: (context, index) {
                                            final item = buildLeftAlleySlots(
                                                parkingSlotsTotal,
                                                spaceBetweenSlots,
                                                isSelected)[index];
                                            return item;
                                          },
                                          separatorBuilder:
                                              (BuildContext context,
                                                  int index) {
                                            return SizedBox(
                                                height: spaceBetweenSlots);
                                          },
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          color: Colors.indigo.withAlpha(20),
                                          height:
                                              alleyListViewMinHeightToDisplay,
                                          child: const Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Positioned(
                                                top: 0,
                                                child: Icon(
                                                    Icons.arrow_circle_down),
                                              ),
                                              Positioned(
                                                bottom: 0,
                                                child: Icon(
                                                    Icons.arrow_circle_down),
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
                                                  color: Colors.indigo
                                                      .withAlpha(30),
                                                  width: 2),
                                              right: BorderSide(
                                                  color: Colors.indigo
                                                      .withAlpha(30),
                                                  width: 2),
                                            )),
                                        width:
                                            MediaQuery.of(context).size.width *
                                                alleySpotWidthRatio,
                                        height: alleyListViewMinHeightToDisplay,
                                        child: ListView.separated(
                                          shrinkWrap: false,
                                          itemCount: parkingSlotsTotal ~/ 2,
                                          itemBuilder: (context, index) {
                                            final item = buildRightAlleySlots(
                                                parkingSlotsTotal,
                                                spaceBetweenSlots,
                                                isSelected)[index];
                                            return item;
                                          },
                                          separatorBuilder:
                                              (BuildContext context,
                                                  int index) {
                                            return SizedBox(
                                                height: spaceBetweenSlots);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                  onPressed: () {}, child: const Text("data")),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                }),
          ],
        ),
      ),
    );
    //WILLL NEED 3 COLUMNS with an expanded or flex for the 3 vertical columns and in each of the two extreme columns, INKWELL AND A CONATINER CHILD FOR EACH SLOT with the icons and colors. So find a wwway to create a function that allows me to show those and not repeat code much
  }

  Future<void> pickDate() async {
    final pickedDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime.now(),
        lastDate: DateTime(DateTime.now().year + 3));

    if (pickedDate == null) {
      print(
          "CANCELED : Today : $initialDate ___________ PICKED DATE: $reservedDate ____now ${DateTime.now()}");
      return;
    }
    setState(() {
      reservedDate = pickedDate;
      isReservationDayPicked = true;
      firstTimeAskingForDateSelect == false;
      print("FirtsTimeCheck $firstTimeAskingForDateSelect");
    });
  }

  List<Material> buildLeftAlleySlots(
      int parkingSlotsTotal, double spaceBetweenSlots, bool isSelected) {
    int leftAlleySlotsTotal = parkingSlotsTotal ~/ 2;
    return List.generate(
        leftAlleySlotsTotal,
        (i) => Material(
              color: const Color.fromARGB(255, 63, 97, 95).withAlpha(80),
              child: InkWell(
                highlightColor: Colors.pink,
                onTap: () {
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
                    child: Center(child: Text('A$i')),
                  ),
                ),
              ),
            )).toList(); // replace * with your rupee or use Icon instead
  }

  List<Material> buildRightAlleySlots(
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

  Color checkMate(int i) {
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

  void refreshSlotColorState(dynamic selectedSlotColorFetched) {
    setState(() {
      finalSelectedColorSlot = selectedSlotColorFetched;
    });
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
}

//
class DashedSeparatedBordersPainterLTRB extends CustomPainter {
  bool left = false, top = false, right = false, bottom = false;
  DashedSeparatedBordersPainterLTRB(
      this.left, this.top, this.right, this.bottom);

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

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.grey
      ..strokeCap = StrokeCap.square
      ..strokeWidth = 1;

    _drawDashedLine(canvas, size, paint);
  }

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
}
