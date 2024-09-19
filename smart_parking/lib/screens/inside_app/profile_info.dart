// ignore_for_file: avoid_unnecessary_containers, avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_parking/screens/inside_app/home.dart';
import 'package:smart_parking/services/firebase/firestore_service.dart';
import 'package:smart_parking/styling/styling.dart';

import 'for_profile_info/user_info_header.dart';
import 'for_profile_info/profile_info_big_card.dart';
import 'for_profile_info/profile_info_mini_cards.dart';

// ignore: must_be_immutable
class ProfileInfo extends StatefulWidget {
  String profilePic;
  final Function customFunction;
  bool status;
  ProfileInfo({Key? key, required this.profilePic, required this.customFunction, required this.status})
      : super(key: key);

  @override
  State<ProfileInfo> createState() => _ProfileInfoState();
}

class _ProfileInfoState extends State<ProfileInfo> {
  @override
  void initState() {
    widget.profilePic = currentUser!.photoURL.toString();
    super.initState();
  }

  User? currentUser = FirebaseAuth.instance.currentUser;
  String paramProfilePic = '';
  FirestoreUserService firestoreService = FirestoreUserService();

  //

  opaqueImageStateSetter(String newOpaqueImage) {
    /*  if (newOpaqueImage == '') {
      print("HERE OPAQUE FUNC");
    } else {
      setState(() {
        currentUser!.updatePhotoURL(newOpaqueImage);
        paramProfilePic = newOpaqueImage;
      });
    } */
  }

  @override
  Widget build(BuildContext context) {
    /* THIS WILL BE NEEDED :
 https://stackoverflow.com/questions/61797829/how-can-i-put-a-counter-in-my-flutter-application-that-increases-everyday-a-user
 https://stackoverflow.com/questions/62058809/how-to-get-the-number-of-login-of-the-user-in-the-app-in-a-day 
 https://github.com/mitesh77/Best-Flutter-UI-Templates/blob/master/best_flutter_ui_templates/lib/fitness_app/bottom_navigation_view/bottom_bar_view.dart
 */

    test() {
      if (widget.status == false) {
        print("HOMESTATE STSTUS FALSE ");
        if (paramProfilePic == '' && widget.profilePic != "assets/images/no_profile_picture_grey.png") {
          print("THIS IS FROM TEST 1: ${widget.profilePic}");
          currentUser!.updatePhotoURL(widget.profilePic);
          return widget.profilePic;
        } else if (paramProfilePic == '' && widget.profilePic == "assets/images/no_profile_picture_grey.png") {
          print(
              "THIS IS FROM TEST 2: widget profile pic ${widget.profilePic} ________ curreUSERPP ${currentUser!.photoURL.toString()}");
          return currentUser!.photoURL.toString();
        } else {
          setState(() {
            widget.profilePic = paramProfilePic;
          });
          print("THIS IS FROM TEST 3: ${widget.profilePic}");
          HomeState().getProfilePic(paramProfilePic);
          return paramProfilePic;
        }
      } // problem not here
      else {
        print("HOMESTATE STSTUS TRUE");
        print("THIS IS FROM TEST 1: ${widget.profilePic}");
        return widget.profilePic; //returns if for opaquepic
      }
    }

    final screenHeight = MediaQuery.of(context).size.height;

    print("THIS IS WIDGET PROFILE : ${widget.profilePic}");
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              Expanded(
                flex: 4,
                child: Stack(
                  children: <Widget>[
                    OpaqueImage(imageUrl: test(), customFunction: opaqueImageStateSetter),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  color: Colors.white,
                                  onPressed: () => Scaffold.of(context).openDrawer(),
                                ),
                                const Text(
                                  "My Profile",
                                  style: headingTextStyle,
                                ),
                              ]),
                            ),
                            UserInfoHeader(
                              avatarImage: paramProfilePic,
                              customFunction: widget.customFunction,
                              status: widget.status,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.only(top: 50),
                  color: Colors.white,
                  child: Table(
                    children: [
                      TableRow(
                        children: [
                          const ProfileInfoBodyCard(
                            firstText: "13",
                            secondText: "New matches",
                            icon: Icon(
                              Icons.star,
                              size: 32,
                              color: blueColor,
                            ),
                          ),
                          ProfileInfoBodyCard(
                            firstText: "21",
                            secondText: "Unmatched me",
                            icon: Image.asset(
                              "assets/icons/sad_smiley.png",
                              width: 32,
                              color: blueColor,
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          ProfileInfoBodyCard(
                            firstText: "264",
                            secondText: "All matches",
                            icon: Image.asset(
                              "assets/icons/checklist.png",
                              width: 32,
                              color: blueColor,
                            ),
                          ),
                          const ProfileInfoBodyCard(
                            firstText: "42",
                            secondText: "Rematches",
                            icon: Icon(
                              Icons.refresh,
                              size: 32,
                              color: blueColor,
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          const ProfileInfoBodyCard(
                            firstText: "404",
                            secondText: "Profile Visitors",
                            icon: Icon(
                              Icons.remove_red_eye,
                              size: 32,
                              color: blueColor,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: const ProfileInfoBodyCard(
                              firstText: "42",
                              secondText: "Super likes",
                              icon: Icon(
                                Icons.favorite,
                                size: 32,
                                color: blueColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: screenHeight * (4 / 9) - 80 / 2,
            left: 16,
            right: 16,
            child: const SizedBox(
              height: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  ProfileInfoMiniCards(firstText: "54%", secondText: "Progress"),
                  SizedBox(
                    width: 10,
                  ),
                  ProfileInfoMiniCards(
                    hasImage: true,
                    imagePath: "assets/icons/pulse.png",
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  ProfileInfoMiniCards(firstText: "152", secondText: "Level"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OpaqueImage extends StatelessWidget {
  final String imageUrl;
  final Function customFunction;

  const OpaqueImage({Key? key, required this.imageUrl, required this.customFunction}) : super(key: key);
  assetOrNetworkImageOpaque(String imageUrl) {
    if (imageUrl.contains('assets/images')) {
      return Image.asset(
        imageUrl,
        width: double.maxFinite,
        height: double.maxFinite,
        fit: BoxFit.contain,
      );
    } else {
      return Image.network(
        imageUrl,
        width: double.maxFinite,
        height: double.maxFinite,
        fit: BoxFit.cover,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        assetOrNetworkImageOpaque(imageUrl),
        Container(
          color: primaryColorOpacity.withOpacity(0.22), //0.85 de base
        ),
      ],
    );
  }
}
