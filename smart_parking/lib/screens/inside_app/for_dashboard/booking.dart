// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:smart_parking/notifiers/location_notifier.dart';
import 'package:smart_parking/screens/inside_app/for_booking/location_alert_box.dart';
import 'package:smart_parking/screens/inside_app/for_booking/for_sliding_up_panel.dart/slider_inf_loaded.dart';
import 'package:smart_parking/screens/inside_app/for_booking/refresh_and_slideup.dart';
import 'package:smart_parking/screens/inside_app/for_booking/slots_map/no_alert.dart';
import 'package:smart_parking/services/firebase/firestore_service.dart';

class BookingPage extends StatefulWidget {
  //final String mapStyle;
  const BookingPage({Key? key}) : super(key: key);
  @override
  BookingPageState createState() => BookingPageState();
}

class BookingPageState extends State<BookingPage> {
  @override
  void initState() {
    //call SUBCOLLECTION FUNCTION
    FocusNode();
    BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(devicePixelRatio: 5.5),
            'assets/images/parking_marker_icon.png')
        .then((onValue) {
      setState(() {
        smartParkingIconMarker = onValue;
      });
    });
    rootBundle.loadString('assets/mapstyle/mapstyle.txt').then((string) {
      _mapStyle = string;
    });
    searchBarFocus = FocusNode();
    super.initState();
    firestoreParkingLocationService.getParkingInfoData().then((themap) {
      print("RESULT FROM FirestoreParkingLocationService SERVICE : $themap");
      fetchedMappingResult.addAll(themap);
      /* displaySearchResult.addAll(
          myPlacesAutocompleteService.showPlacesList(fetchedMappingResult)); */
      //print("FETCHED MAPPING RESULT CHECK :  $fetchedMappingResult");
    });

    //getCoordinates(); COMMENT TO KEEP FOR FUTURE PURPOSE
  } //END OF INITISTATE

  // VARIABLES------------------------
  FocusNode mapFocus = FocusNode();
  bool isParkingLocationIconNotClicked = true;
  final drangHandlePanelController = PanelController();
  late String _mapStyle;
  MapType _currentMapType = MapType.normal;
  Map<String, Set<String>> displaySearchResult = {};
  late FocusNode searchBarFocus;
  FirestoreParkingLocationService firestoreParkingLocationService =
      FirestoreParkingLocationService();
  // ignore: prefer_typing_uninitialized_variables
  var fetchedParkingLat, fetchedParkingLng;
  double aParkingLatitude = 0.0;
  double aParkingLongitude = 0.0;
  //
  String sentParkingIDtoSlotsBooking = '';
  BitmapDescriptor smartParkingIconMarker = BitmapDescriptor.defaultMarker;
  Map<String, dynamic> fetchedMappingResult =
      {}; //contains entries from firestore "locations" document like {{key,value}, {key,value},...} with key=document_id and value={name, geopoint{}, streetadd...} and each entry in value is a map of elements that can be accessed through value.key or value.value
  Map<String, List<Placemark>> mappedParkingPlacemarks = {};
  Map<MarkerId, Marker> myMapMarkers = {};
  Map<String, Set<double>> mappedParkingCoordinates = {};

  // VARIABLES------------------------ END-------
  refreshParkingIconClickState(bool result) {
    setState(() {
      isParkingLocationIconNotClicked = result;
    });
  }

  initMarker(Map<String, dynamic> parkingData, parkingID) {
    final MarkerId parkingMarkerID = MarkerId(parkingID);
    getLatLngValues(parkingID);
    print("MARKERS RESULT: ${myMapMarkers.values}");
    //recupParkingLocationData(parkingID);
    final Marker newMarker = Marker(
        onTap: () {
          refreshParkingIconClickState(false);
          getSelectedParkingIDThroughMapOnTap(
              parkingID); //SEND THIS ID TO SLOTSBOOKINGMAP STREAM BUILDER
          //LINK THIS TAP TO WHAT TO DISPLAY WITH THE FLOATING ACTION BUTTON, make the floating action SELECTABLE to check the parking info and layout
        },
        markerId: parkingMarkerID,
        icon: smartParkingIconMarker,
        position: aParkingLatitude == 0.0
            ? LatLng(aParkingLatitude, aParkingLongitude)
            : LatLng(recupLat(parkingID), recupLng(parkingID)),
        infoWindow: (InfoWindow(
            title: parkingData['Name'],
            snippet:
                "${parkingData['StreetAddress']}, ${parkingData['City']}, ${parkingData['CountryCode']}")));
    setState(() {
      myMapMarkers[parkingMarkerID] = newMarker;
      print("PARKING MARKER ID FROM INITIMARKER: $parkingMarkerID");
    });
  }

  recupLat(String parkingID) {
    for (var parkingInfo in mappedParkingCoordinates.entries) {
      if (parkingInfo.key == parkingID) {
        aParkingLatitude = parkingInfo.value.first;
        return aParkingLatitude;
      }
    }
  }

  recupLng(String parkingID) {
    for (var parkingInfo in mappedParkingCoordinates.entries) {
      if (parkingInfo.key == parkingID) {
        aParkingLongitude = parkingInfo.value.last;
        return aParkingLongitude;
      }
    }
  }

  getLatLngValues(String parkingID) {
    Set<double> parkingCoordinatesList = {};
    firestoreParkingLocationService
        .getParkingLocationCoordinates(parkingID)
        .then((value) {
      fetchedParkingLat = value.latitude;
      aParkingLatitude = fetchedParkingLat;
      //print("OK $fetchedLatitude _________ $aParkingLatitude");
      fetchedParkingLng = value.longitude;
      aParkingLongitude = fetchedParkingLng;
      //print("OK LONG $fetchedLongitude _________ $aParkingLongitude");
      parkingCoordinatesList.addAll({aParkingLatitude, aParkingLongitude});
      mappedParkingCoordinates
          .addAll({parkingID: parkingCoordinatesList.toSet()});
      print("THIS IS EACH PARKING COORDINATES: $parkingCoordinatesList");
    }).whenComplete(() {
      aParkingLatitude = fetchedParkingLat;
      print(
          "COMPLETE PARKING COORDINATES: FetchedLng $fetchedParkingLng _________ aParkingLNG $aParkingLongitude");
      aParkingLongitude = fetchedParkingLng;
    });

    if (aParkingLatitude == 0) {
      print(
          "NO COMPLETE PARKING COORDINATES: FetchedLng $fetchedParkingLng _________ aParkingLNG $aParkingLongitude");
    }
  }

