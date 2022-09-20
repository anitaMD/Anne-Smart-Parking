// ignore_for_file: avoid_print

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:smart_parking/services/firebase/firestore_service.dart';
import 'package:smart_parking/services/maps/places_autocomplete_service.dart';

class CurrentLocationNotifier with ChangeNotifier {
  Location location = Location();

  bool locationEnabledFromAlertBox = false; // DO NOT DELETE ANY OF THESE 3
  bool serviceEnabledAfterRejected = false;
  bool serviceRejectedFromTheStart = false;
  bool serviceEnabledAfterDisabledNotRejected = false;

  int userLocationAsked = 0;

  double currentUserLat = 0.0;
  double currentUserLng = 0.0;
  bool enabled = false;
  bool positionAvailable = false;
  geolocator.Position locationFetchedFromAlertBox = geolocator.Position(
    longitude: 137.42796133580664,
    latitude: -122.085749655962,
    timestamp: Timestamp.now().toDate(),
    accuracy: 16.805999755859375,
    altitude: 68.9000015258789,
    heading: 162.72528076171875,
    speed: 0.0626937747001648,
    speedAccuracy: 0.0,
  );
  String address = "";
  MyPlacesService myPlacesAutocompleteService = MyPlacesService();
  FirestoreParkingLocationService firestoreParkingLocationService =
      FirestoreParkingLocationService();
  Map<String, dynamic> fetchedMappingResult = {};
  Set<String> searchPlacesResultsList = {};

  /*  LocationData currentLocation = LocationData.fromMap({
    'latitude': 137.42796133580664,
    'longitude': -122.085749655962,
    'accuracy': 16.805999755859375,
    'altitude': 68.9000015258789,
    'speed': 0.0626937747001648,
    'speedAccuracy': 0.0,
    'heading': 162.72528076171875,
    'time': 1643310129929.0,
    'isMock': false,
    'verticalAccuracy': 1.1111111640930176,
    'headingAccuracy': 0.0,
    'elapsedRealtimeNanos': 120183901000000.0,
    'elapsedRealtimeUncertaintyNanos': 0.0,
    'satelliteNumber': 0,
    'provider': 'fused',
  }); */

  CurrentLocationNotifier() {
    getCurrentLocationOfUser().then((value) {
      print("MY POSITION : $value");
      positionAvailable = true;
      currentUserLat = value.latitude;
      currentUserLng = value.longitude;
    }).whenComplete(() {
      currentUserLat;
      currentUserLng;
      getSearchPlacesResult();
      notifyListeners();
    });

    print(
        "LATITUDE NOTF AFTER : $currentUserLat ______ LONGITUDE NOTIF AFTER : $currentUserLng");
    notifyListeners();
    //getSearchPlacesResult();

    //getMappedResultsFromFirestore();
    /*  getCurrentLocationOfUser()
        .then((value) => currentLocation = value)
        .whenComplete(() {
      currentLocation;
      //getSearchPlacesResult();
      notifyListeners();
    }); */
  }

  geolocator.Position getLocationFromAlert() => locationFetchedFromAlertBox;

  updateLocationFromAlertBox(geolocator.Position updatedLocationFromButton) {
    locationFetchedFromAlertBox = updatedLocationFromButton;
    locationEnabledFromAlertBox = true;
    print("LOCATION FROM ALERT BOX $locationFetchedFromAlertBox}");
    /* currentUserLat = updatedLocationFromButton.latitude;
    currentUserLng = updatedLocationFromButton.longitude;
 */
    positionAvailable = true;
    notifyListeners();
  }

  Future<bool> enableDeviceLocationService(
      geolocator.LocationPermission initialPermission) async {
    //
    bool permissionGranted = false;
    geolocator.LocationPermission permissionToReturn =
        await geolocator.Geolocator.requestPermission(); //DO NOT DELETE THIS
    if (permissionToReturn == geolocator.LocationPermission.denied) {
      permissionToReturn = await geolocator.Geolocator.requestPermission();
      if (permissionToReturn == geolocator.LocationPermission.denied) {
        print(Future.error('Location permissions are denied'));
        permissionGranted = false;
      }
    }

    if (permissionToReturn == geolocator.LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      print(Future.error(
          'Location permissions are permanently denied, we cannot request permissions.'));
      permissionGranted = false;
    }

    if (permissionToReturn == geolocator.LocationPermission.whileInUse ||
        permissionToReturn == geolocator.LocationPermission.always) {
      print(Future.value('Location services are enabled.'));
      positionAvailable == true;
      permissionGranted = true;
    }
    return permissionGranted;
  }

