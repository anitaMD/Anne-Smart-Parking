// ignore_for_file: avoid_debugPrint, unused_local_variable
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flag/flag.dart';
import 'package:flutter/services.dart';
import 'package:smart_parking/screens/inside_app/for_booking/slots_map/network.dart';
import 'package:smart_parking/styling/styling.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:country_state_city_picker/country_state_city_picker.dart';
import 'package:flutter_emoji/flutter_emoji.dart';

class SelectVehicule extends StatefulWidget {
  final User? currentlySIUser;
  final Function(Map<String, dynamic>) updateParkingDetailsAndSelectedDayMapped;
  final bool reShowSelectedCarCard;
  final Map<String, dynamic> selectedCarDetails;
  const SelectVehicule(
      {super.key,
      required this.currentlySIUser,
      required this.updateParkingDetailsAndSelectedDayMapped,
      required this.reShowSelectedCarCard,
      required this.selectedCarDetails});

  @override
  State<SelectVehicule> createState() => _SelectVehiculeState();
}

class _SelectVehiculeState extends State<SelectVehicule> {
  /* CHECK FOR CAR MODELS AND BRANDS https://www.kbb.com/car-make-model-list/new/view-all/ */
  IconData carIcon = Icons.time_to_leave_rounded,
      motorcycleIcon = Icons.motorcycle,
      arrowIcon = Icons.keyboard_double_arrow_down_rounded;

  bool isCarArrowExpanded = false,
      //isMotorcArrowExpanded = false,
      isVehiculeSelected = false,
      addCarIconPressed = false,
      newCarAdded = false,
      callSelectVehiculeAfterAdd = false,
      carSelectionCanceled = false,
      isFlagAvailable = false,
      widgetReShowSelectedCarCard = false,
      firstTimeClickingOnChangeCarAfterNextPrev = true,
      stateSetter = false,
      tappedOnCarCard = false,
      cardDragEnd = false;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> vehiculesInfoFetched = [];
  String country = '',
      region = '',
      realCountryValue = 'Select Reg. Country',
      realStateCityValue = 'Select Reg. State/City',
      realCityDepValue = 'Select Reg. City/Department',
      cityCountryPattern = "^[A-ZÀ-Ú][À-Úà-ú -zA-Z']*",
      licensePlatePattern = "[A-Z0-9]*",
      modelDetailPattern = "^([A-ZÀ-Ú0-9])([À-Úà-ú a-zA-Z'0-9-]*)";

  final CarouselController carouselController = CarouselController();
  int current = 0,
      expandVehiculeCardTotalCalls = 0,
      alertIndex = 0,
      currentSmoothIndicator = 0,
      totalStates = 0,
      totalCities = 0;
  Iterable<Widget> currentCarouselItems = [];

  ScrollController infoListViewController = ScrollController();
  double cardHeight = 100;
  Set<String> fetchedCarLogosAssets = {};
  Map<String, dynamic> pickVehiculeNeededInfMapped = {},
      formFetchedInf = {},
      selectedCarInfo = {};
  Set<Map<String, dynamic>> allUserCars = {},
      allUserMotorcycles = {},
      mappedSelectedVehiculeCard = {};
  Color cardCol = Colors.white;
  var myDB = FirebaseFirestore.instance;

