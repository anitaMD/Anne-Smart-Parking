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
  final String role; // "user" | "agent"
  final String? location;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.profileImageUrl,
    required this.isSpecialAccessUser,
    required this.role,
    this.equalityCardPaths = const [],
    this.createdAt,
    this.location,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      profileImageUrl: data['profileImageUrl'] as String? ?? '',
      role: data['role'] as String? ?? 'user',
      isSpecialAccessUser: data['isSpecialAccessUser'] as bool? ?? false,
      equalityCardPaths: List<String>.from(
        data['equalityCardPaths'] as List? ?? [],
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      location: data['location'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'profileImageUrl': profileImageUrl,
        'isSpecialAccessUser': isSpecialAccessUser,
        'equalityCardPaths': equalityCardPaths,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        if (location != null) 'location': location,
      };

  UserModel copyWith({
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
    bool? isSpecialAccessUser,
    List<String>? equalityCardPaths,
    String? role,
  }) =>
      UserModel(
        id: id,
        fullName: fullName ?? this.fullName,
        email: email,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        role: role ?? this.role,
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
