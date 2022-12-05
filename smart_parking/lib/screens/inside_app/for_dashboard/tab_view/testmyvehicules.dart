import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_state_city_picker/country_state_city_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flag/flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_emoji/flutter_emoji.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:smart_parking/models/common/theme_helper.dart';
import 'package:smart_parking/services/local_notifications/notification.dart';
import 'package:smart_parking/styling/styling.dart';

class TestMyVehiculesTab extends StatefulWidget {
  final Function(String carModelFromPanel, String carBrandFromPanel) updateDashboardCar;
  const TestMyVehiculesTab({Key? key, required this.updateDashboardCar}) : super(key: key);

  @override
  State<TestMyVehiculesTab> createState() => _TestMyVehiculesTabState();
}

class _TestMyVehiculesTabState extends State<TestMyVehiculesTab> with SingleTickerProviderStateMixin {
  Set<String> fetchedCarLogosAssets = {};
  bool singleTapVehiculeSelected = false, isVehiculeDeleted = false;
  int current = 0, alertIndex = 0, totalStates = 0, totalCities = 0, selectedVehiculeIndex = 0;
  Map<String, dynamic> selectedVehiculeInfoMappedFromSelectVehicule = {}, formFetchedInf = {};
  User? currentUser = FirebaseAuth.instance.currentUser;
  double cardHeight = 100;
  String country = '',
      region = '',
      realCountryValue = 'Select Reg. Country',
      realStateCityValue = 'Select Reg. State/City',
      realCityDepValue = 'Select Reg. City/Department',
      cityCountryPattern = "^[A-ZÀ-Ú][À-Úà-ú -zA-Z']*",
      licensePlatePattern = "[A-Z0-9]*",
      modelDetailPattern = "^([A-ZÀ-Ú0-9])([À-Úà-ú a-zA-Z'0-9-]*)",
      newlySelectedCarModel = '',
      newlySelectedCarBrand = '';

  Color cardCol = Colors.white, defaultVehiculeColor = const Color.fromARGB(255, 169, 194, 215);

  ScrollController infoListViewController = ScrollController();
  late AnimationController _animationController;

  final CarouselController carouselController = CarouselController();
  //

  @override
  void initState() {
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animationController.repeat(reverse: true);
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return currentUser != null
        ? expandedCardForCarousel(widget.updateDashboardCar)

        /*  SelectVehicule(
            currentlySIUser: currentUser!,
            updateParkingDetailsAndSelectedDayMapped: fetchSelectedVehiculeInfo,
            reShowSelectedCarCard: selectedVehiculeInfoMappedFromSelectVehicule.isEmpty ? false : true,
            selectedCarDetails: selectedVehiculeInfoMappedFromSelectVehicule,
          ) */
        : Container(
            height: 100,
            color: Colors.red,
          );
  }