  @override
  void initState() {
    //batchDelete();
    //batchWriteCarLogos(); //call it only when necessary
    widgetReShowSelectedCarCard = widget.reShowSelectedCarCard;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    /*  widgetReShowSelectedCarCard == true
        ? Future.delayed(Duration(seconds: 5)).then((value) => setState(
              () {
                isCarArrowExpanded = true;
              },
            ))
        : null; */
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: isCarArrowExpanded == false &&
                      widget.reShowSelectedCarCard == false
                  ? carCard(carIcon, 'Car', arrowIcon)
                  : isVehiculeSelected == true ||
                          widget.selectedCarDetails.isNotEmpty
                      ? selectedCarCard(true)
                      : Container(
                          height: 10,
                          color: Colors.green,
                        ),
            ),
          ],
        ),
        isCarArrowExpanded == true
            ? Container()
            : isCarArrowExpanded == false ||
                    widget.reShowSelectedCarCard == true
                ? getVehiculeNeededInfo('showCar')
                : Container(), //to get the test list from the get go. DO NOT DELETE
      ],
    );
  }

  SizedBox selectVehiculeAlertCard(int alertIndex, String showVehicule) {
    vehiculesInfoFetched = pickVehiculeNeededInfMapped['fetchedVehiculeInfo'];
    debugPrint("VehiculesInfoFetched $vehiculesInfoFetched");

    var theCurrentVehicule = vehiculesInfoFetched.singleWhere((element) {
      return element.data()['Specs']['License Plate N°'].toString().contains(
          getAllLicensePlateNumbers(vehiculesInfoFetched, showVehicule)
              .elementAt(alertIndex));
    });
    String theCountryISO = EmojiParser()
        .unemojify(
            "${theCurrentVehicule.data()['Other Details']['Reg. Country ISO']}")
        .split("-")
        .last
        .split(':')
        .first
        .toUpperCase();

    String theCityISO =
        theCurrentVehicule.data()['Other Details']['Reg. City ISO'];

    String theRegYear = theCurrentVehicule
        .data()['Specs']['Registration Year']
        .toString()
        .substring(2);

    return SizedBox(
      height: cardHeight,
      child: Card(
          color: cardCol,
          child: Row(
            children: [
              Flexible(
                child: Container(
                    height: cardHeight,
                    padding: const EdgeInsets.only(left: 5, right: 5),
                    color: const Color.fromARGB(255, 11, 73, 150),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flag.fromString(
                          theCountryISO,
                          replacement: SizedBox(
                            child: Container(
                              height: 20,
                              color: Colors.black54,
                            ),
                          ),
                          width: 120,
                          height: 20,
                        ),
                        Align(
                          child: FittedBox(
                            child: Text(
                              theCountryISO,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontFamily: 'OpenSans',
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        )
                      ],
                    )),
              ),
              //Text("TESTING")
              Expanded(
                //LICENSEPLATE
                flex: 6,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  //crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                        flex: 2,
                        child: showVehiculeLogo(
                            vehiculesInfoFetched, showVehicule, true)
                        /* FittedBox(
                        child: Text(
                            allUserCars.isNotEmpty
                                ? getAllVehiculesBrands(
                                        vehiculesInfoFetched, showVehicule)
                                    .elementAt(current)
                                : 'IS EMPTY',
                            style: const TextStyle(
                              //letterSpacing: 2.0,
                              fontSize: 15,
                              fontFamily: 'OpenSans',
                            )),
                      ), */
                        ),
                    FittedBox(
                      child: Text(
                          getAllLicensePlateNumbers(
                                  vehiculesInfoFetched, showVehicule)
                              .elementAt(alertIndex),
                          style: const TextStyle(
                              letterSpacing: 2.0,
                              fontSize: 25,
                              fontFamily: 'OpenSans',
                              fontWeight: FontWeight.w900)),
                    ),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        width: 100,
                        child: FittedBox(
                          child: Text(
                              getVehiculeModelDetail(
                                      vehiculesInfoFetched, showVehicule)
                                  .elementAt(alertIndex),
                              style: const TextStyle(
                                // letterSpacing: 1.0,
                                fontSize: 10,
                                fontFamily: 'OpenSans',
                              )),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                //CITY CODE AND REG YEAR
                child: Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.only(left: 5, right: 5),
                    height: cardHeight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Align(
                          child: FittedBox(
                            child: Text(
                              theCityISO,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: 'OpenSans',
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          child: FittedBox(
                            child: Text(
                              theRegYear,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: 'OpenSans',
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        )
                      ],
                    )),
              ),
            ],
          )),
    );
  }

  SizedBox showSingleVehiculeCardForAlertCarousel(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> vehiculesInfoFetched,
    String showVehicule,
  ) {
    return SizedBox(
      height: cardHeight,
      child: Card(
          color: cardCol,
          child: Row(
            children: [
              Flexible(
                child: Container(
                    height: cardHeight,
                    padding: const EdgeInsets.only(left: 5, right: 5),
                    color: const Color.fromARGB(255, 11, 73, 150),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flag.fromCode(
                          FlagsCode.SN,
                          width: 120,
                          height: 20,
                        ),
                        const Align(
                          child: FittedBox(
                            child: Text(
                              "YT",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontFamily: 'OpenSans',
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        )
                      ],
                    )),
              ),
              //Text("TESTING")
              Expanded(
                //LICENSEPLATE
                flex: 6,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  //crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                        flex: 2,
                        child:
                            showVehiculeLogo(vehiculesInfoFetched, showVehicule)
                        /* FittedBox(
                        child: Text(
                            allUserCars.isNotEmpty
                                ? getAllVehiculesBrands(
                                        vehiculesInfoFetched, showVehicule)
                                    .elementAt(current)
                                : 'IS EMPTY',
                            style: const TextStyle(
                              //letterSpacing: 2.0,
                              fontSize: 15,
                              fontFamily: 'OpenSans',
                            )),
                      ), */
                        ),
                    FittedBox(
                      child: Text(
                          getAllLicensePlateNumbers(
                                  vehiculesInfoFetched, showVehicule)
                              .elementAt(current),
                          style: const TextStyle(
                              letterSpacing: 2.0,
                              fontSize: 25,
                              fontFamily: 'OpenSans',
                              fontWeight: FontWeight.w900)),
                    ),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        width: 100,
                        child: FittedBox(
                          child: Text(
                              getVehiculeModelDetail(
                                      vehiculesInfoFetched, showVehicule)
                                  .elementAt(current),
                              style: const TextStyle(
                                // letterSpacing: 1.0,
                                fontSize: 10,
                                fontFamily: 'OpenSans',
                              )),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                //CITY COED AND YEAR
                child: Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.only(left: 5, right: 5),
                    height: cardHeight,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Align(
                          child: FittedBox(
                            child: Text(
                              'DK',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: 'OpenSans',
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          child: FittedBox(
                            child: Text(
                              '15',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: 'OpenSans',
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        )
                      ],
                    )),
              ),
            ],
          )),
    );
  }

  StreamBuilder<QuerySnapshot<Map<String, dynamic>>> showVehiculeLogo(
//named like this because all vehicules logos and brands are the same, be it for a car or motorcycle
      List<QueryDocumentSnapshot<Map<String, dynamic>>> vehiculesInfoFetched,
      String showVehicule,
      [bool useAlertIndex = false]) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance.collection("carBrandLogos").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Text(''); //Text('Loading brand logos');
          } else {
            List<QueryDocumentSnapshot<Map<String, dynamic>>>
                allVehiculesTypesLogosFetched = snapshot.data!.docs;
            var currentVehiculeLogoInfo =
                allVehiculesTypesLogosFetched.where((element) {
              if (firstTimeClickingOnChangeCarAfterNextPrev == true &&
                  widget.reShowSelectedCarCard == true) {
                return element
                        .data()['Brand Info']['Name']
                        .toString()
                        .toLowerCase() ==
                    widget.selectedCarDetails['Specs']['Brand']
                        .toString()
                        .toLowerCase();
              } else {
                return element
                        .data()['Brand Info']['Name']
                        .toString()
                        .toLowerCase() ==
                    getAllVehiculesBrands(vehiculesInfoFetched, showVehicule)
                        .elementAt(alertIndex)
                        .toLowerCase();
              }

              /* return useAlertIndex == false &&
                      widgetReShowSelectedCarCard == false
                  ? element
                          .data()['Brand Info']['Name']
                          .toString()
                          .toLowerCase() ==
                      getAllVehiculesBrands(vehiculesInfoFetched, showVehicule)
                          .elementAt(alertIndex)
                          .toLowerCase()
                  : useAlertIndex == true &&
                          widgetReShowSelectedCarCard == false
                      ? element
                              .data()['Brand Info']['Name']
                              .toString()
                              .toLowerCase() ==
                          getAllVehiculesBrands(
                                  vehiculesInfoFetched, showVehicule)
                              .elementAt(alertIndex)
                              .toLowerCase()
                      : firstTimeClickingOnChangeCarAfterNextPrev == true
                          ? element
                                  .data()['Brand Info']['Name']
                                  .toString()
                                  .toLowerCase() ==
                              widget.selectedCarDetails['Specs']['Brand']
                                  .toString()
                                  .toLowerCase()
                          : element
                                  .data()['Brand Info']['Name']
                                  .toString()
                                  .toLowerCase() ==
                              getAllVehiculesBrands(
                                      vehiculesInfoFetched, showVehicule)
                                  .elementAt(alertIndex)
                                  .toLowerCase(); */
            });

            debugPrint(
                "Currently displayed vehicule's logo info: ${currentVehiculeLogoInfo.first.data()}");
            return ClipOval(
                child: Image.asset(
              currentVehiculeLogoInfo.first.data()['Brand Info']['Logo'],
              width: 40,
              height: 40,
            ));
          }
        });
  }

  StreamBuilder<QuerySnapshot<Map<String, dynamic>>> getVehiculeNeededInfo(
      String vehiculeType) {
/*     Flutter StreamBuilder doesn't need to call setState to rebuild its children. StreamBuilder rebuilds by default when change were detected on stream.  */
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection("users/${widget.currentlySIUser!.uid}/vehicules")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Text(''); //Text('Loading vehicules');
          } else {
            var vehiculesInfoFetched = snapshot.data!.docs;
            mappedSelectedVehiculeCard
                .clear(); //to clear the whole map and have accurate values
            Map<String, dynamic> vehiculeInfMappedWithDocID = {};

            Iterable<Widget> carSlider = getAllLicensePlateNumbers(
                    vehiculesInfoFetched, vehiculeType)
                .map((e) => showSingleVehiculeCardForAlertCarousel(
                    vehiculesInfoFetched,
                    vehiculeType)); //maps every registerd vehicule's license plate number to its corresponding singleVehiculeCard
            debugPrint("CAROUSEL ELEMENTS NUMBER: ${carSlider.length}");
            pickVehiculeNeededInfMapped.addAll({
              'item': carSlider,
              'fetchedVehiculeInfo': vehiculesInfoFetched,
              'vehiculeType': vehiculeType
            });

            currentCarouselItems = carSlider;
            currentSmoothIndicator = carSlider.length;

            return Container(
                /*  height: 15,
              color: Colors.red, */
                );
          }
        });
  }

  Widget selectedCarCard(bool vehiculeSelected, [bool widgetReshow = false]) {
    if (!mounted) null;
    //DO NOT REMOVE following Setstate as it refreshes the stfw
    setState(
      () {
        carSelectionCanceled = false;
      },
    );
    var fetchedAlertIndex = 0;
    widgetReshow == true
        ? fetchedAlertIndex = widget.selectedCarDetails['alertIndex']
        : null;
    return Card(
        color: Colors.red,
        shadowColor: const Color(0xff7986CB),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 5,
        child: Container(
            padding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
            width: 100, //130
            height: 170, //200
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
            ),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: SizedBox(
                      height: cardHeight,
                      child: GestureDetector(
                        onTap: () async {
                          widget.reShowSelectedCarCard == true &&
                                  firstTimeClickingOnChangeCarAfterNextPrev ==
                                      true
                              ? setState(
                                  () {
                                    firstTimeClickingOnChangeCarAfterNextPrev =
                                        false;
                                  },
                                )
                              : null;
                          selectVehiculeAlertDialog(
                              currentSmoothIndicator, currentCarouselItems);
                        },
                        child: Card(
                            shadowColor: const Color(0xff7986CB),
                            elevation: 10,
                            child: Row(
                              children: [
                                Flexible(
                                  child: Container(
                                      height: cardHeight,
                                      padding: const EdgeInsets.only(
                                          left: 5, right: 5),
                                      color: const Color.fromARGB(
                                          255, 11, 73, 150),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Flag.fromString(
                                            widgetReShowSelectedCarCard == true
                                                ? widget.selectedCarDetails[
                                                        'Other Details']
                                                    ['Reg. Country ISO']
                                                : selectedCarInfo[
                                                        'Other Details']
                                                    ['Reg. Country ISO'],
                                            width: 120,
                                            height: 20,
                                          ),
                                          Align(
                                            child: FittedBox(
                                              child: Text(
                                                widgetReShowSelectedCarCard ==
                                                        true
                                                    ? widget.selectedCarDetails[
                                                            'Other Details']
                                                        ['Reg. Country ISO']
                                                    : selectedCarInfo[
                                                            'Other Details']
                                                        ['Reg. Country ISO'],
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontFamily: 'OpenSans',
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                          )
                                        ],
                                      )),
                                ),
                                //Text("TESTING")
                                Expanded(
                                  //LICENSEPLATE
                                  flex: 6,
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    //crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                          flex: 2,
                                          child: showVehiculeLogo(
                                              vehiculesInfoFetched, 'showCar')),
                                      FittedBox(
                                        child: Text(
                                            widgetReShowSelectedCarCard == true
                                                ? widget.selectedCarDetails[
                                                    'Specs']['License Plate N°']
                                                : getAllLicensePlateNumbers(
                                                        vehiculesInfoFetched,
                                                        'showCar')
                                                    .elementAt(alertIndex),
                                            style: const TextStyle(
                                                letterSpacing: 2.0,
                                                fontSize: 25,
                                                fontFamily: 'OpenSans',
                                                fontWeight: FontWeight.w900)),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: SizedBox(
                                          width: 100,
                                          child: FittedBox(
                                            child: Text(
                                                widgetReShowSelectedCarCard ==
                                                        true
                                                    ? widget.selectedCarDetails[
                                                        'Specs']['Model Detail']
                                                    : getVehiculeModelDetail(
                                                            vehiculesInfoFetched,
                                                            'showCar')
                                                        .elementAt(alertIndex),
                                                style: const TextStyle(
                                                  // letterSpacing: 1.0,
                                                  fontSize: 10,
                                                  fontFamily: 'OpenSans',
                                                )),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Flexible(
                                  //CITY CODE AND YEAR
                                  child: Container(
                                      color: Colors.transparent,
                                      padding: const EdgeInsets.only(
                                          left: 5, right: 5),
                                      height: cardHeight,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Align(
                                            child: FittedBox(
                                              child: Text(
                                                widgetReShowSelectedCarCard ==
                                                        true
                                                    ? widget.selectedCarDetails[
                                                            'Other Details']
                                                        ['Reg. City ISO']
                                                    : selectedCarInfo[
                                                            'Other Details']
                                                        ['Reg. City ISO'],
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 15,
                                                  fontFamily: 'OpenSans',
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Align(
                                            child: FittedBox(
                                              child: Text(
                                                widgetReShowSelectedCarCard ==
                                                        true
                                                    ? widget.selectedCarDetails[
                                                            'Specs'][
                                                            'Registration Year']
                                                        .toString()
                                                        .substring(1, 3)
                                                    : selectedCarInfo['Specs'][
                                                            'Registration Year']
                                                        .toString()
                                                        .substring(1, 3),
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 15,
                                                  fontFamily: 'OpenSans',
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                          )
                                        ],
                                      )),
                                ),
                              ],
                            )),
                      ),
                    ),
                  ),
                  /*  Flexible(
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.red.shade400.withValues(alpha:1),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(20),
                            top: Radius.circular(20),
                          )),
                      child: FittedBox(
                        child: Text('Click above to change car.',
                            style: TextStyle(
                                //fontSize: 10,
                                //letterSpacing: 1,
                                color: Colors.white,
                                fontFamily: 'OpenSans',
                                fontWeight: FontWeight.w200)),
                      ),
                    ),
                  )
                  */ /*  SizedBox(
                    width: 50,
                    height: 15,
                    child: ElevatedButton(
                      onPressed: () async {
                        widget.reShowSelectedCarCard == true &&
                                firstTimeClickingOnChangeCarAfterNextPrev ==
                                    true
                            ? setState(
                                () {
                                  firstTimeClickingOnChangeCarAfterNextPrev =
                                      false;
                                },
                              )
                            : null;
                        selectVehiculeAlertDialog(
                            currentSmoothIndicator, currentCarouselItems);
                      },
                      style: ButtonStyle(
                          elevation: MaterialStateProperty.all(5),
                          shape: MaterialStateProperty.all(
                            const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(20),
                              top: Radius.circular(20),
                            )),
                          ),
                          shadowColor: MaterialStateProperty.all(
                              const Color(0xff7986CB)),
                          backgroundColor: MaterialStateProperty.all(
                              Color.fromARGB(255, 185, 202, 211))),
                      child: Container(
                        padding: const EdgeInsets.only(top: 2, bottom: 2),
                        child: const Align(
                          child: FittedBox(
                            child: Text('CHANGE',
                                style: TextStyle(
                                    //fontSize: 10,
                                    letterSpacing: 1,
                                    fontFamily: 'OpenSans',
                                    fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ),
                    ),
                  )
                 */
                ])));
  }

  GestureDetector carCard(
      IconData carIcon, String carLabel, IconData buttonIcon) {
    return GestureDetector(
      onTap: () {
        debugPrint("TAPPED ON CARD");
        setState(() {
          tappedOnCarCard = true;
        });
        var carouselItems =
            pickVehiculeNeededInfMapped['item'] as Iterable<Widget>;
        int smoothIndicatorLength = 0;
        pickVehiculeNeededInfMapped.isNotEmpty
            ? smoothIndicatorLength = carouselItems.length
            : smoothIndicatorLength = 0;

        pickVehiculeNeededInfMapped.isNotEmpty
            ? selectVehiculeAlertDialog(smoothIndicatorLength, carouselItems)
            : Container();
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 5,
        child: Container(
          width: 130,
          height: 140,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(50)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                carIcon,
                size: 40,
              ),
              /*   Text(
                carLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontFamily: 'OpenSans',
                  fontWeight: FontWeight.w900,
                ),
              ), */
              SizedBox(
                  width: 80,
                  height: 30,
                  child: ElevatedButton(
                    onPressed: () async {
                      isCarArrowExpanded == false
                          ? setState(() {
                              alertIndex = 0;
                              expandVehiculeCardTotalCalls = 0;
                              current =
                                  0; //otherwise, will get an error because current could ba at 2 when motrocycle index stops at 1 so DO NOT DELETE
                              isCarArrowExpanded = true;
                              //isMotorcArrowExpanded = false;
                              addCarIconPressed = false;
                              callSelectVehiculeAfterAdd = false;
                            })
                          : setState(() {
                              isCarArrowExpanded = false;
                            });

                      if (isCarArrowExpanded == true) {
                        var carouselItems = pickVehiculeNeededInfMapped['item']
                            as Iterable<Widget>;
                        int smoothIndicatorLength = 0;
                        pickVehiculeNeededInfMapped.isNotEmpty
                            ? smoothIndicatorLength = carouselItems.length
                            : smoothIndicatorLength = 0;

                        pickVehiculeNeededInfMapped.isNotEmpty
                            ? selectVehiculeAlertDialog(
                                smoothIndicatorLength, carouselItems)
                            : Container();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 5,
                      backgroundColor: const Color(0xff78909C),
                      shape: const CircleBorder(),
                    ),
                    /*    style: ButtonStyle(
                      elevation: MaterialStateProperty.all(1),
                      shape: MaterialStateProperty.all(
                        const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(20),
                          top: Radius.circular(20),
                        )),
                      ),
                      shadowColor:
                          MaterialStateProperty.all(const Color(0xff7986CB)),
                      backgroundColor:
                          MaterialStateProperty.all(const Color(0xff78909C))), */
                    child: isCarArrowExpanded == false
                        ? const Icon(Icons.add, size: 20)
                        : const Icon(Icons.keyboard_arrow_up, size: 20),
                  ))
            ],
          ),
        ),
      ),
    );
  }

  List<String> getAllLicensePlateNumbers(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> vehiculesInfoFetched,
      String showVehicule) {
    Set<String> allVehiculesLicensePlates = {};
    if (showVehicule.contains('Car')) {
      //contains is case sensitive so be careful
      for (var element in vehiculesInfoFetched) {
        element['Type'] == "Car"
            ? {
                allVehiculesLicensePlates
                    .add(element.data()['Specs']['License Plate N°']),
                allUserCars.add({element.id: element.data()})
              }
            : null;
      }
    } else if (showVehicule.contains('Motor')) {
      for (var element in vehiculesInfoFetched) {
        element['Type'] == "Motorcycle"
            ? {
                allVehiculesLicensePlates
                    .add(element.data()['Specs']['License Plate']),
                allUserMotorcycles.add({element.id: element.data()}),
              }
            : null;
      }
    }
    debugPrint("ALL LICENSES OF CURRENT USER $allVehiculesLicensePlates");
    return allVehiculesLicensePlates.toList();
  }

  List<String> getAllVehiculesBrands(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> vehiculesInfoFetched,
      String showVehicule) {
    List<String> allVehiculesBrands =
        []; //went from Set to List because user can have cars with same brand but model detail and licene p numbers will always be unique so will need a Set
    if (showVehicule.contains('Car')) {
      //contains is case sensitive so be careful
      for (var element in vehiculesInfoFetched) {
        element['Type'] == "Car"
            ? allVehiculesBrands.add(element.data()['Specs']['Brand'])
            : null;
      }
    } else if (showVehicule.contains('Motor')) {
      for (var element in vehiculesInfoFetched) {
        element['Type'] == "Motorcycle"
            ? allVehiculesBrands.add(element.data()['Specs']['Brand'])
            : null;
      }
    }
    debugPrint("ALL BRANDS OF CURRENT USER $allVehiculesBrands");
    return allVehiculesBrands.toList();
  }

  List<String> getVehiculeModelDetail(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> vehiculesInfoFetched,
      String showVehicule) {
    List<String> allVehiculesModelsDetails = [];
    if (showVehicule.contains('Car')) {
      //contains is case sensitive so be careful
      for (var element in vehiculesInfoFetched) {
        element['Type'] == "Car"
            ? allVehiculesModelsDetails
                .add(element.data()['Specs']['Model Detail'])
            : null;
      }
    } else if (showVehicule.contains('Motor')) {
      for (var element in vehiculesInfoFetched) {
        element['Type'] == "Motorcycle"
            ? allVehiculesModelsDetails
                .add(element.data()['Specs']['Model Detail'])
            : null;
      }
    }
    debugPrint("ALL MODEL DETAILS OF CURRENT USER $allVehiculesModelsDetails");
    return allVehiculesModelsDetails.toList();
  }

  Future<dynamic> getCountry() async {
    Network n = Network("http://ip-api.com/json");
    var locationSTR = (await n.getData());
    var locationInfo = jsonDecode(locationSTR);
    debugPrint("Location from getCountry: $getCountry()");
    return locationInfo;
  }

  Container addVehiculeAlert(String vehiculeType, int smoothIndicatorLength,
      Iterable<Widget> carouselItems) {
/* USE THIS IN CASE NETWORK EXCEPTION AGAIN
Future<String> getCountryName() async {
    Position position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    debugdebugPrint('location: ${position.latitude}');
    final coordinates = new Coordinates(position.latitude, position.longitude);
    var addresses = await Geocoder.local.findAddressesFromCoordinates(coordinates);
    var first = addresses.first;
    return first.countryName; // this will return country name
} */
    return Container(
      padding: const EdgeInsets.only(
          top:
              20), //because alert adds 20 pixels padding before the action buttons so I have to compensate to make the element look like it's at the center
      height: 200,
      width: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Expanded(
            flex: 1,
            child: Align(
              child: FittedBox(child: Text("No car currently registered.")),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: 5,
              backgroundColor: Colors.indigo,
              shape: const CircleBorder(),
            ),
            onPressed: () async {
              setState(() {
                addCarIconPressed = true;
                callSelectVehiculeAfterAdd = true;
              });
              await registerCarForm(
                  vehiculeType, smoothIndicatorLength, carouselItems);
            },
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 30,
              semanticLabel: "OK",
            ),
          ),
          SizedBox(
            child: Align(
              child: FittedBox(
                  child: Text(
                '"Add"',
                style: TextStyle(
                  color: Colors.indigo.shade400,
                  fontSize: 15,
                  fontFamily: 'OpenSans',
                  fontWeight: FontWeight.bold,
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Future<QuerySnapshot<Map<String, dynamic>>> addVehiculeInfoToFirebase(
      Map<String, dynamic> formRes) {
    CollectionReference vehiculesCollectionRef =
        myDB.collection("users/${widget.currentlySIUser!.uid}/vehicules");
    WriteBatch batch = myDB.batch();
    myDB
        .collection("users/${widget.currentlySIUser!.uid}/vehicules")
        .get()
        .then((value) async {
      if (value.docs.isEmpty) {
        myDB
            .doc("users/${widget.currentlySIUser!.uid}")
            .collection("vehicules")
            .add({'initialized': true});
      }

      batch.set(
          //maybe add timestamp later to know when the car was added
          vehiculesCollectionRef.doc(),
          {
            'Type': 'Car',
            'Specs': {
              'Brand': formRes['car brand'],
              'Registration City': formFetchedInf['reg city'],
              'Registration Country': formFetchedInf['reg country'],
              'Color': 'White',
              'License Plate N°': formRes['license plate'],
              'Model Detail': formRes['model detail'],
              'Registration Year': formRes['year']
            },
            'History': {
              'Overall Parking Hours': 0,
              'Total Bookings': 0,
            },
            'Other Details': {
              'Reg. City ISO': formRes['city iso'],
              'Reg. Country ISO': EmojiParser()
                  .unemojify(realCountryValue)
                  .split("-")
                  .last
                  .split(':')
                  .first
                  .toUpperCase(),
            },
            'Currently Selected': false
          });
      await batch
          .commit()
          .whenComplete(() => debugPrint("CAR SUCCESSFULLY ADDED IN FIREBASE"));

      await myDB
          .collection("users/${widget.currentlySIUser!.uid}/vehicules")
          .get()
          .then((value) async {
        var firstInitializedDoc = value.docs
            .where((element) => element.data().keys.contains('initialized'));

        firstInitializedDoc.isNotEmpty
            ? await vehiculesCollectionRef
                .doc(firstInitializedDoc.first.id)
                .delete()
            : null;
      });
    });
    return myDB
        .collection("users/${widget.currentlySIUser!.uid}/vehicules")
        .get();
  }

  Future<void> selectVehiculeAlertDialog(
      int smoothIndicatorLength, Iterable<Widget> carouselItems,
      [String vehiculeType = 'Car']) async {
    await showDialog(
      useRootNavigator: false,
      barrierDismissible: false,
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          actionsAlignment: MainAxisAlignment.spaceBetween,
          content: SizedBox(
            width: double.maxFinite,
            height: cardHeight + 110,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  carouselItems.isEmpty
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            callSelectVehiculeAfterAdd == false
                                ? addVehiculeAlert(
                                    'Car', smoothIndicatorLength, carouselItems)
                                : Container(),
                          ],
                        )
                      : const SizedBox(
                          height: 10,
                        ),
                  carouselItems.isEmpty
                      ? Container()
                      : SizedBox(
                          height: 70,
                          child: Column(
                            children: [
                              SizedBox(
                                child: Align(
                                  child: FittedBox(
                                      child: Text(
                                    vehiculeType.contains('Car')
                                        ? '"New Car"'
                                        : '"New Motorcycle"',
                                    style: TextStyle(
                                      color:
                                          Colors.indigo.withValues(alpha: 0.8),
                                      fontSize: 15,
                                      fontFamily: 'OpenSans',
                                      fontWeight: FontWeight.w100,
                                    ),
                                  )),
                                ),
                              ),
                              FittedBox(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    elevation: 5,
                                    backgroundColor:
                                        Colors.indigo.withValues(alpha: 0.5),
                                    shape: const CircleBorder(),
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    var registerFormResult =
                                        await registerCarForm(
                                            vehiculeType,
                                            smoothIndicatorLength,
                                            carouselItems);
                                  },
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 20,
                                    semanticLabel: "OK",
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                  const SizedBox(height: 10),
                  SizedBox(
                      child: carouselItems.isNotEmpty
                          ? selectVehiculeAlertCard(alertIndex, 'showCar')
                          : Container()

                      /* Container() */ /* alertDialListView(
                                            'showCar',
                                            current,
                                          ) */
                      ),
                  const SizedBox(height: 10),
                  smoothIndicatorLength != 0
                      ? AnimatedSmoothIndicator(
                          activeIndex: alertIndex,
                          duration: const Duration(milliseconds: 400),
                          count: smoothIndicatorLength,
                          effect: const WormEffect(
                              type: WormType.normal,
                              spacing: 5.0,
                              radius: 20.0,
                              dotWidth: 5.0,
                              dotHeight: 5.0,
                              paintStyle: PaintingStyle.stroke,
                              strokeWidth: 1.5,
                              dotColor: Colors.black,
                              activeDotColor: Colors.indigo),
                        )
                      : Container(),
                ],
              ),
            ),
          ),
          actions: smoothIndicatorLength == 0 && addCarIconPressed == false
              ? [Container()]
              : [
                  TextButton(
                    onPressed: () => {
                      if (alertIndex > 0)
                        {
                          setState(() {
                            alertIndex -= 1;
                          }),
                        }
                    },
                    child: const Text(
                      'PREV',
                      style: TextStyle(
                        color: Color.fromARGB(255, 11, 73, 150),
                        fontSize: 10,
                        fontFamily: 'OpenSans',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => {
                      setState(() {
                        isVehiculeSelected = true; ////stopped here
                      }),
                      Navigator.pop(context, 'CAR SELECTED')
                    },
                    child: const Text(
                      'SELECT',
                      style: TextStyle(
                        color: Colors.green,
                        //fontSize: 16,
                        //fontFamily: 'OpenSans',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (alertIndex + 1 < smoothIndicatorLength) {
                        setState(() {
                          alertIndex += 1;
                        });
                      }
                    },
                    child: const Text(
                      'NEXT',
                      style: TextStyle(
                        color: Color.fromARGB(255, 11, 73, 150),
                        fontSize: 10,
                        fontFamily: 'OpenSans',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
        );
      }),
    ).then((value) {
      debugPrint("SelectVehiculeAlert result: $value");
      if (value == 'CAR SELECTED') {
        debugPrint(
            "CAR SELECTED $alertIndex ______ ${vehiculesInfoFetched.elementAt(alertIndex).data()}");
        setState(
          () {
            widgetReShowSelectedCarCard = false;
          },
        );
        // selectedCarInfo.clear;
        selectedCarInfo
            .addAll(vehiculesInfoFetched.elementAt(alertIndex).data());
        selectedCarInfo.addAll({
          'alertIndex': alertIndex,
        });

        widget.updateParkingDetailsAndSelectedDayMapped(selectedCarInfo);
        selectedCarCard(true);
      } else if (value == 'NEW CAR ADDED') {
        setState(() {
          isVehiculeSelected == false;
        });
      } else {
        isVehiculeSelected == false
            ? debugPrint("CANCELED CAR SELECTION")
            : debugPrint("CANCELED CAR CHANGE");
        setState(() {
          carSelectionCanceled = true;
          isVehiculeSelected == false ? isCarArrowExpanded = false : null;
        });
      }
    });
  }

  Future<Null> registerCarForm(String vehiculeType, int smoothIndicatorLength,
      Iterable<Widget> carouselItems) {
    // https://stackoverflow.com/questions/71792773/how-to-pop-out-double-alert-message/
    List<String> carOptions = [];
    getDirectory().then((value) {
      fetchedCarLogosAssets.addAll(value);
      for (var single in fetchedCarLogosAssets) {
        var carBrand = single
            .split('/')
            .toList()
            .elementAt(3)
            .toUpperCase()
            .split('.')
            .first
            .toString();
        String carBrandFormatted =
            carBrand[0].toUpperCase() + carBrand.substring(1).toLowerCase();
        carOptions.add(carBrandFormatted);
      }
      carOptions.add('OTHER');
    });
    bool autoValidate = true,
        readOnly = false,
        showSegmentedControl = true,
        cityIsoHasError = false,
        countryHasError = false,
        carBrandHasError = false,
        carColorHasError = false,
        licensePlateHasError = false,
        modelDetailHasError = false,
        yearHasError = false,
        brandFieldInitiallyEmpty = true,
        cityIsoFieldInitiallyEmpty = true,
        carColorFieldInitiallyEmpty = true,
        countryFieldInitiallyEmpty = true,
        licensePlateFieldInitiallyEmpty = true,
        modelDetailFieldInitiallyEmpty = true,
        yearFieldInitiallyEmpty = true;

    int allStates = 0, allCities = 0;
    final textField1Key = GlobalKey<FormBuilderFieldState>();
    // ignore: unused_element
    void onChanged(dynamic val) => debugPrint(val.toString());
    final formKey = GlobalKey<FormBuilderState>();
    //https://www.iso.org/obp/ui#iso:code:3166:SN
    return showDialog(
        barrierDismissible: false,
        useRootNavigator: false,
        context: context,
        builder: (dialcontext) =>
            StatefulBuilder(builder: (dialcontext, setState) {
              return AlertDialog(
                content: SizedBox(
                  width: double.maxFinite,
                  height: cardHeight + 800,
                  child: SingleChildScrollView(
                    child: GestureDetector(
                      onTap: () {
                        FocusScope.of(context).requestFocus(FocusNode());
                      },
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            "Please refer to the license plate model below and fill the form with your car's license plate information.",
                            style: TextStyle(
                              color: Colors.indigo.shade400,
                              fontSize: 15,
                              fontFamily: 'OpenSans',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            //DO NOT EDIT
                            height: cardHeight,
                            child: Card(
                                surfaceTintColor: Colors.yellow,
                                elevation: 5,
                                shadowColor: (const Color(0xff7986CB)),
                                color: cardCol,
                                child: Row(
                                  children: [
                                    Flexible(
                                      flex: 2,
                                      child: Container(
                                          height: cardHeight,
                                          padding: const EdgeInsets.only(
                                              left: 5, right: 5),
                                          color: const Color.fromARGB(
                                              255, 11, 73, 150),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Container(
                                                color: Colors.black,
                                                width: 120,
                                                height: 20,
                                                child: const FittedBox(
                                                  child: Text(
                                                    'Country Flag',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                      fontFamily: 'OpenSans',
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              /* Flag.fromCode(
                                                  FlagsCode.SN,
                                                  width: 120,
                                                  height: 20,
                                                ), */
                                              const Align(
                                                child: FittedBox(
                                                  child: Text(
                                                    'Country ISO',
                                                    //isoCountryCode,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                      fontFamily: 'OpenSans',
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            ],
                                          )),
                                    ),
                                    //Text("TESTING")
                                    Expanded(
                                      //LICENSEPLATE
                                      flex: 8,
                                      child: Container(
                                        margin: const EdgeInsets.only(left: 10),
                                        child: const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: SizedBox(
                                                width: 80,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: FittedBox(
                                                child: Text('License Plate N° ',
                                                    style: TextStyle(
                                                        //letterSpacing: 2.0,
                                                        fontSize: 15,
                                                        fontFamily: 'OpenSans',
                                                        fontWeight:
                                                            FontWeight.w500)),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: SizedBox(
                                                width: 80,
                                                child: FittedBox(
                                                  child: Text('Model Detail',
                                                      style: TextStyle(
                                                        // letterSpacing: 1.0,
                                                        fontSize: 5,
                                                        fontFamily: 'OpenSans',
                                                      )),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Flexible(
                                      flex: 2,
                                      child: Container(
                                          height: cardHeight,
                                          padding: const EdgeInsets.only(
                                              left: 5, right: 5),
                                          color: Colors.transparent,
                                          child: const Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              FittedBox(
                                                child: Text(
                                                  'City ISO',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 15,
                                                    fontFamily: 'OpenSans',
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ),
                                              /* Flag.fromCode(
                                                  FlagsCode.SN,
                                                  width: 120,
                                                  height: 20,
                                                ), */
                                              Align(
                                                child: FittedBox(
                                                  child: Text(
                                                    'Reg. YEAR',
                                                    //isoCountryCode,
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 15,
                                                      fontFamily: 'OpenSans',
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            ],
                                          )),
                                    ),
                                  ],
                                )),
                          ),
                          SizedBox(
                            child: SelectState(
                              style: realCountryValue.contains("Reg.") ||
                                      realStateCityValue.contains("Reg.")
                                  ? const TextStyle(
                                      color: Color.fromARGB(163, 0, 0, 0))
                                  : const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                contentPadding:
                                    EdgeInsets.only(top: 8, bottom: 8),
                              ),
                              onCountryChanged: (value) {
                                setState(() {
                                  realCountryValue = value;
                                });
                              },
                              onStateChanged: (value) {
                                setState(() {
                                  realStateCityValue = value;
                                });
                              },
                              onCityChanged: (value) {
                                setState(() {
                                  realCityDepValue = value;
                                });
                              },
                              onCityLengthChanged: (int value) {
                                setState(() {
                                  totalCities = value;
                                });
                              },
                              onStateLengthChanged: (int value) {
                                setState(() {
                                  totalStates = value;
                                });
                              },
                            ),
                          ),
                          FormBuilder(
                            key: formKey,
                            // enabled: false,
                            onChanged: () {
                              formKey.currentState!.save();
                              debugPrint(
                                  "USER INPUT FROM FORM ${formKey.currentState!.value.toString()}");
                            },
                            autovalidateMode: AutovalidateMode.disabled,
                            skipDisabled: true,
                            child: Column(
                              children: [
                                FormBuilderTextField(
                                  maxLength: 3,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp("[A-Z*]*"),
                                        replacementString: ''),
                                    FilteringTextInputFormatter.deny(
                                        RegExp(r'[/\\0-9]')),
                                  ],
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  name: 'city iso',
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.only(
                                        bottom: 15, top: 15),
                                    counterStyle: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 8,
                                      height: 0.2,
                                    ),
                                    hintText: 'Example for Dakar : DK',
                                    labelStyle: cityIsoFieldInitiallyEmpty
                                        ? null
                                        : customlabelStyleAddCar,
                                    labelText: 'City ISO-3166 code',
                                    suffixIcon: cityIsoHasError == true
                                        ? const Icon(Icons.error,
                                            color: Colors.red)
                                        : cityIsoFieldInitiallyEmpty
                                            ? null
                                            : const Icon(Icons.check,
                                                color: Colors.green),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      cityIsoFieldInitiallyEmpty = false;
                                      cityIsoHasError = !(formKey
                                              .currentState?.fields['city iso']
                                              ?.validate() ??
                                          false);
                                    });
                                  },
                                  // valueTransformer: (text) => num.tryParse(text),
                                  validator: FormBuilderValidators.compose([
                                    FormBuilderValidators.required(),
                                    FormBuilderValidators.match(
                                        RegExp(r"[A-Z*]{2,3}"),
                                        errorText: "2-3 letters required."),
                                    FormBuilderValidators.max(70),
                                  ]),
                                  //initialValue: '?',
                                  keyboardType: TextInputType.name,
                                  textInputAction: TextInputAction.next,
                                ),

                                FormBuilderDropdown<String>(
                                  autofocus: true,
                                  name: 'car brand',
                                  decoration: InputDecoration(
                                    labelText: 'Car Brand',
                                    suffix: carBrandHasError == true
                                        ? const Icon(
                                            Icons.error,
                                            size: 30,
                                          )
                                        : brandFieldInitiallyEmpty == true
                                            ? null
                                            : brandFieldInitiallyEmpty ==
                                                        false &&
                                                    carBrandHasError == false
                                                ? const Icon(
                                                    Icons.check,
                                                    color: Colors.green,
                                                    size: 25,
                                                  )
                                                : null,
                                    hintText: 'Select A Brand',
                                  ),
                                  validator: FormBuilderValidators.compose(
                                      [FormBuilderValidators.required()]),
                                  items: carOptions
                                      .map((brand) => DropdownMenuItem(
                                            alignment: AlignmentDirectional
                                                .centerStart,
                                            value: brand,
                                            child: Text(brand),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      brandFieldInitiallyEmpty = false;
                                      carBrandHasError = !(formKey
                                              .currentState?.fields['car brand']
                                              ?.validate() ??
                                          false);
                                    });
                                  },
                                  valueTransformer: (val) => val?.toString(),
                                ),
                                /*             //CITY FIELD
                                FormBuilderTextField(
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(cityCountryPattern),
                                        replacementString: ''),
                                    FilteringTextInputFormatter.deny(
                                        RegExp(r'[/\\0-9]')),
                                  ],
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  name: 'city',
                                  decoration: InputDecoration(
                                    hintText: 'Your City',
                                    labelStyle: cityFieldInitiallyEmpty
                                        ? null
                                        : customlabelStyleAddCar,
                                    labelText: 'City',
                                    suffixIcon: cityHasError == true
                                        ? const Icon(Icons.error,
                                            color: Colors.red)
                                        : cityFieldInitiallyEmpty
                                            ? null
                                            : const Icon(Icons.check,
                                                color: Colors.green),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      cityFieldInitiallyEmpty = false;
                                      cityHasError = !(formKey
                                              .currentState?.fields['city']
                                              ?.validate() ??
                                          false);
                                    });
                                  },
                                  // valueTransformer: (text) => num.tryParse(text),
                                  validator: FormBuilderValidators.compose([
                                    FormBuilderValidators.required(),
                                    FormBuilderValidators.match(
                                        cityCountryPattern),
                                    FormBuilderValidators.max(70),
                                  ]),
                                  //initialValue: '?',
                                  keyboardType: TextInputType.name,
                                  textInputAction: TextInputAction.next,
                                ),
                
                                //COUNTRY FIELD
                                FormBuilderTextField(
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(cityCountryPattern),
                                        replacementString: ''),
                                    FilteringTextInputFormatter.deny(
                                        RegExp(r'[/\\0-9]')),
                                  ],
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  name: 'country',
                                  decoration: InputDecoration(
                                    hintText: 'Your Country',
                                    labelText: 'Country',
                                    suffixIcon: countryHasError
                                        ? const Icon(Icons.error,
                                            color: Colors.red)
                                        : countryFieldInitiallyEmpty
                                            ? null
                                            : const Icon(Icons.check,
                                                color: Colors.green),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      countryFieldInitiallyEmpty = false;
                                      countryHasError = !(formKey
                                              .currentState?.fields['country']
                                              ?.validate() ??
                                          false);
                                    });
                                  },
                                  // valueTransformer: (text) => num.tryParse(text),
                                  validator: FormBuilderValidators.compose([
                                    FormBuilderValidators.required(),
                                    FormBuilderValidators.match(
                                        cityCountryPattern),
                                    FormBuilderValidators.max(70),
                                  ]),
                                  //initialValue: '?',
                                  keyboardType: TextInputType.text,
                                  textInputAction: TextInputAction.next,
                                ),
                 */
                                //LICENSE PLATE FIELD
                                FormBuilderTextField(
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(licensePlatePattern),
                                        replacementString: ''),
                                  ],
                                  maxLength: 8,
                                  maxLengthEnforcement:
                                      MaxLengthEnforcement.enforced,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  name: 'license plate',
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.only(
                                        bottom: 15, top: 15),
                                    counterStyle: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 8,
                                      height: 0.2,
                                    ),
                                    hintText: 'Your car lincense plate',
                                    labelText: 'License Plate',
                                    suffixIcon: licensePlateHasError
                                        ? const Icon(Icons.error,
                                            color: Colors.red)
                                        : licensePlateFieldInitiallyEmpty
                                            ? null
                                            : const Icon(Icons.check,
                                                color: Colors.green),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      licensePlateFieldInitiallyEmpty = false;
                                      licensePlateHasError = !(formKey
                                              .currentState
                                              ?.fields['license plate']
                                              ?.validate() ??
                                          false);
                                    });
                                  },
                                  // valueTransformer: (text) => num.tryParse(text),
                                  validator: FormBuilderValidators.compose([
                                    FormBuilderValidators.required(),
                                    FormBuilderValidators.match(
                                        RegExp(r"[A-Z0-9]{5,8}"),
                                        errorText: "5-8 characters needed."),
                                  ]),
                                  //initialValue: '?',
                                  keyboardType: TextInputType.text,
                                  textInputAction: TextInputAction.next,
                                ),

                                //MODEL DETAIL FIELD
                                FormBuilderTextField(
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(modelDetailPattern),
                                        replacementString: ''),
                                  ],

                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  name: 'model detail',
                                  decoration: InputDecoration(
                                    hintText: 'Car Model Details',
                                    labelText: 'Model Detail',
                                    suffixIcon: modelDetailHasError
                                        ? const Icon(Icons.error,
                                            color: Colors.red)
                                        : modelDetailFieldInitiallyEmpty
                                            ? null
                                            : const Icon(Icons.check,
                                                color: Colors.green),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      modelDetailFieldInitiallyEmpty = false;
                                      modelDetailHasError = !(formKey
                                              .currentState
                                              ?.fields['model detail']
                                              ?.validate() ??
                                          false);
                                    });
                                  },
                                  // valueTransformer: (text) => num.tryParse(text),
                                  validator: FormBuilderValidators.compose([
                                    FormBuilderValidators.required(),
                                    FormBuilderValidators.match(
                                        RegExp(modelDetailPattern)),
                                    FormBuilderValidators.max(70),
                                  ]),
                                  //initialValue: '?',
                                  keyboardType: TextInputType.text,
                                  textInputAction: TextInputAction.next,
                                ),

                                //YEAR FIELD
                                FormBuilderTextField(
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp('^[1-2][0-9]*'),
                                        replacementString: ''),
                                  ],
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  maxLength: 4,
                                  name: 'year',
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.only(
                                        bottom: 15, top: 15),
                                    counterStyle: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 8,
                                      height: 0.2,
                                    ),
                                    hintText: 'Year Of First Registration',
                                    labelText: 'Year',
                                    suffixIcon: yearHasError
                                        ? const Icon(Icons.error,
                                            color: Colors.red)
                                        : yearFieldInitiallyEmpty
                                            ? null
                                            : const Icon(Icons.check,
                                                color: Colors.green),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      yearFieldInitiallyEmpty = false;
                                      yearHasError = !(formKey
                                              .currentState?.fields['year']
                                              ?.validate() ??
                                          false);
                                    });
                                  },
                                  // valueTransformer: (text) => num.tryParse(text),
                                  validator: FormBuilderValidators.compose([
                                    FormBuilderValidators.required(),
                                    FormBuilderValidators.numeric(),
                                    FormBuilderValidators.match(
                                        RegExp(r'^([1-2]+)([0-9]){3}'),
                                        errorText:
                                            '4 digits required.'), //validator.match is diff from allow
                                    FormBuilderValidators.max(
                                        DateTime.now().year),
                                  ]),
                                  //initialValue: '1960',
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final nav = Navigator.of(dialcontext);
                                    if (realCountryValue.contains("Reg.") ||
                                        realStateCityValue.contains("Reg.")) {
                                      null;
                                    } else {
                                      if (formKey.currentState
                                              ?.saveAndValidate() ??
                                          false) {
                                        formFetchedInf.addAll(
                                            formKey.currentState!.value);
                                        debugPrint(
                                            "FETCHED FORM RESULT $formFetchedInf");
                                        carouselItems =
                                            pickVehiculeNeededInfMapped['item']
                                                as Iterable<Widget>;
                                        smoothIndicatorLength =
                                            carouselItems.length;
                                        formFetchedInf.addAll({
                                          'reg country': realCountryValue
                                              .split("    ")
                                              .last,
                                          'reg city': realStateCityValue,
                                        });

                                        debugPrint(
                                            "FORM VALIDATION SUCCESS ${formKey.currentState!.value}");
                                        await addVehiculeInfoToFirebase(
                                                formFetchedInf)
                                            .then((fireSnap) {
                                          Future.delayed(
                                                  const Duration(seconds: 2))
                                              .then((value) {
                                            smoothIndicatorLength == 0
                                                ? nav.pop(
                                                    'NEW CAR ADDED') //to discard the "no vehicule registed ADD alert"
                                                : null;
                                            nav.pop('NEW CAR ADDED');
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(dialcontext)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(vehiculeType
                                                              .contains(
                                                                  'Car') ==
                                                          true
                                                      ? 'Car added successfully'
                                                      : 'Motorcycle added successfully'),
                                                ),
                                              );
                                            }
                                          });
                                        });
                                        /*  Future.delayed(Duration(seconds: 5))
                                          .then((value) {
                                        Navigator.of(context).pop();
                                        Navigator.of(dialcontext).pop();
                                      }); */
                                      } else {
                                        debugPrint(formKey.currentState?.value
                                            .toString());
                                        debugPrint('Form validation failed');
                                      }
                                    }
                                  },
                                  child: const Text(
                                    'Submit',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                  child: OutlinedButton(
                                      onPressed: () {
                                        formKey.currentState?.reset();

                                        realCountryValue =
                                            'Select Reg. Country';
                                        realStateCityValue =
                                            'Select Reg. State/City';
                                      },
                                      // color: Theme.of(context).colorScheme.secondary,
                                      child: Text(
                                        'Reset',
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary),
                                      )))
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            })).then((value) {
      if (value == 'NEW CAR ADDED') {
        myDB
            .collection("users/${widget.currentlySIUser!.uid}/vehicules")
            .get()
            .then((snapshotV) async {
          await afterVehiculeAddGetNeededInf(vehiculeType, snapshotV.docs);
          setState(
            () {
              carouselItems =
                  pickVehiculeNeededInfMapped['item'] as Iterable<Widget>;
              smoothIndicatorLength = carouselItems.length;
              isFlagAvailable = true;
              newCarAdded = true;
            },
          );
          selectVehiculeAlertDialog(
            smoothIndicatorLength,
            carouselItems,
            vehiculeType,
          );
        });
/* 
        setState(() {
          firstTimeCallingShow = false;
        }); */
      } else {
        debugPrint("HERE WE GO");
      }
    });
  }

  dynamic afterVehiculeAddGetNeededInf(String vehiculeType,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    Iterable<Widget> carSlider = getAllLicensePlateNumbers(docs, vehiculeType)
        .map((e) => showSingleVehiculeCardForAlertCarousel(docs,
            vehiculeType)); //maps every registerd vehicule's license plate number to its corresponding singleVehiculeCard
    debugPrint("CAROUSEL ELEMENTS NUMBER: ${carSlider.length}");
    pickVehiculeNeededInfMapped.addAll({
      'item': carSlider,
      'fetchedVehiculeInfo': docs,
      'vehiculeType': vehiculeType
    });
    debugPrint("pickVehiculeNeededInfMapped: $pickVehiculeNeededInfMapped");
    return pickVehiculeNeededInfMapped['fetchedVehiculeInfo'];
  }

  Future<void> batchDelete() async {
    CollectionReference collectionRef = myDB.collection("carBrandLogos");
    WriteBatch batch = myDB.batch();
    collectionRef.get().then((value) => {
          debugPrint("DONNE: ${value.docs.length}"),
          for (int i = 0; i < value.docs.length; i++)
            {batch.delete(value.docs.elementAt(i).reference)},
          debugPrint("DONNE: ${value.docs.length}"),
          batch.commit().whenComplete(() => debugPrint("SUCCESSFULLY DELETED")),
          //map((document) => {debugPrint("MAMAM: ${document.id}")})
        });

    /* {batch.delete(document.reference)})
        });
    batch.commit().whenComplete(() => debugPrint("SUCCESSFULLY DELETED")); */
  }

  Future<void> batchWriteCarLogos() async {
    await getDirectory().then((value) {
      fetchedCarLogosAssets.addAll(value);
    });
    CollectionReference collectionRef = myDB.collection("carBrandLogos");
    WriteBatch batch = myDB.batch();
    for (int i = 0; i < fetchedCarLogosAssets.length; i++) {
      batch.set(
        collectionRef.doc(),
        {
          'Brand Info': {
            'Logo': fetchedCarLogosAssets.elementAt(i),
            'Name': fetchedCarLogosAssets
                .elementAt(i)
                .split('/')
                .toList()
                .elementAt(3)
                .toUpperCase()
                .split('.')
                .first,
          }
        },
      );
    }
    await batch
        .commit()
        .whenComplete(() => debugPrint("SUCCESSFULLY WRITTEN TO FIREBASE"));
  }

  Future<Set<String>> getDirectory() async {
    /*  
   https://stackoverflow.com/questions/72691684/how-do-i-access-the-an-assets-subdirectory-with-directory-in-flutter 
   Directory("assets/whatever") didn't <ork because During a build, Flutter places assets into a special archive called the asset bundle that apps read from at runtime. 
   Check link above
   */
    final assetsManifest =
        await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
    final allAssets =
        json.decode(assetsManifest).keys; //or values, would still work fine
    Set<String> carLogosAssets = {};
    for (var asset in allAssets) {
      if (asset.toString().contains("carLogos")) {
        carLogosAssets.add(asset);
      }
    }
    debugPrint("PATH: $carLogosAssets");
    return carLogosAssets;
  }

  Future<Null> refresh() => Future.delayed(const Duration(seconds: 1), () {
        setState(() {});
      });

