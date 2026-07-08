// ignore_for_file: avoid_print, prefer_typing_uninitialized_variables,, avoid_function_literals_in_foreach_calls

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_parking/old/models/new_user.dart';
//import 'package:smart_parking/old/models/inside_parking_info.dart';
import 'package:smart_parking/old/models/user.dart';
import 'package:smart_parking/old/services/firebase/firebase_service.dart';

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

  Future createNewUser(NewUserProfile user) async {
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

  Future testgetUserFullName(User aUser) async {
    try {
      var userData = await _usersCollectionReference.doc(aUser.uid).get();
      Map<String, dynamic> data = userData.data() as Map<String, dynamic>;
      var theUserName = data['Full Name'];
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

  Future testgetUserProfileImage(User aUser) async {
    try {
      var userData = await _usersCollectionReference.doc(aUser.uid).get();
      Map<String, dynamic> data = userData.data() as Map<String, dynamic>;
      var theUserProfileImage = data['Profile Image'];
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

  void getUserVehicules() {}

  Future<bool> doesPhoneNumberAlreadyExist(
      {required String phoneNumber}) async {
    var result;
    try {
      await _usersCollectionReference.get().then((element) {
        var matchingPhone = element.docs.any((element1) {
          Map<String, dynamic> data = element1.data() as Map<String, dynamic>;
          //print("NUMBER EXISTSZSZ ${data['Phone Number'] == phoneNumber} ________ $phoneNumber");

          return data['Phone Number'] == phoneNumber;
        });
        matchingPhone
            ? print("NUMBER EXISTS IN THE DATABASE FROM FIRESTORE")
            : print("NUMBER DOES NOT EXISTS IN THE DATABASE FROM FIRESTORE");
        return matchingPhone;
      }).then((value) => result = value);

      return result;
    } catch (e) {
      print("EXCEPTION OCCURED");
      return false;
    }
  }

  Future<dynamic> doesEmailAlreadyExist({required String email}) async {
    bool result = false;
    try {
      await _usersCollectionReference.snapshots().any((element) {
        var matchingEmail = element.docs.any((element1) {
          Map<String, dynamic> data = element1.data() as Map<String, dynamic>;
          // print("NUMBER EXISTSZSZ ${data['Phone Number'] == phoneNumber}");

          return data['Email'] == email;
        });
        matchingEmail
            ? print("EMAIL EXISTS IN THE DATABASE FROM FIRESTORE")
            : print("EMAIL DOES NOT EXISTS IN THE DATABASE FROM FIRESTORE");
        return matchingEmail;
      }).then((value) => result = value);

      return result;
    } catch (e) {
      print("EXCEPTION OCCURED");
      return false;
    }
  }

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
}

///closing brackets

class FirestoreWalletService {
  var myDB = FirebaseFirestore.instance;
  var currentlySignedInUser = FirebaseService().currentlySignedInUser;

  Future<QuerySnapshot<Map<String, dynamic>>> initializeWalletDebitTopUp(
      User? currentlySIUser, String walletCollId) {
    //creating debits collection
    CollectionReference walletDebitCollection = myDB.collection(
        "users/${currentlySIUser?.uid}/wallet/$walletCollId/debits");
    WriteBatch batchDebit = myDB.batch(), batchTopUp = myDB.batch();

    myDB
        .collection("users/${currentlySIUser?.uid}/wallet/$walletCollId/debits")
        .get()
        .then((value) async {
      if (value.docs.isEmpty) {
        myDB
            .doc("users/${currentlySIUser?.uid}/wallet/$walletCollId")
            .collection("debits")
            .add({'initialized': true});
      }

      batchDebit.set(
          //maybe add timestamp later to know when the car was added
          walletDebitCollection.doc(),
          {
            'Debit Amount': 0,
            'RecipientParking ID': '',
            'RecipientParking Name': '',
            'TimeStamp': FieldValue.serverTimestamp(),
            'New Balance': 5000
          }); //{'Debit Amount': 0, 'RecipientParking ID': '', 'TimeStamp': FieldValue.serverTimestamp()});
      await batchDebit
          .commit()
          .whenComplete(() => debugPrint("DEBIT SUCCESSFULLY ADDED"));
      await myDB
          .collection(
              "users/${currentlySIUser?.uid}/wallet/$walletCollId/debits")
          .get()
          .then((value) async {
        var firstInitializedDoc = value.docs
            .where((element) => element.data().keys.contains('initialized'));
        firstInitializedDoc.isNotEmpty
            ? await walletDebitCollection
                .doc(firstInitializedDoc.first.id)
                .delete()
            : null;
      });
    });

    //CreatingTopUp collection

    CollectionReference walletTopUpCollection = myDB.collection(
        "users/${currentlySIUser?.uid}/wallet/$walletCollId/topUps");
    myDB
        .collection("users/${currentlySIUser?.uid}/wallet/$walletCollId/topUps")
        .get()
        .then((value) async {
      if (value.docs.isEmpty) {
        myDB
            .doc("users/${currentlySIUser?.uid}/wallet/$walletCollId")
            .collection("topUps")
            .add({'initialized': true});
      }

      batchTopUp.set(
          //maybe add timestamp later to know when the car was added
          walletTopUpCollection.doc(),
          {
            'TopUp Amount': 5000,
            'From': 'Your Smart Parking',
            'Type': 'Welcome Gift',
            'TimeStamp': FieldValue.serverTimestamp(),
            'New Balance': 5000
          });

      await batchTopUp
          .commit()
          .whenComplete(() => debugPrint("DEBIT SUCCESSFULLY ADDED"));

      await myDB
          .collection(
              "users/${currentlySIUser?.uid}/wallet/$walletCollId/topUps")
          .get()
          .then((value) async {
        var firstInitializedDoc = value.docs
            .where((element) => element.data().keys.contains('initialized'));
        firstInitializedDoc.isNotEmpty
            ? await walletTopUpCollection
                .doc(firstInitializedDoc.first.id)
                .delete()
            : null;
      });
    });

    return myDB.collection("users/${currentlySIUser?.uid}/wallet").get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> addUserWalletInfoToFirebase(
      User? currentlySIUser) {
    myDB
        .collection("users/${currentlySIUser?.uid}/wallet")
        .get()
        .then((value) async {
      if (value.docs.isEmpty) {
        myDB.doc("users/${currentlySIUser?.uid}").collection("wallet").add({
          'Balance': 5000,
          'Transactions': {
            'Top Ups': {'Total Entries': 1, 'IDs': <String>[]},
            'Debits': {'Total Entries': 0, 'IDs': <String>[]},
          },
        });
      }
    });

    return myDB.collection("users/${currentlySIUser?.uid}/wallet").get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> debitAfterBooking(
      User? currentlySIUser,
      String walletCollId,
      int bookingTotalToPay,
      String receivedID,
      linkedParkingNameAndInsideInfo) {
    //creating debits collection
    CollectionReference walletDebitCollection = myDB.collection(
        "users/${currentlySIUser?.uid}/wallet/$walletCollId/debits");
    WriteBatch batchDebit = myDB.batch();

    myDB
        .collection("users/${currentlySIUser?.uid}/wallet/$walletCollId/debits")
        .get()
        .then((value) async {
      if (value.docs.isEmpty) {
        myDB
            .doc("users/${currentlySIUser?.uid}/wallet/$walletCollId")
            .collection("debits")
            .add({'initialized': true});
      }
      int balance = 0;
      await myDB
          .doc("users/${currentlySIUser?.uid}")
          .collection("wallet")
          .get()
          .then((value) => balance = value.docs.first.data()['Balance']);
      batchDebit.set(
          //maybe add timestamp later to know when the car was added
          walletDebitCollection.doc(),
          {
            'Debit Amount': bookingTotalToPay,
            'RecipientParking ID': receivedID,
            'RecipientParking Name': linkedParkingNameAndInsideInfo,
            'TimeStamp': FieldValue.serverTimestamp(),
            'New Balance': balance - bookingTotalToPay
          }); //{'Debit Amount': 0, 'RecipientParking ID': '', 'TimeStamp': FieldValue.serverTimestamp()});
      await batchDebit
          .commit()
          .whenComplete(() => debugPrint("WALLET SUCCESSFULLY DEBITED"));
      await myDB
          .collection(
              "users/${currentlySIUser?.uid}/wallet/$walletCollId/debits")
          .get()
          .then((value) async {
        var firstInitializedDoc =
            value.docs.where((element) => element.data()['Debit Amount'] == 0);
        firstInitializedDoc.isNotEmpty
            ? await walletDebitCollection
                .doc(firstInitializedDoc.first.id)
                .delete()
            : null;
      });
    });

    //CreatingTopUp collection

    return myDB.collection("users/${currentlySIUser?.uid}/wallet").get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> topUp(
      User? currentlySIUser, String walletCollId) {
    WriteBatch batchTopUp = myDB.batch();

    CollectionReference walletTopUpCollection = myDB.collection(
        "users/${currentlySIUser?.uid}/wallet/$walletCollId/topUps");
    myDB
        .collection("users/${currentlySIUser?.uid}/wallet/$walletCollId/topUps")
        .get()
        .then((value) async {
      if (value.docs.isEmpty) {
        myDB
            .doc("users/${currentlySIUser?.uid}/wallet/$walletCollId")
            .collection("topUps")
            .add({'initialized': true});
      }

      batchTopUp.set(
          //maybe add timestamp later to know when the car was added
          walletTopUpCollection.doc(),
          {
            'TopUp Amount': 8500,
            'From': 'Agent',
            'Type': 'Top Up From Agent',
            'TimeStamp': FieldValue.serverTimestamp()
          });

      await batchTopUp
          .commit()
          .whenComplete(() => debugPrint("DEBIT SUCCESSFULLY ADDED"));

      await myDB
          .collection(
              "users/${currentlySIUser?.uid}/wallet/$walletCollId/topUps")
          .get()
          .then((value) async {
        var firstInitializedDoc = value.docs
            .where((element) => element.data().keys.contains('initialized'));
        firstInitializedDoc.isNotEmpty
            ? await walletTopUpCollection
                .doc(firstInitializedDoc.first.id)
                .delete()
            : null;
      });
    });

    return myDB.collection("users/${currentlySIUser?.uid}/wallet").get();
  }
}

class FirestoreReservationAndArchiveService {
  var myDB = FirebaseFirestore.instance;
  var currentlySignedInUser = FirebaseService().currentlySignedInUser;
//listeningtofbchangeswon'twork here so I moved getUserReservationDetails to reservationCountdown direectly
  void archiveReservation(User? currentlySIUser) {
    myDB.collection('slotsReservations').get().then((value) => null);
  }
}