  void showSnackBarText(String text, [TextStyle snackStyle = const TextStyle(color: Colors.white, fontSize: 15)]) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 50,
          behavior: SnackBarBehavior.floating,
          content: Text(
            text,
            style: snackStyle,
          ),
        ),
      );
    }
  }

  fetchSelectedVehiculeInfo(Map<String, dynamic> selectedVehiculeInf) {
    setState(() {
      selectedVehiculeInfoMappedFromSelectVehicule.addAll(selectedVehiculeInf);
    });
  }

  /* Widget selectedCarCard() {
    if (!mounted) null;
    //DO NOT REMOVE following Setstate as it refreshes the stfw
    /* setState(
      () {
        carSelectionCanceled = false;
      },
    );
    var fetchedAlertIndex = 0;
    widgetReshow == true ? fetchedAlertIndex = widget.selectedCarDetails['alertIndex'] : null; */
    return  */

  expandedCardForCarousel(Function(String carModelFromPanel, String carBrandFromPanel) updateDashboardCar) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection("users/${currentUser!.uid}/vehicules").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Text('Loading vehicules');
          } else {
            var vehiculesInfoFetched = snapshot.data!.docs;
            if (vehiculesInfoFetched.isNotEmpty) {
              vehiculesInfoFetched.sort(
                (aData, bData) {
                  var b = bData['Currently Selected'] as bool;
                  return b ? 1 : -1;
                },
              );
            }
            return SingleChildScrollView(
              child: Column(
                children: [
                  showTotalRegCars(vehiculesInfoFetched),
                  buildCarousel(
                    //carSlider.toList(),
                    vehiculesInfoFetched,
                  )
                ],
              ),
            );
          }
        });
  }

  List<String> getVehiculeModelDetail(List<QueryDocumentSnapshot<Map<String, dynamic>>> vehiculesInfoFetched) {
    List<String> allVehiculesModelsDetails = [];

    //contains is case sensitive so be careful
    for (var element in vehiculesInfoFetched) {
      element['Type'] == "Car" ? allVehiculesModelsDetails.add(element.data()['Specs']['Model Detail']) : null;
    }

    debugPrint("ALL MODEL DETAILS OF CURRENT USER $allVehiculesModelsDetails");
    return allVehiculesModelsDetails.toList();
  }

  List<String> getAllLicensePlates(List<QueryDocumentSnapshot<Map<String, dynamic>>> vehiculesInfoFetched) {
    Set<String> allVehiculesLicensePlates = {};

    //contains is case sensitive so be careful
    for (var element in vehiculesInfoFetched) {
      element['Type'] == "Car"
          ? {
              allVehiculesLicensePlates.add(element.data()['Specs']['License Plate N°']),
            }
          : null;
    }

    debugPrint("ALL LICENSES OF CURRENT USER $allVehiculesLicensePlates");
    return allVehiculesLicensePlates.toList();
  }

  Widget getCardForSlider(List<QueryDocumentSnapshot<Map<String, dynamic>>> vehiculesInfoFetched, int listViewIndex) {
    return SizedBox(
      width: 230,
      child: Card(
          color: singleTapVehiculeSelected && selectedVehiculeIndex == listViewIndex
              ? Colors.indigo.withAlpha(400)
              : listViewIndex != 0
                  ? Colors.white
                  : defaultVehiculeColor,
          shadowColor: const Color(0xff7986CB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: 5,
          child: Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              width: 100, //130
              height: 170, //200
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
              ),
              child: Column(
                  mainAxisAlignment: listViewIndex == 0 ? MainAxisAlignment.center : MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      flex: 2,
                      child: SizedBox(
                        height: cardHeight,
                        child: GestureDetector(
                          onTap: (() {
                            setState(
                              () {
                                singleTapVehiculeSelected
                                    ? {singleTapVehiculeSelected = false, selectedVehiculeIndex = 0}
                                    : {singleTapVehiculeSelected = true, selectedVehiculeIndex = listViewIndex};
                              },
                            );
                          }),
                          onDoubleTap: () async {
                            listViewIndex != 0
                                ? {
                                    await setDefaultCarToDisplay(vehiculesInfoFetched.elementAt(listViewIndex),
                                            vehiculesInfoFetched, widget.updateDashboardCar)
                                        .whenComplete(() =>
                                            widget.updateDashboardCar(newlySelectedCarModel, newlySelectedCarBrand)),
                                  }
                                : null;
                          },
                          child: Card(
                              shadowColor: const Color(0xff7986CB),
                              elevation: 10,
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
                                              vehiculesInfoFetched.elementAt(listViewIndex)['Other Details']
                                                  ['Reg. Country ISO'],
                                              width: 120,
                                              height: 20,
                                            ),
                                            Align(
                                              child: FittedBox(
                                                child: Text(
                                                  vehiculesInfoFetched.elementAt(listViewIndex)['Other Details']
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
                                    //LICENSEPLATE + logo + MODELDETAIL
                                    flex: 6,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Expanded(flex: 2, child: showVehiculeLogo(vehiculesInfoFetched, listViewIndex)),
                                        FittedBox(
                                          child: Text(
                                              getAllLicensePlates(vehiculesInfoFetched).elementAt(listViewIndex),
                                              style: const TextStyle(
                                                  letterSpacing: 2.0,
                                                  fontSize: 25,
                                                  fontFamily: 'OpenSans',
                                                  fontWeight: FontWeight.w900)),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: SizedBox(
                                            width: 70,
                                            child: FittedBox(
                                              child: Text(
                                                  getVehiculeModelDetail(vehiculesInfoFetched).elementAt(listViewIndex),
                                                  style: const TextStyle(
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
                                  Flexible(
                                    //CITY CODE AND YEAR
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
                                                  vehiculesInfoFetched.elementAt(listViewIndex)['Other Details']
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
                                                  vehiculesInfoFetched
                                                      .elementAt(listViewIndex)['Specs']['Registration Year']
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
                  ]))),
    );
  }

  List<String> getAllVehiculesBrands(List<QueryDocumentSnapshot<Map<String, dynamic>>> vehiculesInfoFetched) {
    List<String> allVehiculesBrands =
        []; //went from Set to List because user can have cars with same brand but model detail and licene p numbers will always be unique so will need a Set

    //contains is case sensitive so be careful
    for (var element in vehiculesInfoFetched) {
      element['Type'] == "Car" ? allVehiculesBrands.add(element.data()['Specs']['Brand']) : null;
    }

    debugPrint("ALL BRANDS OF CURRENT USER $allVehiculesBrands");
    return allVehiculesBrands.toList();
  }

  buildCarousel(/* List<Widget> carSlider, */ List<QueryDocumentSnapshot<Map<String, dynamic>>> vehiculesInfoFetched,
      [int newValue = 0]) {
    return Container(
      margin: const EdgeInsets.only(left: 15, right: 15),
      height: 250,
      width: MediaQuery.of(context).size.width * 0.64,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Flexible(
          child: SizedBox(
            child: Row(children: [
              Flexible(
                child: RawScrollbar(
                  minOverscrollLength: 8,
                  scrollbarOrientation: ScrollbarOrientation.bottom,
                  thumbColor: Theme.of(context).primaryColor,
                  radius: const Radius.circular(15),
                  thumbVisibility: true,
                  trackVisibility: true,
                  controller: infoListViewController,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 5, 0, 15),
                    child: ListView.separated(
                        separatorBuilder: (BuildContext context, int index) {
                          return const SizedBox(width: 20);
                        },
                        controller:
                            infoListViewController, //DO NOT REMOVE. LISTVIEW AND SCROLLBAR MUST SHARE THE SAME CONTROLLER OR YOU'LL GET AN ERROR
                        itemCount: vehiculesInfoFetched.length, //4,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          debugPrint("INDEXES $index");
                          Iterable<Widget> carSlider = getAllLicensePlates(vehiculesInfoFetched)
                              .map((e) => getCardForSlider(vehiculesInfoFetched, index));
                          debugPrint("CAROUSEL LEGNTH: ${carSlider.length}");

                          final item = carSlider.elementAt(index);

                          return item;
                        }),
                  ),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(
          height: 30,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Visibility(
                visible: singleTapVehiculeSelected ? true : false,
                child: editingVehiculeButtons(
                    'Edit',
                    Icons.edit,
                    Colors.blue,
                    vehiculesInfoFetched.elementAt(selectedVehiculeIndex),
                    vehiculesInfoFetched)), //passthevdehicule to edit as an argument with onTap (onTap allows to select a vehicule only)
            editingVehiculeButtons(
                'Add', Icons.add, Colors.green, vehiculesInfoFetched.elementAt(0), vehiculesInfoFetched),
            Visibility(
              visible: singleTapVehiculeSelected ? true : false,
              child: editingVehiculeButtons('Remove', Icons.remove, Colors.red,
                  vehiculesInfoFetched.elementAt(selectedVehiculeIndex), vehiculesInfoFetched),
            ) //passthevdehicule to edit as an argument for
          ],
        )
      ]),
    );
  }

  showVehiculeLogo(
//named like this because all vehicules logos and brands are the same, be it for a car or motorcycle
      List<QueryDocumentSnapshot<Map<String, dynamic>>> vehiculesInfoFetched,
      int listViewIndex) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection("carBrandLogos").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Text(''); //Text('Loading brand logos');
          } else {
            List<QueryDocumentSnapshot<Map<String, dynamic>>> allVehiculesTypesLogosFetched = snapshot.data!.docs;
            var currentVehiculeLogoInfo = allVehiculesTypesLogosFetched.where((element) {
              return element.data()['Brand Info']['Name'].toString().toLowerCase() ==
                  getAllVehiculesBrands(vehiculesInfoFetched).elementAt(listViewIndex).toLowerCase();

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

            debugPrint("Currently displayed vehicule's logo info: ${currentVehiculeLogoInfo.first.data()}");
            return CircleAvatar(
                backgroundColor: Colors.transparent,
                child: Image.asset(
                  currentVehiculeLogoInfo.first.data()['Brand Info']['Logo'],
                  width: 40,
                  height: 40,
                ));
          }
        });
  }

  showTotalRegCars(vehiculesInfoFetched) {
/* USE THIS IN CASE NETWORK EXCEPTION AGAIN
Future<String> getCountryName() async {
    Position position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    debugdebugPrint('location: ${position.latitude}');
    final coordinates = new Coordinates(position.latitude, position.longitude);
    var addresses = await Geocoder.local.findAddressesFromCoordinates(coordinates);
    var first = addresses.first;
    return first.countryName; // this will return country name
} */

    return SizedBox(
      height: 100,
      width: double.maxFinite,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                vehiculesInfoFetched.isEmpty
                    ? Container()
                    : FadeTransition(
                        opacity: _animationController,
                        child: GestureDetector(
                            onTap: () async {
                              await showDialog(
                                  context: context,
                                  builder: (context) {
                                    return ThemeHelper().alartDialog(
                                        'Description',
                                        'Double-tap on any of the license plates to set as default car; single tap to select and delete or edit.',
                                        context);
                                  });
                            },
                            child: const Icon(
                              Icons.info,
                              size: 25,
                              color: Colors.indigo,
                            )),
                      ),
                Align(
                  child: FittedBox(
                      child: Text(vehiculesInfoFetched.isEmpty
                          ? "No car currently registered."
                          : ' You have ${vehiculesInfoFetched.length} registered car(s).')),
                ),
              ],
            ),
          ),
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
    Set<String> carLogosAssets = {};
    for (var asset in allAssets) {
      if (asset.toString().contains("carLogos")) {
        carLogosAssets.add(asset);
      }
    }
    debugPrint("PATH: $carLogosAssets");
    return carLogosAssets;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> addVehiculeInfoToFirebase(Map<String, dynamic> formRes) {
    CollectionReference vehiculesCollectionRef = myDB.collection("users/${currentUser!.uid}/vehicules");
    WriteBatch batch = myDB.batch();
    myDB.collection("users/${currentUser!.uid}/vehicules").get().then((value) async {
      if (value.docs.isEmpty) {
        myDB.doc("users/${currentUser!.uid}").collection("vehicules").add({'initialized': true});
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
              'Reg. Country ISO':
                  EmojiParser().unemojify(realCountryValue).split("-").last.split(':').first.toUpperCase(),
            },
            'Currently Selected': false
          });
      await batch.commit().whenComplete(() => debugPrint("CAR SUCCESSFULLY ADDED IN FIREBASE"));

      await myDB.collection("users/${currentUser!.uid}/vehicules").get().then((value) async {
        var firstInitializedDoc = value.docs.where((element) => element.data().keys.contains('initialized'));

        firstInitializedDoc.isNotEmpty ? await vehiculesCollectionRef.doc(firstInitializedDoc.first.id).delete() : null;
      });
    });
    return myDB.collection("users/${currentUser!.uid}/vehicules").get();
  }

  registerOrEditCarForm(
      {required String action, required QueryDocumentSnapshot<Map<String, dynamic>> vehiculeToEditOnly}) {
    // https://stackoverflow.com/questions/71792773/how-to-pop-out-double-alert-message/
    List<String> carOptions = [];
    getDirectory().then((value) {
      fetchedCarLogosAssets.addAll(value);
      for (var single in fetchedCarLogosAssets) {
        var carBrand = single.split('/').toList().elementAt(3).toUpperCase().split('.').first.toString();
        String carBrandFormatted = carBrand[0].toUpperCase() + carBrand.substring(1).toLowerCase();
        carOptions.add(carBrandFormatted);
      }
      carOptions.add('OTHER');
    });
    bool cityIsoHasError = false,
        carBrandHasError = false,
        licensePlateHasError = false,
        modelDetailHasError = false,
        yearHasError = false,
        brandFieldInitiallyEmpty = true,
        cityIsoFieldInitiallyEmpty = true,
        licensePlateFieldInitiallyEmpty = true,
        modelDetailFieldInitiallyEmpty = true,
        yearFieldInitiallyEmpty = true,
        noCountryCityReselectedDuringEdit = false,
        showEditingCarUI = action == 'editCar' ? true : false;

    // ignore: unused_element
    void onChanged(dynamic val) => debugPrint(val.toString());
    final formKey = GlobalKey<FormBuilderState>();
    //https://www.iso.org/obp/ui#iso:code:3166:SN
    return showDialog(
        barrierDismissible: false,
        useRootNavigator: false,
        context: context,
        builder: (dialcontext) => StatefulBuilder(builder: (dialcontext, setState) {
              return AlertDialog(
                title: showEditingCarUI
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          CircleAvatar(
                            backgroundColor: Colors.amber,
                            radius: 10,
                            child: Icon(
                              Icons.mode_edit,
                              size: 15,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text('Editing car details'),
                        ],
                      )
                    : Container(),
                scrollable: true,
                content: GestureDetector(
                  onTap: () {
                    FocusScope.of(context).requestFocus(FocusNode());
                  },
                  child: SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      children: [
                        !noCountryCityReselectedDuringEdit
                            ? Container()
                            : const SizedBox(
                                height: 25,
                                child: Text(
                                  "Please Select Reg.Country and Reg.City.",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                    fontFamily: 'OpenSans',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                        showEditingCarUI
                            ? Container()
                            : Text(
                                "Please refer to the license plate model below and fill the form with your car's license plate information.",
                                style: TextStyle(
                                  color: Colors.indigo.shade400,
                                  fontSize: 15,
                                  fontFamily: 'OpenSans',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                        const SizedBox(height: 20),
                        showEditingCarUI
                            ? Container()
                            : SizedBox(
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
                                              padding: const EdgeInsets.only(left: 5, right: 5),
                                              color: const Color.fromARGB(255, 11, 73, 150),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                crossAxisAlignment: CrossAxisAlignment.center,
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
                                                          fontWeight: FontWeight.w900,
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
                                          flex: 8,
                                          child: Container(
                                            margin: const EdgeInsets.only(left: 10),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                                              children: const [
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
                                                            fontWeight: FontWeight.w500)),
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
                                              padding: const EdgeInsets.only(left: 5, right: 5),
                                              color: Colors.transparent,
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: const [
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
                                                          fontWeight: FontWeight.bold,
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
                        /*  showEditingCarUI
                            ? Container()
                            :  */
                        SizedBox(
                          child: SelectState(
                            style: realCountryValue.contains("Reg.") || realStateCityValue.contains("Reg.")
                                ? const TextStyle(color: Color.fromARGB(163, 0, 0, 0))
                                : const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.only(top: 8, bottom: 8),
                            ),
                            onCityTap: () {
                              debugPrint("CITY TAPPED ");
                            },
                            onCountryChanged: (value) {
                              debugPrint("CHANGED COUNTRY $value");
                              setState(() {
                                realCountryValue = value;
                              });
                            },
                            onStateChanged: (value) {
                              debugPrint("CHANGED Cstate $value");

                              setState(() {
                                realStateCityValue = value;
                              });
                            },
                            onCityChanged: (value) {
                              debugPrint("CHANGED CITY $value");
                              setState(() {
                                realCityDepValue = value;
                              });
                            },
                            onCityLengthChanged: (int value) {
                              debugPrint("CHANGED CITY LENGTH $value");
                              setState(() {
                                totalCities = value;
                              });
                            },
                            onStateLengthChanged: (int value) {
                              debugPrint("CHANGED STATE LENGTH $value");
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
                            debugPrint("USER INPUT FROM FORM ${formKey.currentState!.value.toString()}");
                          },
                          autovalidateMode: AutovalidateMode.disabled,
                          skipDisabled: true,
                          child: Column(
                            children: [
                              FormBuilderTextField(
                                initialValue: showEditingCarUI
                                    ? vehiculeToEditOnly.data()['Other Details']['Reg. City ISO']
                                    : null,
                                maxLength: 3,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp("[A-Z*]*"), replacementString: ''),
                                  FilteringTextInputFormatter.deny(RegExp(r'[/\\0-9]')),
                                ],
                                textCapitalization: TextCapitalization.characters,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                name: 'city iso',
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.only(bottom: 15, top: 15),
                                  counterStyle: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 8,
                                    height: 0.2,
                                  ),
                                  hintText: 'Example for Dakar : DK',
                                  labelStyle: cityIsoFieldInitiallyEmpty ? null : customlabelStyleAddCar,
                                  labelText: 'City ISO-3166 code',
                                  suffixIcon: cityIsoHasError == true
                                      ? const Icon(Icons.error, color: Colors.red)
                                      : cityIsoFieldInitiallyEmpty
                                          ? null
                                          : const Icon(Icons.check, color: Colors.green),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    cityIsoFieldInitiallyEmpty = false;
                                    cityIsoHasError = !(formKey.currentState?.fields['city iso']?.validate() ?? false);
                                  });
                                },
                                // valueTransformer: (text) => num.tryParse(text),
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(),
                                  FormBuilderValidators.match("[A-Z*]{2,3}", errorText: "2-3 letters required."),
                                  FormBuilderValidators.max(70),
                                ]),
                                //initialValue: '?',
                                keyboardType: TextInputType.name,
                                textInputAction: TextInputAction.next,
                              ),

                              FormBuilderDropdown<String>(
                                initialValue: showEditingCarUI ? vehiculeToEditOnly.data()['Specs']['Brand'] : null,
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
                                          : brandFieldInitiallyEmpty == false && carBrandHasError == false
                                              ? const Icon(
                                                  Icons.check,
                                                  color: Colors.green,
                                                  size: 25,
                                                )
                                              : null,
                                  hintText: 'Select A Brand',
                                ),
                                validator: FormBuilderValidators.compose([FormBuilderValidators.required()]),
                                items: carOptions
                                    .map((brand) => DropdownMenuItem(
                                          alignment: AlignmentDirectional.centerStart,
                                          value: brand,
                                          child: Text(brand),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    brandFieldInitiallyEmpty = false;
                                    carBrandHasError =
                                        !(formKey.currentState?.fields['car brand']?.validate() ?? false);
                                  });
                                },
                                valueTransformer: (val) => val?.toString(),
                              ),
                              //LICENSE PLATE FIELD
                              FormBuilderTextField(
                                initialValue:
                                    showEditingCarUI ? vehiculeToEditOnly.data()['Specs']['License Plate N°'] : null,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(licensePlatePattern), replacementString: ''),
                                ],
                                maxLength: 8,
                                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                                textCapitalization: TextCapitalization.characters,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                name: 'license plate',
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.only(bottom: 15, top: 15),
                                  counterStyle: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 8,
                                    height: 0.2,
                                  ),
                                  hintText: 'Your car lincense plate',
                                  labelText: 'License Plate',
                                  suffixIcon: licensePlateHasError
                                      ? const Icon(Icons.error, color: Colors.red)
                                      : licensePlateFieldInitiallyEmpty
                                          ? null
                                          : const Icon(Icons.check, color: Colors.green),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    licensePlateFieldInitiallyEmpty = false;
                                    licensePlateHasError =
                                        !(formKey.currentState?.fields['license plate']?.validate() ?? false);
                                  });
                                },
                                // valueTransformer: (text) => num.tryParse(text),
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(),
                                  FormBuilderValidators.match("[A-Z0-9]{5,8}", errorText: "5-8 characters needed."),
                                ]),
                                //initialValue: '?',
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.next,
                              ),

                              //MODEL DETAIL FIELD
                              FormBuilderTextField(
                                initialValue:
                                    showEditingCarUI ? vehiculeToEditOnly.data()['Specs']['Model Detail'] : null,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(modelDetailPattern), replacementString: ''),
                                ],

                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                textCapitalization: TextCapitalization.sentences,
                                name: 'model detail',
                                decoration: InputDecoration(
                                  hintText: 'Car Model Details',
                                  labelText: 'Model Detail',
                                  suffixIcon: modelDetailHasError
                                      ? const Icon(Icons.error, color: Colors.red)
                                      : modelDetailFieldInitiallyEmpty
                                          ? null
                                          : const Icon(Icons.check, color: Colors.green),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    modelDetailFieldInitiallyEmpty = false;
                                    modelDetailHasError =
                                        !(formKey.currentState?.fields['model detail']?.validate() ?? false);
                                  });
                                },
                                // valueTransformer: (text) => num.tryParse(text),
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(),
                                  FormBuilderValidators.match(modelDetailPattern),
                                  FormBuilderValidators.max(70),
                                ]),
                                //initialValue: '?',
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.next,
                              ),

                              //YEAR FIELD
                              FormBuilderTextField(
                                initialValue:
                                    showEditingCarUI ? vehiculeToEditOnly.data()['Specs']['Registration Year'] : null,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp('^[1-2][0-9]*'), replacementString: ''),
                                ],
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                maxLength: 4,
                                name: 'year',
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.only(bottom: 15, top: 15),
                                  counterStyle: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 8,
                                    height: 0.2,
                                  ),
                                  hintText: 'Year Of First Registration',
                                  labelText: 'Year',
                                  suffixIcon: yearHasError
                                      ? const Icon(Icons.error, color: Colors.red)
                                      : yearFieldInitiallyEmpty
                                          ? null
                                          : const Icon(Icons.check, color: Colors.green),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    yearFieldInitiallyEmpty = false;
                                    yearHasError = !(formKey.currentState?.fields['year']?.validate() ?? false);
                                  });
                                },
                                // valueTransformer: (text) => num.tryParse(text),
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(),
                                  FormBuilderValidators.numeric(),
                                  FormBuilderValidators.match('^([1-2]+)([0-9]){3}',
                                      errorText: '4 digits required.'), //validator.match is diff from allow
                                  FormBuilderValidators.max(DateTime.now().year),
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
                                  //print("OK DUDE $realCountryValue  èè $realCityDepValue  $realStateCityValue");
                                  if (realCountryValue == 'Select Reg. Country' &&
                                      realCityDepValue == "Select Reg. City/Department") {
                                    setState(() => noCountryCityReselectedDuringEdit = true);
                                    print("CAN'T PROCEED");
                                    //showSnackBarText("CAN'T PROCEED");
                                  } else {
                                    setState(() => noCountryCityReselectedDuringEdit = false);
                                    if (formKey.currentState?.saveAndValidate() ?? false) {
                                      formFetchedInf.addAll(formKey.currentState!.value);
                                      debugPrint("FETCHED FORM RESULT $formFetchedInf");

                                      formFetchedInf.addAll({
                                        'reg country': realCountryValue.split("    ").last,
                                        'reg city': realStateCityValue,
                                      });

                                      debugPrint("FORM VALIDATION SUCCESS ${formKey.currentState!.value}");
                                      showEditingCarUI
                                          ? await updateVehiculeInfoFirebase(formFetchedInf, vehiculeToEditOnly)
                                              .then((fireSnap) {
                                              Future.delayed(const Duration(seconds: 2)).then((value) {
                                                Navigator.of(context).pop('CAR INFO UPDATED');
                                                showSnackBarText("Car info updated successfully!");
                                              });
                                            })
                                          : await addVehiculeInfoToFirebase(formFetchedInf).then((fireSnap) {
                                              Future.delayed(const Duration(seconds: 2)).then((value) {
                                                Navigator.of(context).pop('NEW CAR ADDED');
                                                showSnackBarText("Car added successfully");
                                              });
                                            });
                                    } else {
                                      debugPrint(formKey.currentState?.value.toString());
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

                                      realCountryValue = 'Select Reg. Country';
                                      realStateCityValue = 'Select Reg. State/City';
                                    },
                                    // color: Theme.of(context).colorScheme.secondary,
                                    child: Text(
                                      'Reset',
                                      style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                                    )))
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            })).then((value) {
      if (value == 'NEW CAR ADDED' || value == "CAR INFO UPDATED") {
        myDB.collection("users/${currentUser!.uid}/vehicules").get().then((snapshotV) async {
          setState(() {});
        });
      } else {
        debugPrint("HERE WE GO");
      }
    });
  }

  getDisplayVehiculeStatusColor(String status) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
          color: status == 'selected' ? Colors.blue : Colors.yellow, //for unbookable as it's already past datetime.now
          shape: BoxShape.circle),
    );
  }

  Future<bool> setDefaultCarToDisplay(
      QueryDocumentSnapshot<Map<String, dynamic>> newlySelectedVehicule,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> vehiculesInfoFetched,
      Function(String carModelFromPanel, String carBrandFromPanel) updateDashboardCar) async {
    await myDB
        .collection("users/${currentUser!.uid}/vehicules")
        .doc(newlySelectedVehicule.id)
        .update({'Currently Selected': true});
    var previouslySelectedCar = vehiculesInfoFetched.where((element) => element.data()['Currently Selected'] == true);
    await myDB
        .collection("users/${currentUser!.uid}/vehicules")
        .doc(previouslySelectedCar.first.id)
        .update({'Currently Selected': false}).then((value) {
      setState(() {
        newlySelectedCarModel = newlySelectedVehicule.data()['Specs']['Model Detail'].toString();
        newlySelectedCarBrand = newlySelectedVehicule.data()['Specs']['Brand'].toString().toLowerCase();
      });
    });
    return true;
  }

  editingVehiculeButtons(
      String label,
      IconData icon,
      MaterialColor iconColor,
      QueryDocumentSnapshot<Map<String, dynamic>> selectedVehiculeToEdit,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> vehiculesInfoFetched) {
    return Column(
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            elevation: 5,
            backgroundColor: Colors.white,
            shape: const CircleBorder(),
          ),
          onPressed: () async {
            setState(() {
              /*   addCarIconPressed = true;
                    callSelectVehiculeAfterAdd = true; */
            });
            label == 'Add'
                ? await registerOrEditCarForm(action: "registerCar", vehiculeToEditOnly: selectedVehiculeToEdit)
                : label == 'Remove'
                    ? {
                        await removeCarFromFirebase(selectedVehiculeToEdit).then((carRemoveResult) {
                          carRemoveResult == 'REMOVE CAR' ? postCarDeletionUpdate(vehiculesInfoFetched) : null;
                        })
                      }
                    : await registerOrEditCarForm(
                        action: "editCar",
                        vehiculeToEditOnly: selectedVehiculeToEdit); //editCarInfo(selectedVehiculeToEdit);
          },
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        SizedBox(
          child: Align(
            child: FittedBox(
                child: Text(
              label,
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
    );
  }

  Future<String> removeCarFromFirebase(QueryDocumentSnapshot<Map<String, dynamic>> selectedVehiculeToEdit) async {
    return await showDialog(
      barrierDismissible: true,
      useRootNavigator: false,
      context: context,
      builder: (dialcontext) => StatefulBuilder(builder: (dialcontext, setState) {
        return AlertDialog(
          title: const Text("Removal Confirmation"),
          content: const Text("The selected vehicule will be permanently deleted if you proceed."),
          actions: [
            TextButton(
              style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.black38)),
              onPressed: () {
                Navigator.of(context).pop("REMOVE CAR");
              },
              child: const Text(
                "OK",
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.black38)),
              onPressed: () {
                Navigator.of(context).pop('CANCEL REMOVAL');
              },
              child: const Text(
                "CANCEL",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      }),
    ).then((carAction) async {
      print("CAR ACTION: $carAction");
      if (carAction == 'REMOVE CAR') {
        await myDB.collection("users/${currentUser!.uid}/vehicules").doc(selectedVehiculeToEdit.id).delete();
        setState(() {
          isVehiculeDeleted = true;
        });

        showSnackBarText('Car successfully removed!');
      }
      return carAction;
    });
  }

  postCarDeletionUpdate(vehiculesInfoFetched) {
    if (isVehiculeDeleted && selectedVehiculeIndex == 0 && vehiculesInfoFetched.length - 1 > 0) {
      // meaning the default vehicule was deleted, then set the second element to selected as it's gonna become the first one after everything is updated)
      myDB
          .collection("users/${currentUser!.uid}/vehicules")
          .doc(vehiculesInfoFetched.elementAt(1).id)
          .update({'Currently Selected': true});
    }
    vehiculesInfoFetched.length - 1 > 0
        ? selectedVehiculeIndex == 0
            ? widget.updateDashboardCar(vehiculesInfoFetched.elementAt(1).data()['Specs']['Model Detail'].toString(),
                vehiculesInfoFetched.elementAt(1).data()['Specs']['Brand'].toString().toLowerCase())
            : widget.updateDashboardCar(vehiculesInfoFetched.first.data()['Specs']['Model Detail'].toString(),
                vehiculesInfoFetched.first.data()['Specs']['Brand'].toString().toLowerCase())
        : widget.updateDashboardCar('', 'dacia');

    isVehiculeDeleted = false;
  }

  editCarInfo(QueryDocumentSnapshot<Map<String, dynamic>> selectedVehiculeToEdit) async {
    return showDialog(
      barrierDismissible: true,
      useRootNavigator: false,
      context: context,
      builder: (dialcontext) => StatefulBuilder(builder: (dialcontext, setState) {
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
                    children: const [],
                  )),
            ),
          ),
        );
      }),
    );
  }

  Future<String> updateVehiculeInfoFirebase(
      Map<String, dynamic> formFetchedInf, QueryDocumentSnapshot<Map<String, dynamic>> vehiculeToEditOnly) async {
    Map<String, dynamic> newData = ({
      'Type': 'Car',
      'Specs': {
        'Brand': formFetchedInf['car brand'],
        'Registration City': formFetchedInf['reg city'],
        'Registration Country': formFetchedInf['reg country'],
        'Color': 'White',
        'License Plate N°': formFetchedInf['license plate'],
        'Model Detail': formFetchedInf['model detail'],
        'Registration Year': formFetchedInf['year']
      },
      'History': {
        'Overall Parking Hours': 0,
        'Total Bookings': 0,
      },
      'Other Details': {
        'Reg. City ISO': formFetchedInf['city iso'],
        'Reg. Country ISO': EmojiParser().unemojify(realCountryValue).split("-").last.split(':').first.toUpperCase(),
      },
      'Currently Selected': false
    });
    await myDB.collection("users/${currentUser!.uid}/vehicules").doc(vehiculeToEditOnly.id).update(newData);
    return 'ok';
  }
  /* if (value.docs.isEmpty) {
        myDB.doc("users/${currentUser!.uid}").collection("vehicules").add({'initialized': true});
      } */