  Future<geolocator.Position> getCurrentLocationOfUser() async {
    print("getCurrentLocationOfUser function called successfully!");
    bool serviceEnabled;
    geolocator.LocationPermission permission =
        await geolocator.Geolocator.checkPermission();
    // Test if location services are enabled.
    serviceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
    bool serviceEnabledAtAppStart = serviceEnabled;
    if (serviceEnabledAtAppStart == true) {
      print(
          "LOCATION SERVICE ENABLED FROM THE START. FETCHING CURRENT LOCATION...");
      positionAvailable = true;
      notifyListeners();
    } else {
      print("LOCATION SERVICE NOT ENABLED FROM THE START. SENDING REQUEST..");
    }
    geolocator.Geolocator.getServiceStatusStream()
        .listen((geolocator.ServiceStatus status) async {
      print("LOCATION SERVICE STATUS : $status");
      if (status == geolocator.ServiceStatus.disabled ||
          serviceEnabled == false) {
        positionAvailable == false;
        enableDeviceLocationService(permission).then((value) {
          if (value == true) {
            positionAvailable == true;
            serviceEnabled = value;
            serviceEnabledAfterRejected =
                value; //THINK ABOUT A COUNT VARIABLE TO CHECK IF IT WAS HE FIRST TRY
            notifyListeners();

            print(
                "PERMISSION GRANTED!"); //permission is immediately granted after reactivating the location service because it was granted from the start
          } else if (value == false) {
            //   serviceEnabled = false;
            print("PERMISSION REJECTED!");
          }
        });
      } else if (status == geolocator.ServiceStatus.enabled) {
        await geolocator.Geolocator.isLocationServiceEnabled().then((value) {
          value == true
              ? print("LOCATION SERVICE RE-ENABLED!")
              : print("LOCATION SERVICE DISABLED $serviceEnabled");
        });
      }
/*       serviceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
      print("DISBALED? $serviceEnabled"); */

      //
    });

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device. */
    geolocator.Position dummyPosition = geolocator.Position(
      longitude: 137.42796133580664,
      latitude: -122.085749655962,
      timestamp: Timestamp.now().toDate(),
      accuracy: 16.805999755859375,
      altitude: 68.9000015258789,
      heading: 162.72528076171875,
      speed: 0.0626937747001648,
      speedAccuracy: 0.0,
    );
    //

    try {
      await geolocator.Geolocator.getCurrentPosition(
              desiredAccuracy: geolocator.LocationAccuracy.high)
          .then((value) => {dummyPosition = value});
    } catch (e) {
      bool testEnabled;
      testEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
      if (!testEnabled) {
        serviceRejectedFromTheStart = true;
        userLocationAsked++;
        notifyListeners();

        // Location services are not enabled don't continue
        // accessing the position and request users of the
        // App to enable the location services.
        return Future.error('Location services are disabled.');
      }
    }

    return dummyPosition;
  }

  getMappedResultsFromFirestore() {
    firestoreParkingLocationService.getParkingInfoData().then((themap) {
      print("RESULT FROM FirestoreParkingLocationService SERVICE : $themap");
      fetchedMappingResult.addAll(themap);
    });
  }

  getSearchPlacesResult() {
    Map<String, dynamic> fetchedPlacesMap =
        myPlacesAutocompleteService.showPlacesList(fetchedMappingResult);
    print("MAMAN OK $fetchedPlacesMap");
    // ignore: unused_local_variable
    for (var placeInfo in fetchedPlacesMap.values) {
      //searchPlacesResultsList.add(placeInfo); this is the problem
      print("VOILA");
    }
    print("DEJA VU: $searchPlacesResultsList");
  }

