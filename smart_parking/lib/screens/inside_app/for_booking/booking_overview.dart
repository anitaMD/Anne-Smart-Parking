import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:time_range_picker/time_range_picker.dart';
//import 'package:smart_parking/paydunya_java_latest/com/paydunya/neptune/';

//import 'package:package:smart_parking/paydunya_java_latest/com/paydunya/neptune';

class BookingOverviewFinal extends StatefulWidget {
  final Map<String, dynamic> bookerFirstPageInfoFetched, bookerSecondPageInfoFetched;
  const BookingOverviewFinal(
      {Key? key, required this.bookerFirstPageInfoFetched, required this.bookerSecondPageInfoFetched})
      : super(key: key);

  @override
  State<BookingOverviewFinal> createState() => _BookingOverviewFinalState();
}

class _BookingOverviewFinalState extends State<BookingOverviewFinal> {
  ScrollController bookingDetailsGridVController = ScrollController();
  Set<Items> allBookingDetailItems = {};
  String currentCarPath = '';
  @override
  void initState() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    getDirectory().then((value) => print(" LALILA $value"));

    //print("LALILA ${");
    const TextStyle titleTextStyle = TextStyle(
      color: Colors.black,
      fontFamily: 'OpenSans',
      fontSize: 20,
      fontWeight: FontWeight.w800,
    );
    const TextStyle subtitleTextStyle =
        TextStyle(color: Colors.white, fontFamily: 'OpenSans', fontSize: 15, fontWeight: FontWeight.w900);
    var selectedDay = widget.bookerFirstPageInfoFetched['Selected Day'] as DateTime;
    var selectedTimeInterval = widget.bookerSecondPageInfoFetched['Selected Time Interval'] as TimeRange;
    var duration = (selectedTimeInterval.endTime.hour * 60 + selectedTimeInterval.endTime.minute) -
        (selectedTimeInterval.startTime.hour * 60 + selectedTimeInterval.startTime.minute);

    String durationToString(int minutes) {
      var d = Duration(minutes: minutes);
      List<String> parts = d.toString().split(':');
      return '${parts[0].padLeft(2, '0')}h ${parts[1].padLeft(2, '0')}mn';
    }

    final Items item1 = Items(
      id: 0,
      title: "Booked Day",
      subtitle: DateFormat('EEEE,\nd/M/y').format(selectedDay),
    );
    final Items item2 = Items(
      id: 1,
      title: "Booked Spot",
      subtitle: widget.bookerSecondPageInfoFetched['Selected Parking Spot'],
    );
    final Items item3 = Items(
      id: 2,
      title: "Fee / 30mns",
      subtitle: widget.bookerFirstPageInfoFetched['Selected Parking Fee / 30mns'] + ' FCFA',
    );
    final Items item4 = Items(
      id: 3,
      title: "Booking Start",
      subtitle: selectedTimeInterval.startTime.format(context),
    );
    final Items item5 = Items(
      id: 4,
      title: "Booking End",
      subtitle: selectedTimeInterval.endTime.format(context),
    );
    final Items item6 = Items(
      id: 5,
      title: "Duration",
      subtitle: durationToString(duration),
    );

    allBookingDetailItems.length < 6 ? allBookingDetailItems.addAll({item1, item2, item3, item4, item5, item6}) : null;
    var durationMinutePart = int.parse(durationToString(duration).split(' ').last.substring(0, 2));
    debugPrint(
        "THIS IS WHAT YOU GET: ${widget.bookerFirstPageInfoFetched} \t ${widget.bookerSecondPageInfoFetched} _ ${widget.bookerFirstPageInfoFetched['Selected Vehicule Info']['Specs']['Brand']} __________ $durationMinutePart");
    widget.bookerFirstPageInfoFetched['Selected Vehicule Info']['Specs']['Brand'];

    return SingleChildScrollView(
      child: Column(
        children: [
          /*  const SizedBox(
            height: 10,
          ), */
          const FittedBox(
            child: Text(
              "BOOKING OVERVIEW",
              style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 40),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                child: Text(
                  widget.bookerFirstPageInfoFetched['Selected Vehicule Info']['Specs']['Brand'],
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
              FittedBox(
                child: Text(
                  widget.bookerFirstPageInfoFetched['Selected Vehicule Info']['Specs']['Model Detail'],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white54),
                ),
              ),
              const SizedBox(
                height: 19,
              ),
              const Image(image: AssetImage('assets/images/carRep/ford.png')),
              const SizedBox(
                height: 27,
              ),
              Row(
                children: [
                  const Icon(Icons.location_pin),
                  FittedBox(
                    child: Text(widget.bookerFirstPageInfoFetched['Selected Parking Name'],
                        style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 10, top: 5),
                child: FittedBox(
                  child: Text("Booking Details",
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900, color: Color.fromARGB(169, 255, 255, 255))),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 280,
            child: Column(
              children: [
                Expanded(
                  child: GridView.builder(
                      controller: bookingDetailsGridVController,
                      shrinkWrap: true,
                      itemCount: allBookingDetailItems.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          childAspectRatio: 1,
                          crossAxisSpacing: MediaQuery.of(context).size.width < 373.33 ? 9 : 6,
                          mainAxisSpacing: MediaQuery.of(context).size.width < 373.33 ? 9 : 6,
                          crossAxisCount: MediaQuery.of(context).size.width < 373.33 ? 9 : 3),
                      itemBuilder: (context, index) {
                        return Row(
                          children: [
                            Flexible(
                                child: SizedBox(
                              width: 300,
                              child: Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  color: const Color(0xff78909C), // Colors.white.withOpacity(0.6), //Colors.white10
                                  elevation: 15,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: GridTile(
                                            child: Padding(
                                          padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
                                          child: FittedBox(
                                            child: Text(
                                              allBookingDetailItems.elementAt(index).title,
                                              style: allBookingDetailItems.elementAt(index).id != 5 &&
                                                      allBookingDetailItems.elementAt(index).id != 0
                                                  ? titleTextStyle
                                                  : const TextStyle(
                                                      color: Colors.black,
                                                      fontFamily: 'OpenSans',
                                                      fontSize: 14.5,
                                                      fontWeight: FontWeight.w900),
                                            ),
                                          ),
                                        )),
                                      ),
                                      SizedBox(
                                        height: allBookingDetailItems.elementAt(index).id != 0 ? 20 : 0,
                                      ),
                                      Flexible(
                                        child: Text(allBookingDetailItems.elementAt(index).subtitle,
                                            style: subtitleTextStyle),
                                      ),
                                    ],
                                  )),
                            ))
                          ],
                        );
                      }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Future<Set<String>> getDirectory() async {
    /*  
   https://stackoverflow.com/questions/72691684/how-do-i-access-the-an-assets-subdirectory-with-directory-in-flutter 
   Directory("assets/whatever") didn't <ork because During a build, Flutter places assets into a special archive called the asset bundle that apps read from at runtime. 
   Check link above
   */
    final assetsManifest = await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
    final allAssets = json.decode(assetsManifest).keys; //or values, would still work fine
    Set<String> carRepAssets = {};
    for (var asset in allAssets) {
      if (asset.toString().contains("carRep")) {
        carRepAssets.add(asset);
      }
    }
    debugPrint("PATH: $carRepAssets");
    return carRepAssets;
  }

//
}

class Items {
  int id;
  String title;
  String subtitle;
  Items({
    required this.id,
    required this.title,
    required this.subtitle,
  });
}