/* THESE WILL BE NEEDED IF I EVER WANT TO DISPLAY A CAROUSEL USING THE CAROULSEL SLIDER DEPENDANCY

/*   selectedmotorcycleCard() {
    return const Card(borderOnForeground: true, color: Colors.yellow);
  }
 */
  

 /*  motorcycleCard(
      IconData motorcycleIcon, String motorcycleLabel, IconData buttonIcon) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 5,
      child: Container(
        width: 130,
        height: 140,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(50)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              motorcycleIcon,
              size: 40,
            ),
            Align(
              child: FittedBox(
                child: Text(
                  motorcycleLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontFamily: 'OpenSans',
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 80,
              height: 30,
              child: ElevatedButton(
                  onPressed: () {
                    //DEAL WITH SELECTEDCARCARD
                    isMotorcArrowExpanded == false
                        ? setState(() {
                            expandVehiculeCardTotalCalls = 0;
                            current =
                                0; //otherwise, will get an error because current could ba at 2 when motrocycle index stops at 1 so DO NOT DELETE
                            isMotorcArrowExpanded = true;
                            isCarArrowExpanded =
                                false; //both shouldn(t be true at the same time)
                          })
                        : setState(() {
                            isMotorcArrowExpanded = false;
                          });
                  },
                  style: ButtonStyle(
                      elevation: MaterialStateProperty.all(1),
                      shape: MaterialStateProperty.all(
                        const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(20),
                          top: Radius.circular(20),
                        )),
                      ),
                      shadowColor:
                          MaterialStateProperty.all(const Color(0xff7986CB)),
                      backgroundColor:
                          MaterialStateProperty.all(const Color(0xff78909C))),
                  child: Icon(
                    isMotorcArrowExpanded == true
                        ? Icons.keyboard_arrow_up
                        : arrowIcon,
                    size: 15,
                  )),
            )
          ],
        ),
      ),
    );
  }
 */

  /*   expandedCardForCarousel(String showVehicule) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection("users/${widget.currentlySIUser!.uid}/vehicules")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Text('Loading vehicules');
          } else {
            var vehiculesInfoFetched = snapshot.data!.docs;
            mappedSelectedVehiculeCard
                .clear(); //to clear the whole map and have accurate values

            Map<String, dynamic> vehiculeInfMappedWithDocID = {};
            for (var element in vehiculesInfoFetched) {
              vehiculeInfMappedWithDocID.addAll({element.id: element.data()});
            }
            debugPrint("VEHICULES LENGHT: $vehiculeInfMappedWithDocID");
            var neededVehiculesNumber =
                getAllLicensePlates(vehiculesInfoFetched, showVehicule).length;
            Iterable<Widget> carSlider =
                getAllLicensePlates(vehiculesInfoFetched, showVehicule).map(
                    (e) =>
                        getCardForSlider(vehiculesInfoFetched, showVehicule));
            debugPrint("CAROUSEL LEGNTH: ${carSlider.length}");
      
            return buildCarousel(carSlider.toList(), vehiculesInfoFetched, showVehicule);
          }
        });
  }
 */

  /*  Widget getCardForSlider(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> vehiculesInfoFetched,
    String showVehicule,
  ) {
    return Card(
        color: cardCol,
        child: Row(
          children: [
            Flexible(
              child: Container(
                  height: cardHeight,
                  padding: const EdgeInsets.only(left: 5, right: 5),
                  color: const Color.fromARGB(255, 11, 73, 150),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flag.fromCode(
                        FlagsCode.SN,
                        width: 120,
                        height: 20,
                      ),
                      Align(
                        child: FittedBox(
                          child: Text(
                            isoCountryCode,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: 'OpenSans',
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      )
                    ],
                  )),
            ),
            //Text("TESTING")
            Expanded(
              //LICENSEPLATE
              flex: 6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                //crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                      flex: 2,
                      child: showCarLogo(vehiculesInfoFetched, showVehicule)
                      /* FittedBox(
                      child: Text(
                          allUserCars.isNotEmpty
                              ? getAllVehiculesBrands(
                                      vehiculesInfoFetched, showVehicule)
                                  .elementAt(current)
                              : 'IS EMPTY',
                          style: const TextStyle(
                            //letterSpacing: 2.0,
                            fontSize: 15,
                            fontFamily: 'OpenSans',
                          )),
                    ), */
                      ),
                  FittedBox(
                    child: Text(
                        getAllLicensePlates(vehiculesInfoFetched, showVehicule)
                            .elementAt(current),
                        style: const TextStyle(
                            letterSpacing: 2.0,
                            fontSize: 25,
                            fontFamily: 'OpenSans',
                            fontWeight: FontWeight.w900)),
                  ),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      width: 100,
                      child: FittedBox(
                        child: Text(
                            getVehiculeModelDetail(
                                    vehiculesInfoFetched, showVehicule)
                                .elementAt(current),
                            style: const TextStyle(
                              // letterSpacing: 1.0,
                              fontSize: 10,
                              fontFamily: 'OpenSans',
                            )),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              //CITY COED AND YEAR
              child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.only(left: 5, right: 5),
                  height: cardHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Align(
                        child: FittedBox(
                          child: Text(
                            'DK',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: 'OpenSans',
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        child: FittedBox(
                          child: Text(
                            '15',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: 'OpenSans',
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      )
                    ],
                  )),
            ),
          ],
        ));
  } */

 /* buildCarousel(
      List<Widget> carSlider,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> vehiculesInfoFetched,
      String showVehicule,
      [int newValue = 0]) {
    return Container(
      margin: const EdgeInsets.only(top: 15, left: 10, right: 10),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.indigo.withAlpha(30), width: 3),
          right: BorderSide(color: Colors.indigo.withAlpha(30), width: 3),
          top: BorderSide(color: Colors.indigo.withAlpha(30), width: 3),
          bottom: BorderSide(color: Colors.indigo.withAlpha(30), width: 3),
        ),
      ),
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      width: double.infinity,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CarouselSlider.builder(
          carouselController: carouselController,
          itemCount: carSlider.length,
          itemBuilder:
              (BuildContext context, int itemIndex, int pageViewIndex) =>
                  //updateKey(itemIndex);
                  GestureDetector(
                      onTap: () {
                        debugPrint(
                            "Currently selected car : ${getAllVehiculesBrands(vehiculesInfoFetched, showVehicule).elementAt(current)}");

                        isVehiculeSelected =
                            false; //put false for now because it's gonna make the pick a vehicule card disappear
                      },
                      child: carSlider.elementAt(current)),
          options: CarouselOptions(
            onPageChanged: (index, reason) {
              debugPrint("REASON: ${reason.index}");
              setState(() {
                current = index;
              });
            },
            height: cardHeight,
            disableCenter: true,

            //aspectRatio: 16 / 9,
            viewportFraction: 0.7,
            padEnds: true,
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
          count: carSlider.length,
          effect: const WormEffect(
              type: WormType.normal,
              spacing: 5.0,
              radius: 20.0,
              dotWidth: 5.0,
              dotHeight: 5.0,
              paintStyle: PaintingStyle.stroke,
              strokeWidth: 1.5,
              dotColor: Colors.black,
              activeDotColor: Colors.indigo),
        ),
        /* Container(
          height: 30,
          color: Colors.red,
        ), */
      ]),
    );
  } */


 /* registeredVehiculesCard(
    int count,
    String showVehicule,
  ) {
    return Card(
            color: Colors.blueGrey,
            shadowColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 5,
            child: Container(
              //THERE WAS AN EXPANDED HERE BEFORE CONTAINER
              padding: const EdgeInsets.all(5),
              width: 95,
              height: 70,
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(50)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    child: FittedBox(
                      child: Text(
                        "Registered $showVehicule:  $count",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontFamily: 'OpenSans',
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  /*       SizedBox(
                width: 85,
                child: Align(
                  child: FittedBox(
                      child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontFamily: 'OpenSans',
                      fontWeight: FontWeight.w900,
                    ),
                  )),
                )),
          */
                ],
              ),
            ),
          );
  }
 */


*/
} //closing MAIN BRACKETS