/*   @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    FocusNode().dispose();
    searchBarFocus.dispose();
    super.dispose();
  } */

  final Completer<GoogleMapController> _controller = Completer();
  mapInitialize() {
    for (var parkingInfo in fetchedMappingResult.entries) {
      initMarker(parkingInfo.value, parkingInfo.key);
      print(
          "INFO VALUE : ${parkingInfo.value},________ INFO KEY : ${parkingInfo.key}");
    }
  }

  var mapCreated = false;
  isMapCreated() => setState(() {
        mapCreated = true;
      }); //print("$mapCreated IS FINALLY TRUE");

  refresh() => Future.delayed(const Duration(seconds: 1), () {
        setState(() {});
      });

  displayMyMap(CameraPosition currentLocationCameraPosition) {
    return GoogleMap(
      // ignore: prefer_collection_literals
      onTap: (latLng) {
        mapFocus.requestFocus();
        refreshParkingIconClickState(true);
        print(
            "isParkingLocationNotClicked : $isParkingLocationIconNotClicked ");
      },
      // ignore: prefer_collection_literals
      gestureRecognizers: Set()
        ..add(Factory<PanGestureRecognizer>(() => PanGestureRecognizer()))
        ..add(Factory<VerticalDragGestureRecognizer>(
            () => VerticalDragGestureRecognizer())),
      mapType: _currentMapType,
      markers: Set<Marker>.of(myMapMarkers.values),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      buildingsEnabled: true,

      initialCameraPosition: currentLocationCameraPosition, //_kGooglePlex,
      onMapCreated: (GoogleMapController controller) {
        try {
          _controller.complete(controller);
          controller.setMapStyle(_mapStyle);
          isMapCreated();
          // ignore: empty_catches
        } catch (e) {}
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double panelHeightClosed = MediaQuery.of(context).size.height * 0.1;
    double panelHeightOpened = MediaQuery.of(context).size.height * 0.5;
    //
    final currentLocationProvider =
        Provider.of<CurrentLocationNotifier>(context);

    if (mapCreated == true) mapInitialize(); //MAP INITIALIZATION----

    displayLocationEnablerDialBox(
        bool rejectedFromTheStart, bool enabledAfterRejected) {
      if (rejectedFromTheStart == true && enabledAfterRejected == false) {
        Future.delayed(const Duration(seconds: 10)).then((value) => {
              showDialog(
                barrierColor: Colors.black26,
                barrierDismissible: false,
                context: context,
                builder: (context) {
                  return const ActivateLocationAlertBox(
                    title: "Device Location Needed",
                    description:
                        "To display the map and available smart parkings, we need to access your location.",
                  );
                },
              )
            });
      }
    }

    displayLocationEnablerDialBox(
        currentLocationProvider.serviceRejectedFromTheStart,
        currentLocationProvider.serviceEnabledAfterRejected);
    print(
        " MAPTYPEEUU $_currentMapType"); //TERRAIN IS THE ONE WITH COLORS AND LESS MARKERS FROM OTHER PACES

    print(
        "POSITION AVAILABLE NOW?  ${currentLocationProvider.positionAvailable}");
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 246, 244, 248),
      //backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: FutureBuilder(
            future: firestoreParkingLocationService.getParkingInfoData(),
            builder: (BuildContext context1, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                //

                if (currentLocationProvider.positionAvailable == false) {
                  return SlidingUpPanel(
                    panelBuilder: (sc) => Testons(controller: sc),
                    body: const Padding(
                      padding: EdgeInsets.only(bottom: 200.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.orange,
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ),
                  );
                } //
                else if (currentLocationProvider.currentUserLat != 0.0 ||
                    currentLocationProvider.serviceEnabledAfterRejected ==
                        true) {
                  print("VOILA ${currentLocationProvider.currentUserLat}");
                  Marker currentLocationMarker = Marker(
                    markerId: const MarkerId("Your Location"),
                    position: currentLocationProvider
                                .locationEnabledFromAlertBox ==
                            true
                        ? LatLng(
                            currentLocationProvider
                                .locationFetchedFromAlertBox.latitude,
                            currentLocationProvider
                                .locationFetchedFromAlertBox.longitude)
                        : LatLng(
                            currentLocationProvider.currentUserLat.toDouble(),
                            currentLocationProvider.currentUserLng.toDouble()),
                    icon: BitmapDescriptor.defaultMarker,
                    infoWindow: InfoWindow(
                        //EDIT THE JSON.KEYS.FIRST BECAUSE ITS NOT SHOWING ANYTHING
                        title: "Current Position",
                        snippet: currentLocationProvider
                                    .locationEnabledFromAlertBox ==
                                true
                            ? currentLocationProvider
                                .locationFetchedFromAlertBox
                                .toJson()
                                .keys
                                .first
                            : currentLocationProvider.address.toString()),
                  );
                  print(
                      "THIS IS THE CURRENT LOCATION MARKER : $currentLocationMarker");
                  if (currentLocationProvider.serviceEnabledAfterRejected ==
                          true &&
                      currentLocationProvider.userLocationAsked != 0) {
                    print(
                        "ON VERIFIE ${currentLocationProvider.locationFetchedFromAlertBox.latitude}");
                  }
                  myMapMarkers[currentLocationMarker.markerId] =
                      currentLocationMarker;
                  CameraPosition currentUserPositionCamera = CameraPosition(
                      target: currentLocationProvider
                                      .serviceEnabledAfterRejected ==
                                  true &&
                              currentLocationProvider.userLocationAsked != 0
                          ? LatLng(
                              currentLocationProvider
                                  .locationFetchedFromAlertBox.latitude,
                              currentLocationProvider
                                  .locationFetchedFromAlertBox.longitude)
                          : LatLng(
                              currentLocationProvider.currentUserLat.toDouble(),
                              currentLocationProvider.currentUserLng
                                  .toDouble()),
                      zoom: 11,
                      bearing: 10); //_kGooglePlex,

                  return SlidingUpPanel(
                    collapsed: Container(
                      decoration: const BoxDecoration(
                        color: Colors.blueGrey,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: const Center(
                          child: Text(
                        "BOOK A CAR NOW",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'OpenSans'),
                      )),
                    ),

                    controller: drangHandlePanelController,
                    minHeight: panelHeightClosed,
                    maxHeight: panelHeightOpened,
                    parallaxEnabled: true,
                    parallaxOffset: .5,
                    panel: RefreshAndSlideUp(
                        notifyParent: refresh,
                        mappedMarkers: myMapMarkers,
                        controller: drangHandlePanelController),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    /*   panelBuilder: (panelScrollController) => RefreshAndSlideUp(
                      notifyParent: refresh,
                      mappedMarkers: myMapMarkers,
                      panelScrollController: panelScrollController,
                      dragHandlePanelController: drangHandlePanelController,
                    ), */ //MAKE THE BLACK CONTAINER The draggable tiroir hand icon
                    body: displayMyMap(currentUserPositionCamera),

                    /* SomeMarkers(
                            notifyParent: refresh, mappedMarkers: myMapMarkers), */
                  );
                } else {
                  return const CircularProgressIndicator(
                      color: Color.fromARGB(255, 238, 244, 54));
                }
              } else {
                return Container();
              }
            }),
      ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            mini: true,
            onPressed: _toggleNavBarForVisibleMap,
            backgroundColor: Colors.white,
            elevation: 6.0,
            heroTag: null,
            child: const Icon(
              Icons.info_outline_rounded,
              color: Colors.red,
            ),
          ),

