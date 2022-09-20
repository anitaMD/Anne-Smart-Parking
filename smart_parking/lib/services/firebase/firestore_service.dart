// ignore_for_file: avoid_print, prefer_typing_uninitialized_variables

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:smart_parking/models/inside_parking_info.dart';
import 'package:smart_parking/models/user.dart';

class FirestoreUserService {
  final CollectionReference _usersCollectionReference =
      FirebaseFirestore.instance.collection("users");

  Future createUser(UserProfile user) async {
    try {
      await _usersCollectionReference.doc(user.id).set(user.toJson());
      print('USER CREATED FROM FIRESTORE SERVICE');
    } catch (e) {
      return e;
    }
  }

  Future getUser(String uid) async {
    try {
      var userData = await _usersCollectionReference.doc(uid).get();
      print('${userData.data()}');
      Map<String, dynamic> data = userData.data() as Map<String, dynamic>;
      return data;
    } catch (e) {
      print(e);
    }
  }

  /* Future<UserProfile> getUser(String uid) async {
    try {
      var userData = await _usersCollectionReference.doc(uid).get();
      print('${userData.data()}');
      Map<String, dynamic> data = userData.data() as Map<String, dynamic>;
      UserProfile userProfile = UserProfile.fromData(data);
      return Future.value(userProfile);
    } catch (e) {
      print(e);
      return UserProfile(
          id: '', fullName: '', email: '', phoneNumber: '', userRole: '');
    }
  } */

  Future<String> getUserDisplayName(UserProfile user) async {
    String fullName = '';
    try {
      var userData = await _usersCollectionReference.doc(user.id).get();
      fullName = userData.get(user.fullName);
    } catch (e) {
      print(e);
    }
    return fullName;
  }

  Future getUserRole(User aUser) async {
    try {
      var userData = await _usersCollectionReference.doc(aUser.uid).get();
      Map<String, dynamic> data = userData.data() as Map<String, dynamic>;
      var theUserRole = data['userRole'];
      print(theUserRole);
      return theUserRole;
    } catch (e) {
      print(e);
      return e.toString();
    }
  } //

  Future getUserFullName(User aUser) async {
    try {
      var userData = await _usersCollectionReference.doc(aUser.uid).get();
      Map<String, dynamic> data = userData.data() as Map<String, dynamic>;
      var theUserName = data['fullName'];
      print(theUserName);
      return theUserName;
    } catch (e) {
      print(e);
      return e.toString();
    }
  } //

  Future getUserNumber(User aUser) async {
    try {
      var userData = await _usersCollectionReference.doc(aUser.uid).get();
      Map<String, dynamic> data = userData.data() as Map<String, dynamic>;
      var theUserNumber = data['phoneNumber'];
      print(theUserNumber);
      return theUserNumber;
    } catch (e) {
      print(e);
      return e.toString();
    }
  }

  Future getUserProfileImage(User aUser) async {
    try {
      var userData = await _usersCollectionReference.doc(aUser.uid).get();
      Map<String, dynamic> data = userData.data() as Map<String, dynamic>;
      var theUserProfileImage = data['profileImage'];
      print(theUserProfileImage);
      return theUserProfileImage;
    } catch (e) {
      print(e);
      return e.toString();
    }
  } //

  Future setUserProfileImage(User aUser, String uploadedImagePath) async {
    try {
      await _usersCollectionReference.doc(aUser.uid).set(
        {
          'profileImage': uploadedImagePath,
        },
        SetOptions(merge: true),
      );
      var userData = await _usersCollectionReference.doc(aUser.uid).get();
      Map<String, dynamic> data = userData.data() as Map<String, dynamic>;
      print(
          "THIS IS FROM FIRESTORE SERVICE SETFUNCTION ${data['profileImage']}");
    } catch (e) {
      print(e);
      return e.toString().toUpperCase();
    }
  } //

  getUserVehicules() {}

  Future updateUserData(
    String uid,
    String fullName,
    String phoneNumber,
    String email,
  ) async {
    return await _usersCollectionReference.doc(uid).set({
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
    });
  } //
}

///closing brackets

class FirestoreParkingLocationService {
  /*  InsideInfo insideParkingInfoClass =
      InsideInfo(availableSlots: 0, occupiedSlots: 0, totalSlotsNumber: 0); */
  final CollectionReference _locationsCollectionReference =
      FirebaseFirestore.instance.collection("locations");

  Map<String, dynamic> allParkingsDataSnapShot = {}, allParkingsInsideInfo = {};
  late Stream insideParkingInfSnapshot;
  String selectedParkingID = '';

////SPACE NEEDED