/* 
      batch.set(
          //maybe add timestamp later to know when the car was added
          vehiculesCollectionRef.doc(),
          {
            'Type': 'Car',
            'Specs': {
              'Brand': formFetchedInf['car brand'],
              'Registration City': formFetchedInf['reg city'],
              'Registration Country': formFetchedInf['reg country'],
              'Color': 'White',
              'License Plate N°': formFetchedInf['license plate'],
              'Model Detail': formFetchedInf['model detail'],
              'Registration Year': formFetchedInf['year']
            },
            'History': {
              'Overall Parking Hours': 0,
              'Total Bookings': 0,
            },
            'Other Details': {
              'Reg. City ISO': formRes['city iso'],
              'Reg. Country ISO':
                  EmojiParser().unemojify(realCountryValue).split("-").last.split(':').first.toUpperCase(),
            },
            'Currently Selected': false
          },);
      await batch.commit().whenComplete(() => debugPrint("CAR SUCCESSFULLY ADDED IN FIREBASE"));

      await myDB.collection("users/${currentUser!.uid}/vehicules").get().then((value) async {
        var firstInitializedDoc = value.docs.where((element) => element.data().keys.contains('initialized'));

        firstInitializedDoc.isNotEmpty ? await vehiculesCollectionRef.doc(firstInitializedDoc.first.id).delete() : null;
      });
    });
    return myDB.collection("users/${currentUser!.uid}/vehicules").get(); */

  //
}