  Future<bool> enableLocationService() async {
    print("ASKED FIRST");
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    try {
      serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {}
      }
      permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {}
      } else if (permissionGranted == PermissionStatus.granted) {
        enabled = true;
      }
    } catch (e) {
      print("THERE IS AN ERROR FROM curreLOCATION");
    }
    print("OUI $enabled");
    return enabled;
  }

  Future<List<geocoding.Placemark>> getAddress(double lat, double lang) async {
    final coordinates = geocoding.placemarkFromCoordinates(lat, lang);
    return coordinates;
  }
  //
}

/* // ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as prefix;
import 'package:smart_parking/services/firebase/firestore_service.dart';
import 'package:smart_parking/services/maps/places_autocomplete_service.dart';

class CurrentLocationNotifier with ChangeNotifier {
  Location location = Location();
  String address = "";
  MyPlacesService myPlacesAutocompleteService = MyPlacesService();
  FirestoreParkingLocationService firestoreParkingLocationService =
      FirestoreParkingLocationService();
  Map<String, dynamic> fetchedMappingResult = {};
  Set<String> searchPlacesResultsList = {};

  LocationData currentLocation = LocationData.fromMap({
    'latitude': 137.42796133580664,
    'longitude': -122.085749655962,
    'accuracy': 16.805999755859375,
    'altitude': 68.9000015258789,
    'speed': 0.0626937747001648,
    'speedAccuracy': 0.0,
    'heading': 162.72528076171875,
    'time': 1643310129929.0,
    'isMock': false,
    'verticalAccuracy': 1.1111111640930176,
    'headingAccuracy': 0.0,
    'elapsedRealtimeNanos': 120183901000000.0,
    'elapsedRealtimeUncertaintyNanos': 0.0,
    'satelliteNumber': 0,
    'provider': 'fused',
  });

  CurrentLocationNotifier() {
    //enableLocationService();
    //getMappedResultsFromFirestore();
    getCurrentLocationOfUser()
        .then((value) => currentLocation = value)
        .whenComplete(() {
      currentLocation;
      //getSearchPlacesResult();
      notifyListeners();
    });
  }

  getMappedResultsFromFirestore() {
    firestoreParkingLocationService.getParkingInfoData().then((themap) {
      print("RESULT FROM FirestoreParkingLocationService SERVICE : $themap");
      fetchedMappingResult.addAll(themap);
    });
  }

  getSearchPlacesResult() {
    Map<String, dynamic> fetchedPlacesMap =
        myPlacesAutocompleteService.showPlacesList(fetchedMappingResult);
    print("MAMAN OK $fetchedPlacesMap");
    for (var placeInfo in fetchedPlacesMap.values) {
      //searchPlacesResultsList.add(placeInfo); this is the problem
      print("VOILA");
    }
    print("DEJA VU: $searchPlacesResultsList");
  }

  Future<LocationData> getCurrentLocationOfUser() async {
    //enableLocationService();

    LocationData currentLocation =
        await location.getLocation().whenComplete(() => print("also asked"));
    location.onLocationChanged.listen((LocationData updatedCurrentLocation) {
      currentLocation = updatedCurrentLocation;
      getAddress(currentLocation.latitude!.toDouble(),
              currentLocation.longitude!.toDouble())
          .then((value) {
        address =
            '${value.reversed.elementAt(1).street.toString()}, ${value.reversed.elementAt(1).locality.toString()}, ${value.reversed.elementAt(1).country.toString()}.';
      });
    });
    return currentLocation;
  }

  enableLocationService() async {
    print("ASKED FIRST");
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    try {
      _serviceEnabled = await location.serviceEnabled();
      if (!_serviceEnabled) {
        _serviceEnabled = await location.requestService();
        if (!_serviceEnabled) {}
      }
      _permissionGranted = await location.hasPermission();
      if (_permissionGranted == PermissionStatus.denied) {
        _permissionGranted = await location.requestPermission();
        if (_permissionGranted != PermissionStatus.granted) {}
      }
    } catch (e) {
      print("THERE IS AN ERROR FROM curreLOCATION");
    }
  }

  Future<List<prefix.Placemark>> getAddress(double lat, double lang) async {
    final coordinates = prefix.placemarkFromCoordinates(lat, lang);
    return coordinates;
  }
  //
}
 */
