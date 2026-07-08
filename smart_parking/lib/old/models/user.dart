import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  String profileImage;
  var timeStamp = FieldValue.serverTimestamp();
  //final String userRole;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.timeStamp,
    required this.profileImage,
    /*  required this.userRole*/
  });

  UserProfile.fromData(Map<String, dynamic> data)
      : id = data['id'],
        fullName = data['fullName'],
        email = data['email'],
        //userRole = data['userRole'],
        timeStamp = data['timeStamp'],
        phoneNumber = data['phoneNumber'],
        profileImage = data['profileImage'];

/*   UserProfile.fromData(Map<String, dynamic> data)
      : id = data['ID'],
        fullName = data['Full Name'],
        email = data['Email'],
        //userRole = data['userRole'],
        timeStamp = data['TimeStamp'],
        phoneNumber = data['Phone Number'],
        profileImage = data['Profile Image']; */

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      //'userRole': userRole,
      'phoneNumber': phoneNumber,
      'timeStamp': timeStamp,
      'profileImage': profileImage,
    };
  }

  /*  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'Full Name': fullName,
      'Email': email,
      //'userRole': userRole,
      'Phone Number': phoneNumber,
      'TimeStamp': timeStamp,
      'Profile Image': profileImage,
    };
  } */
}
