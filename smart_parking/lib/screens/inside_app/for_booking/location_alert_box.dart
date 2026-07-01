// ignore_for_file: sized_box_for_whitespace

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:provider/provider.dart';
import 'package:smart_parking/notifiers/location_notifier.dart';

class ActivateLocationAlertBox extends StatefulWidget {
  const ActivateLocationAlertBox({
    super.key,
    required this.title,
    required this.description,
  });
  final String title, description;

  @override
  State<ActivateLocationAlertBox> createState() =>
      _ActivateLocationAlertBoxState();
}

class _ActivateLocationAlertBoxState extends State<ActivateLocationAlertBox> {
  geolocator.Position dummyPosition = geolocator.Position(
    longitude: 137.42796133580664,
    latitude: -122.085749655962,
    timestamp: Timestamp.now().toDate(),
    accuracy: 16.805999755859375,
    altitude: 68.9000015258789,
    altitudeAccuracy: 0.0,
    heading: 162.72528076171875,
    headingAccuracy: 0.0,
    speed: 0.0626937747001648,
    speedAccuracy: 0.0,
  );
  bool userLocationEnabled = false;

  //
  @override
  Widget build(BuildContext context) {
    final currentLocationProvider =
        Provider.of<CurrentLocationNotifier>(context);
    //
    /*   Future.delayed(
      const Duration(seconds: 10),
    ); */
    return AlertDialog(
      insetPadding: const EdgeInsets.all(40.0),
      elevation: 0,
      backgroundColor: const Color(0xffffffff),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 15),
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              widget.description,
              maxLines: 3,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(
            height: 1,
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            height: 50,
            child: InkWell(
              highlightColor: Colors.grey[200],
              onTap: () async {
                final nav = Navigator.of(context);

                try {
                  await geolocator.Geolocator.getCurrentPosition(
                      locationSettings: const geolocator.LocationSettings(
                    accuracy: geolocator.LocationAccuracy.high,
                  )).then((value) => {
                        dummyPosition = value,
                        currentLocationProvider
                            .updateLocationFromAlertBox(dummyPosition),
                        nav.pop(),
                        nav.pop(),
                        nav.pop(true),
                        if (context.mounted)
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text("Location successfully activated!"),
                          )),
                      });
                } catch (e) {
                  bool testEnabled;
                  testEnabled =
                      await geolocator.Geolocator.isLocationServiceEnabled();
                  if (!testEnabled) {
                    // Location services are not enabled don't continue
                    // accessing the position and request users of the
                    // App to enable the location services.
                  }
                }
              },
              child: Center(
                child: InkWell(
                  onTap: () {
                    //Navigator.of(context).popUntil((route) => false);
                    //Navigator.pop(context, true);
                  },
                  child: Text(
                    "Turn on",
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Divider(
            height: 1,
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            height: 50,
            child: InkWell(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(15.0),
                bottomRight: Radius.circular(15.0),
              ),
              highlightColor: Colors.grey[200],
              onTap: () {
                Navigator.pop(context, false);
                Navigator.pop(context, false);
                Navigator.pop(context, false);
              },
              child: const Center(
                child: Text(
                  "Cancel",
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