/* floating buttons aligned in a row horizontally
. info button (will display the parking's info, nbr places total, dispo, rented, prix de la place)
 .eye button to display the parking layout (with the lock icon on reserved places (but the car isn't currently parked) and colors for normal and handicapped people's places, and car icons on places that are currently occupied and free places at the instant.
____
now on the blank space left, the person will see and can choose :
. The car for xhich she will rent
. The reservation time (day and hour, duration etc)
. how to pay
. A BOOK NOW button to validate the reservation */
          Visibility(
            visible: isParkingLocationIconNotClicked == true ? false : true,
            child: FloatingActionButton(
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingThroughSlotsMapNoAlertDialog(
                        receivedID: sentParkingIDtoSlotsBooking,
                        mappedParkingsGeneralInfo: fetchedMappingResult,
                        slotBooked: false),
                  ),
                );

                /* var obtenu = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                          content: BookingThroughSlotsMap(
                              receivedID: sentParkingIDtoSlotsBooking,
                              mappedParkingsGeneralInfo: fetchedMappingResult,
                              slotBooked: false),
                          contentPadding: EdgeInsets.zero,
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('OK'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('BOOK'),
                            ),
                          ],
                        ));
                print("OBTENU $obtenu"); */
              },
              mini: true,
              backgroundColor: Colors.black,
              elevation: 6.0,
              heroTag: null,
              child: const Icon(
                Icons.visibility,
                color: Colors.green,
              ),
            ),
          ),
          FloatingActionButton(
            mini: true,
            onPressed: _toggleNavBarForVisibleMap,
            elevation: 6.0,
            heroTag: null,
            backgroundColor: Colors.white,
            child: const Icon(
              Icons.visibility,
              color: Colors.red,
            ),
          ),
        ],
      ),

      /* FloatingActionButton(
        backgroundColor: Colors.pink,
        child: const Icon(Icons.drag_indicator),
        onPressed: _toggleNavBarForVisibleMap,
        heroTag: null,
        elevation: 6.0,
      ), */
    );
    /* return Container(
        color: Colors.white,
        child: Column(children: const [
          Text(
              'BOOKING where you can show the user the nearby parkings [https://www.google.com/search?q=car+booking+app+flutter&tbm=isch&ved=2ahUKEwi3oLi93Iv1AhUIlBoKHbV0BGEQ2-cCegQIABAA&oq=car+booking+app+flutter&gs_lcp=CgNpbWcQAzoHCCMQ7wMQJzoGCAAQCBAeUPAHWL8RYPMUaAFwAHgAgAGIAogBjgeSAQUwLjUuMZgBAKABAaoBC2d3cy13aXotaW1nwAEB&sclient=img&ei=ksDNYbePKYioarXpkYgG&bih=714&biw=1280&client=firefox-b-d#imgrc=ddyerWq6kmcSrM] and once he clicks on one, he gets the occupation info (numbers only) of the parking and then if he decides to proceed to booking with that one, he is redirected to the page showing the parking map with: cars representing actually parked car, lock icon representing already booked and nothing with green or blue dot for available for noaml people and handicapped '),
        ])); */
  }

  /* void _toggleMapType() {
    setState(() {
      _currentMapType = (_currentMapType == MapType.normal)
          ? MapType.terrain
          : MapType.normal;
    });
  } */

  void _toggleNavBarForVisibleMap() {
    setState(() {
      _currentMapType = (_currentMapType == MapType.normal)
          ? MapType.terrain
          : MapType.normal;
    });
  }

  void getSelectedParkingIDThroughMapOnTap(parkingID) {
    setState(() {
      sentParkingIDtoSlotsBooking = parkingID;
    });
  }

  /* 'BOOKING where you can show the user the nearby parkings [https://www.google.com/search?q=car+booking+app+flutter&tbm=isch&ved=2ahUKEwi3oLi93Iv1AhUIlBoKHbV0BGEQ2-cCegQIABAA&oq=car+booking+app+flutter&gs_lcp=CgNpbWcQAzoHCCMQ7wMQJzoGCAAQCBAeUPAHWL8RYPMUaAFwAHgAgAGIAogBjgeSAQUwLjUuMZgBAKABAaoBC2d3cy13aXotaW1nwAEB&sclient=img&ei=ksDNYbePKYioarXpkYgG&bih=714&biw=1280&client=firefox-b-d#imgrc=ddyerWq6kmcSrM] and once he clicks on one, he gets the occupation info (numbers only) of the parking and then if he decides to proceed to booking with that one, he is redirected to the page showing the parking map with: cars representing actually parked car, lock icon representing already booked and nothing with green or blue dot for available for noaml people and handicapped '), */
}
