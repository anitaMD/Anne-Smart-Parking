class NewUserProfile {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final List<String> equalityCardUploadedStoragePath;
  String profileImage;
  bool isSpecialAccessUser;
  //final String e;

  NewUserProfile(
      {required this.id,
      required this.fullName,
      required this.email,
      required this.phoneNumber,
      required this.profileImage,
      required this.isSpecialAccessUser,
      required this.equalityCardUploadedStoragePath});

  NewUserProfile.fromData(Map<String, dynamic> data)
      : id = data['ID'],
        fullName = data['Full Name'],
        email = data['Email'],
        phoneNumber = data['Phone Number'],
        profileImage = data['Profile Image'],
        isSpecialAccessUser = data['Special Access'],
        equalityCardUploadedStoragePath = data['Equality Card Images'];

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'Full Name': fullName,
      'Email': email,
      'Special Access': isSpecialAccessUser,
      'Phone Number': phoneNumber,
      'Profile Image': profileImage,
      'Equality Card Images': equalityCardUploadedStoragePath,
    };
  }
}