  Future<int> numberOfParkings() async {
    var allParkings;
    var right;
    try {
      await _locationsCollectionReference.get().then((value) {
        allParkings = value.size;
        print(
            "FROM FIRESTORE SERVICE PARKING : Number of parkings : $allParkings ");
        right = allParkings;

        return allParkings;
      });
      print("THATS RIGHT : $right");
      return right;
    } catch (e) {
      print(e);
      return 0;
    }
  } // */

  /*  Stream<List<InsideInfo>> getInsideParkingInfoData() {
    //FIND A WAY TO GET THE INSIDE PARKING INFO COLLECTION'S DOCUMENT FOR EACH PARKING

    _locationsCollectionReference.get().then((value) {
      for (var docum in value.docs) {
        final CollectionReference insideParkingInfoCollection =
            FirebaseFirestore.instance
                .collection("${docum.id}/insideParkingInformation");
        try {
          insideParkingInfSnapshot = insideParkingInfoCollection.snapshots();

          /* insideParkingInfoCollection.doc().get().then(
                (subcolletcion) => allParkingsInsideInfo
                    .addAll({docum.id: subcolletcion.data()}));
            return allParkingsInsideInfo; */
        } catch (e) {
          print(e);
          return {};
        }
      }
    });
    print(
        "INSIDEPARKINGINFOMAP RESULT MESSAGE FROM FIRESETORE SERVICE: $allParkingsInsideInfo");
    return insideParkingInfSnapshot.map((snapshot) => snapshot.docs
        .map((doc) =>
            InsideInfo.fromFirestore(doc.data() as Map<String, dynamic>))
        .toList());
    // return allParkingsInsideInfo;
  }

  */

  /*  Stream<List<InsideInfo>> insideParkingInfoStream() {
    CollectionReference insideParkingInfoCollection =
        _locationsCollectionReference;
    try {
      _locationsCollectionReference.get().then((value) {
        //Map<String, dynamic> testing = {};
        for (var docum in value.docs) {
          if (selectedParkingID == docum.id) {
            insideParkingInfoCollection = FirebaseFirestore.instance
                .collection("locations/${docum.id}/insideParkingInfo");
            insideParkingInfSnapshot = insideParkingInfoCollection.snapshots();
            print("SNAPSHOTS HERE $insideParkingInfSnapshot");
            return insideParkingInfSnapshot.map((snapshot) => snapshot.docs
                .map((doc) => InsideInfo.fromFirestore(
                    doc.data() as Map<String, dynamic>))
                .toList());
          }
          return {};
          /* insideParkingInfoCollection.doc().get().then(
                (subcolletcion) => allParkingsInsideInfo
                    .addAll({docum.id: subcolletcion.data()}));
            return allParkingsInsideInfo; */
          /* insideParkingInfoCollection
              .get()
              .then((value) => {
                    testing.addAll({
                      docum.id: value.docs
                          .map((singleParkingInfo) => singleParkingInfo.data())
                    }),
                    print("THIS IS THE TEST : ${testing.length}"),
                    print("THIS IS THE TEST LIST : $testing"),
                  }); */
        }
      });
    } catch (e) {
      print(e);
      return;
    }
  }
 */
  Future<Map<String, dynamic>> getParkingInfoData() async {
    try {
      await _locationsCollectionReference.get().then((value) {
        for (var docum in value.docs) {
          //keep everything starting after this comment as it was the original code
          var parkingData = docum
              .data(); //data is a map object so parkingData will be a map too
          print("FROM FIRESTORE SERVICE PARKING : Parking data : $parkingData");
          allParkingsDataSnapShot.addAll({docum.id: parkingData});
        }
      });
      print(
          "MAP RESULT MESSAGE FROM FIRESETORE SERVICE: $allParkingsDataSnapShot");
      return allParkingsDataSnapShot;
    } catch (e) {
      print(e);
      return {};
    }
  } // */

  /*  Future getParkingID() async {
    try {
      await _locationsCollectionReference.get().then((value) {
        for (var docum in value.docs) {
          var parkingID = docum.id;
          print("FROM FIRESTORE SERVICE PARKING : Parking ID : $parkingID");
          return parkingID;
        }
      });
    } catch (e) {
      print(e);
    }
  } // */

  Future<GeoPoint> getParkingLocationCoordinates(String parkingID) async {
    try {
      var parkingLocData =
          await _locationsCollectionReference.doc(parkingID).get();
      print('MESSAGE FROM SERVICE: ${parkingLocData.data()}');
      Map<String, dynamic> data = parkingLocData.data() as Map<String, dynamic>;
      var theParkingPositionCoordinates = data['Positions'];

      //Map<GeoPoint, dynamic> newData = theParkingPositionCoordinates.

      print(theParkingPositionCoordinates);
      return theParkingPositionCoordinates;
    } catch (e) {
      print(e);
      return const GeoPoint(0, 0);
    }
  } // */

} ///closing brackets

