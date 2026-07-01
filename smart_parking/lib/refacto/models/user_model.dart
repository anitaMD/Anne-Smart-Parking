import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle utilisateur YSP Smart Parking
///
/// Collection Firestore : users/{uid}
/// Champs :
/// {
///   fullName: string
///   email: string
///   phoneNumber: string
///   profileImageUrl: string
///   isSpecialAccessUser: bool
///   equalityCardPaths: string[]
///   createdAt: timestamp
/// }
/// Sous-collections : vehicles/, notifications/, wallet/
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String profileImageUrl;
  final bool isSpecialAccessUser;
  final List<String> equalityCardPaths;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.profileImageUrl,
    required this.isSpecialAccessUser,
    this.equalityCardPaths = const [],
    this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      profileImageUrl: data['profileImageUrl'] as String? ?? '',
      isSpecialAccessUser: data['isSpecialAccessUser'] as bool? ?? false,
      equalityCardPaths: List<String>.from(
        data['equalityCardPaths'] as List? ?? [],
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'profileImageUrl': profileImageUrl,
        'isSpecialAccessUser': isSpecialAccessUser,
        'equalityCardPaths': equalityCardPaths,
        'createdAt': FieldValue.serverTimestamp(),
      };

  UserModel copyWith({
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
    bool? isSpecialAccessUser,
    List<String>? equalityCardPaths,
  }) =>
      UserModel(
        id: id,
        fullName: fullName ?? this.fullName,
        email: email,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        profileImageUrl: profileImageUrl ?? this.profileImageUrl,
        isSpecialAccessUser: isSpecialAccessUser ?? this.isSpecialAccessUser,
        equalityCardPaths: equalityCardPaths ?? this.equalityCardPaths,
        createdAt: createdAt,
      );

  String get firstName => fullName.split(' ').first;

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  bool get hasProfileImage => profileImageUrl.isNotEmpty;

  @override
  String toString() => 'UserModel(id: $id, name: $fullName)';
}
