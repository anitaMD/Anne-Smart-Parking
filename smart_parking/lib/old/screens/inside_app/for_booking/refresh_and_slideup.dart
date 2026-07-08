// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:smart_parking/old/screens/inside_app/for_booking/for_sliding_up_panel.dart/stepper_booking_process.dart';

class RefreshAndSlideUp extends StatefulWidget {
  final Function() notifyParent;
  final PanelController controller;
  final Map<MarkerId, Marker> mappedMarkers;
  // final ScrollController panelScrollController;
  // final PanelController dragHandlePanelController;

  const RefreshAndSlideUp(
      {super.key,
      required this.notifyParent,
      required this.mappedMarkers,
      //required this.panelScrollController,
      // required this.dragHandlePanelController,
      required this.controller});

  @override
  RefreshAndSlideUpState createState() => RefreshAndSlideUpState();
}

class RefreshAndSlideUpState extends State<RefreshAndSlideUp> {
  /* test(){
   if(widget.dragHandlePanelController.isPanelShown){
     widget.panelScrollController.
   }
 } */
  final singleChildScrollController = ScrollController();

  Padding showFloatingButton() {
    return Padding(
      padding: const EdgeInsets.only(),
      child: FloatingActionButton(
        mini: true,
        onPressed: () {
          widget.controller.close();
        },
        backgroundColor: Colors.red,
        elevation: 6.0,
        heroTag: null,
        child: const Icon(
          Icons.arrow_drop_down_circle_outlined,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print(
        "MAPPED MARKERS RECEIVED FROM DASHBOARD_HOME: ${widget.mappedMarkers}");
    if (widget.mappedMarkers.entries.length == 1) widget.notifyParent();
    print("NUMBER OF MARKERS: ${widget.mappedMarkers.length}");
    //print("slide LENGTH: ${slides.length}");

    return Container();
  }

  GestureDetector buildDragHandle() => GestureDetector(
        onTap: togglePanel,
        child: Center(
            child: Container(
          width: 30,
          height: 8.5,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12.0),
          ),
        )),
      );

  void togglePanel() {
    widget.controller.isPanelOpen
        ? widget.controller.close()
        : widget.controller.open();
  }

  SingleChildScrollView myScrollNotifListener() {
    return SingleChildScrollView(
      controller: singleChildScrollController,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.3,
        child: const MapsBookingProcess(),
      ),
    );
  }
} 


/* import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_parking/old/services/firestore_service.dart';

class Markers {
  FirestoreParkingLocationService firestoreParkingLocationService =
      FirestoreParkingLocationService();

  var fetchedLatitude, fetchedLongitude;
  double aParkingLatitude = 0.0;
  double aParkingLongitude = 0.0;
  bool really = false;

  Map<String, dynamic> fetchedMappingResult = {};

  Map<MarkerId, Marker> markers = {};
  Map<String, List<double>> theList = {};

  initMarker(Map<String, dynamic> parkingData, parkingID) {
    final MarkerId parkingMarkerID = MarkerId(parkingID);
    getLatLngValues(parkingID);
    print("Look here RIGHT ${markers.values}");

    final Marker newMarker = Marker(
        markerId: parkingMarkerID,
        icon: BitmapDescriptor.defaultMarker,
        position: aParkingLatitude == 0.0
            ? LatLng(aParkingLatitude, aParkingLongitude)
            : LatLng(recupLat(parkingID), recupLng(parkingID)),
        infoWindow:
            (InfoWindow(title: "Fetched", snippet: parkingData['Name'])));
    /* setState(() { */
    markers.update(parkingMarkerID, (value) => newMarker);
    //markers[parkingMarkerID] = newMarker;
    print("JE SUIS Là $parkingMarkerID");
    // });
  }

  recupLat(String parkingID) {
    for (var parkingInfo in theList.entries) {
      if (parkingInfo.key == parkingID) {
        aParkingLatitude = parkingInfo.value.first;
        return aParkingLatitude;
      }
    }
  }

  recupLng(String parkingID) {
    for (var parkingInfo in theList.entries) {
      if (parkingInfo.key == parkingID) {
        aParkingLongitude = parkingInfo.value.last;
        return aParkingLongitude;
      }
    }
  }

  getLatLngValues(String parkingID) {
    List<double> bonbon = [];
    firestoreParkingLocationService
        .getParkingLocationCoordinates(parkingID)
        .then((value) {
      fetchedLatitude = value.latitude;
      aParkingLatitude = fetchedLatitude;
      print("OK $fetchedLatitude _________ $aParkingLatitude");
      fetchedLongitude = value.longitude;
      aParkingLongitude = fetchedLongitude;
      print("OK LONG $fetchedLongitude _________ $aParkingLongitude");
      bonbon.addAll({aParkingLatitude, aParkingLongitude});
      theList.addAll({parkingID: bonbon.toList()});
      print("THIS IS BONBON $bonbon");
    }).whenComplete(() {
      aParkingLatitude = fetchedLatitude;
      print("COMPLETE OK LONG $fetchedLongitude _________ $aParkingLongitude");
      aParkingLongitude = fetchedLongitude;
    });
    print(
        "COMPLETED NO OK LONG $fetchedLongitude _________ $aParkingLongitude");
  }

  Map<MarkerId, Marker> letsee() {
    firestoreParkingLocationService.getParkingInfoData().then((themap) {
      print("RESULT FROM LOC SERVICE : ${themap.keys}");
      fetchedMappingResult.addAll(themap);
      print("IT WORKED $fetchedMappingResult");
    }); // over here
    for (var parkingInfo in fetchedMappingResult.entries) {
      initMarker(parkingInfo.value, parkingInfo.key);
      print(
          "INFO VALUE : ${parkingInfo.value},________ INFO KEY : ${parkingInfo.key}");
    }
    print("markers from markers: $markers");
    return markers;
  }
}
 */