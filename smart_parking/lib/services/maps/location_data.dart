// ignore_for_file: avoid_print

import 'package:geocoding/geocoding.dart' as prefix;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class UserCurrentLocationData {
  /* var currentUserLatitude = 0.0;
  var currentUserLongitude = 0.0; */

  String address = '';
  Location location = Location();
  // late LocationData test;

  Future<List<prefix.Placemark>> getAddress(double lat, double lang) async {
    final coordinates = prefix.placemarkFromCoordinates(lat, lang);
    return coordinates;
  }

  Future<void> enableLocationService() async {
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
      }
    } catch (e) {
      print("THERE IS AN ERROR FROM curreLOCATION");
    }
  }

  Future<Marker> fetchLocation() async {
    enableLocationService();
    LocationData currentPosition = await location.getLocation();
    print("THIS IS CURRENT LAT : ${currentPosition.latitude!.toDouble()}");

    Marker currentPositionMarker = Marker(
      markerId: const MarkerId("Your Location"),
      position: LatLng(currentPosition.latitude!.toDouble(),
          currentPosition.longitude!.toDouble()),
      icon: BitmapDescriptor.defaultMarker,
      infoWindow: InfoWindow(title: "Your Position", snippet: address),
    );
    print("mine : $currentPositionMarker");
    return currentPositionMarker;
  }

  //
  Future<double> fetchCurrentLatitude() async {
    enableLocationService();
    LocationData currentPosition = await location.getLocation();
    print("THIS IS CURRENT LAT : ${currentPosition.latitude!.toDouble()}");
    return currentPosition.latitude!.toDouble();
  } //

  Future<double> fetchCurrentLongitude() async {
    enableLocationService();
    LocationData currentPosition = await location.getLocation();
    print(
        "THIS IS CURRENT LONG HERE : ${currentPosition.longitude!.toDouble()}");
    return currentPosition.longitude!.toDouble();
  }
}

  /*  THIS WOULD WORK IF THE COORDINATES WERE REGISTERED IN MAPS
 
 List ok = [];

  Future<List<prefix.Placemark>> getAddress(double lat, double lang) async {
    /* final coordinates = prefix.placemarkFromCoordinates(lat, lang);
    print("PM : $coordinates");
    return coordinates; */
    prefix
        .placemarkFromCoordinates(lat, lang)
        .whenComplete(() => print("FINI"))
        .then((value) {
      ok.add(value);
      print("OK reversed: ${ok.reversed}");
    });
    final coordinates = prefix.placemarkFromCoordinates(lat, lang);
    print("PM : $coordinates");
    return coordinates;
  } */

