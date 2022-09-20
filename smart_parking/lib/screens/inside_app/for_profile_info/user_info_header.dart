// ignore_for_file: avoid_print

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_parking/services/firebase/firebase_storage.dart';
import 'package:smart_parking/services/firebase/firestore_service.dart';
//import 'package:smart_parking/services/location.dart';
import 'package:smart_parking/styling/styling.dart';

import 'radial_progress.dart';
//import 'rounded_image.dart';

class UserInfoHeader extends StatefulWidget {
  final String avatarImage;
  final Function customFunction;
  final bool status;
  const UserInfoHeader(
      {Key? key,
      required this.avatarImage,
      required this.customFunction,
      required this.status})
      : super(key: key);

  @override
  State<UserInfoHeader> createState() => _UserInfoHeaderState();
}

class _UserInfoHeaderState extends State<UserInfoHeader> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  FirestoreUserService firestoreService = FirestoreUserService();
  File? file;
  StorageService firebaseStorage = StorageService();
  // LocationService locationService = const LocationService();
  String userName = '';
  String avatarImageUploaded = '';

  uploadProfilePicture() async {
    // ignore: unused_local_variable
    String uploaded = '';
    try {
      var image = await ImagePicker().pickImage(source: ImageSource.gallery);
      print(image!.path);
      file = File(image.path);
      uploaded = await firebaseStorage
          .updloadFile(file!)
          .then((value) => avatarImageUploaded = value.toString());

//
      firestoreService.setUserProfileImage(
          currentUser!, avatarImageUploaded); //STOPPED HERE
      print('AVATAR UPLOADED : $avatarImageUploaded');
      currentUser!.updatePhotoURL(avatarImageUploaded);
      print(
          'CURRENT USER AVATAR UPLOADED : ${currentUser!.photoURL.toString()}');

//
      widget.customFunction(avatarImageUploaded);

      setState(() {
        avatarImageUploaded;
      });
    } catch (e) {
      print(e);
    }

    print("THIS IS AVATAR IMAGE WHILE UPLOADING : $avatarImageUploaded");
  }

//TheUploadIsNow working but I need to find a way to update the other pictures

  RoundedImage whichRoundedImage() {
    if (widget.status == false) {
      print("THIS IS FROM WHICH ROUNDED IMAGE STATUS : ${widget.status}");
      print("CAME FROM ROUNDED IMAGE SIGNUP");
      return RoundedImage(
        imagePath: avatarImageUploaded ==
                '' //explication : after calling the uploadProfilePic function, the currentUserProfile updated will be shown after refreshing the MyProfile page and the avatarImageUplo var will be empty again.
            ? currentUser!.photoURL.toString()
            : avatarImageUploaded,
        size: const Size.fromWidth(120.0),
      );
    } //
    else {
      print("CAME FROM ROUNDED IMAGE LOGIN VIEW ${widget.status}");
      return RoundedImage(
        imagePath: avatarImageUploaded ==
                '' //explication : after calling the uploadProfilePic function, the currentUserProfile updated will be shown after refreshing the MyProfile page and the avatarImageUplo var will be empty again.
            ? currentUser!.photoURL.toString()
            : avatarImageUploaded,
        size: const Size.fromWidth(120.0),
      );
    }

    //
    /* if (!HomeState().status) {
      print("THIS IS FROM WHICH ROUNDED IMAGE STATUS");
      print(HomeState().status);
      print("CAME FROM ROUNDED IMAGE SIGNUP");
      return RoundedImage(
        imagePath: avatarImageUploaded ==
                '' //explication : after calling the uploadProfilePic function, the currentUserProfile updated will be shown after refreshing the MyProfile page and the avatarImageUplo var will be empty again.
            ? currentUser!.photoURL.toString()
            : avatarImageUploaded,
        size: const Size.fromWidth(120.0),
      );
    } else {
      print("CAME FROM ROUNDED IMAGE LOGIN VIEW");

      return RoundedImage(
        imagePath: avatarImageUploaded ==
                '' //explication : after calling the uploadProfilePic function, the currentUserProfile updated will be shown after refreshing the MyProfile page and the avatarImageUplo var will be empty again.
            ? currentUser!.photoURL.toString()
            : avatarImageUploaded,
        size: const Size.fromWidth(120.0),
      );
    } */
  }

  @override
  Widget build(BuildContext context) {
    userName = currentUser!.displayName.toString();
    print(
        "THIS IS AVATAR IMAGE UPLOADED AGAIN AFTER REFESHING THE PROFILE PAGE (EMPTY string) $avatarImageUploaded: CurrUserProfileURL ${currentUser!.photoURL.toString()}");

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              RadialProgress(
                  width: 4, goalCompleted: 0.9, child: whichRoundedImage()),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 35.0,
                  height: 35.0,
                  decoration: const BoxDecoration(
                      color: Colors.deepOrange,
                      borderRadius: BorderRadius.all(Radius.circular(20))),
                  child: IconButton(
                    icon: const Icon(Icons.add_a_photo),
                    color: Colors.white,
                    iconSize: 18.0,
                    onPressed: uploadProfilePicture,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                userName,
                style: whiteNameTextStyle,
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          //locationService
        ],
      ),
    );
  }
}

