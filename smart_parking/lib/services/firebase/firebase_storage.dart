// ignore_for_file: avoid_print

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  FirebaseStorage storage = FirebaseStorage.instance;
  User? currentUser = FirebaseAuth.instance.currentUser;
  //
  Future<String> updloadFile(File file) async {
    // ignore: prefer_typing_uninitialized_variables
    var downloadURL;
    try {
      var uid = currentUser?.uid.toString();
      var storageRef = storage.ref().child("users/profile/$uid");
      var uploadTask = storageRef.putFile(file);
      // ignore: unused_local_variable
      var completedTask =
          await uploadTask.then((p0) => downloadURL = p0.ref.getDownloadURL());
      print('IMAGE UPLOADED IN STORAGE');
      return downloadURL;
    } on FirebaseException catch (e) {
      print(e);
      return (e.code.toUpperCase());
    }
  }
}




/* Future<String> updloadFile(File file) async {
    var downloadURL;
    try {
      var uid = currentUser?.uid.toString();
      var storageRef = storage.ref().child("users/profile/$uid");
      var uploadTask = storageRef.putFile(file);
      var completedTask = 
          await uploadTask.then((p0) => downloadURL = p0.ref.getDownloadURL());
      return downloadURL;
    } on FlutterError catch (e) {
      print(e);
      return (e.diagnostics.toString());
    }
  } */
