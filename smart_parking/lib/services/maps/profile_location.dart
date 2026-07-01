// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as prefix;
import 'package:location/location.dart';
import 'package:smart_parking/styling/styling.dart';

class LocationService extends StatefulWidget {
  const LocationService({super.key});

  @override
  LocationServiceState createState() => LocationServiceState();
}

class LocationServiceState extends State<LocationService> {
  String _address = '';
  Location location = Location();
  dynamic test;

  @override
  void initState() {
    super.initState();
    fetchLocation();
  }

  //
  Future<List<prefix.Placemark>> getAddress(double lat, double lang) async {
    final coordinates = prefix.placemarkFromCoordinates(lat, lang);
    return coordinates;
  }

  Future<void> fetchLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    LocationData currentPosition = await location.getLocation();

    location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        currentPosition = currentLocation;
        test = currentPosition;
        getAddress(currentPosition.latitude!.toDouble(),
                currentPosition.longitude!.toDouble())
            .then((value) {
          setState(() {
            _address =
                '${value.reversed.elementAt(1).street.toString()}, ${value.reversed.elementAt(1).locality.toString()}, ${value.reversed.elementAt(1).country.toString()}.';

/*             _address = value.reversed.elementAt(1).toString();
 */
          });
        });
      });
    });
  }

  //
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Image.asset(
          "assets/icons/location_pin.png",
          width: 20.0,
          color: Colors.white,
        ),
        if (test != null)
          Text(
            _address,
            style: whiteSubHeadingTextStyle,
          ),
      ],
    );
  }
}