class RoundedImage extends StatelessWidget {
  final String imagePath;
  final Size size;

  const RoundedImage({
    Key? key,
    required this.imagePath,
    this.size = const Size.fromWidth(120),
  }) : super(key: key);

  assetOrNetworkImage(String theImagePath) {
    if (theImagePath.contains('assets/images')) {
      return ClipOval(
        child: Image.asset(
          imagePath,
          width: size.width,
          height: size.width,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return ClipOval(
        child: Image.network(
          imagePath,
          width: size.width,
          height: size.width,
          fit: BoxFit.cover,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return assetOrNetworkImage(imagePath);
  }
}









/* // ignore_for_file: avoid_print

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_parking/services/firebase_storage.dart';
import 'package:smart_parking/styling/styling.dart';

import 'radial_progress.dart';
//import 'rounded_image.dart';

class UserInfoHeader extends StatefulWidget {
  final String avatarImage;
  const UserInfoHeader({Key? key, required this.avatarImage}) : super(key: key);

  @override
  State<UserInfoHeader> createState() => _UserInfoHeaderState();
}

class _UserInfoHeaderState extends State<UserInfoHeader> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  File? file;
  Storage firebaseStorage = Storage();
  String userName = '';
  String avatarImageBlank = 'assets/images/no_profile_picture_grey.png';
  String avatarImageUploaded = '';

  uploadProfilePicture() async {
    String uploaded = '';
    try {
      var image = await ImagePicker().pickImage(source: ImageSource.gallery);
      print(image!.path);
      file = File(image.path);
      uploaded = await firebaseStorage
          .updloadFile(file!)
          .then((value) => avatarImageUploaded = value.toString());
      print('AVATAR UPLOADED : $avatarImageUploaded');
      currentUser!.updatePhotoURL(avatarImageUploaded);
      print(
          'CURRENT USER AVATAR UPLOADED : ${currentUser!.photoURL.toString()}');

      setState(() {
        avatarImageUploaded;
      });
    } on Exception catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    userName = currentUser!.displayName.toString();
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              RadialProgress(
                width: 4,
                goalCompleted: 0.9,
                child: RoundedImage(
                  imagePath: currentUser!.photoURL.toString() == ''
                      ? avatarImageBlank
                      : currentUser!.photoURL.toString(),
                  size: const Size.fromWidth(120.0),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 35.0,
                  height: 35.0,
                  decoration: const BoxDecoration(
                      color: Colors.deepOrange,
                      borderRadius: BorderRadius.all(Radius.circular(20))),
                  child: IconButton(
                    icon: const Icon(Icons.add_a_photo),
                    color: Colors.white,
                    iconSize: 18.0,
                    onPressed: uploadProfilePicture,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                userName,
                style: whiteNameTextStyle,
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                "assets/icons/location_pin.png",
                width: 20.0,
                color: Colors.white,
              ),
              const Text(
                "  Location/Address",
                style: whiteSubHeadingTextStyle,
              )
            ],
          ),
        ],
      ),
    );
  }
}

class RoundedImage extends StatelessWidget {
  final String imagePath;
  final Size size;

  const RoundedImage({
    Key? key,
    required this.imagePath,
    this.size = const Size.fromWidth(120),
  }) : super(key: key);

  assetOrNetworkImage(String theImagePath) {
    if (theImagePath.contains('assets/images')) {
      return ClipOval(
        child: Image.asset(
          imagePath,
          width: size.width,
          height: size.width,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return ClipOval(
        child: Image.network(
          imagePath,
          width: size.width,
          height: size.width,
          fit: BoxFit.cover,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return assetOrNetworkImage(imagePath);
  }
}
 */