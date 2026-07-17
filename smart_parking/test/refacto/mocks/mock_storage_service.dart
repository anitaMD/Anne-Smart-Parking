import 'dart:io';
import 'package:smart_parking/app/services/storage_service.dart';

/// Mock StorageService — zéro appel HTTP réel vers Cloudinary
///
/// Le vrai StorageService fait un appel réseau direct (MultipartRequest
/// vers Cloudinary) sans client injectable — ce mock permet de tester
/// UserNotifier.updateProfilePicture sans jamais toucher le réseau.
class MockStorageService implements StorageService {
  final String? urlToReturn;
  final List<String> uploadedUids = [];

  MockStorageService({this.urlToReturn = 'https://cloudinary.com/fake.jpg'});

  @override
  Future<String?> uploadProfilePicture({
    required File file,
    required String uid,
  }) async {
    uploadedUids.add(uid);
    return urlToReturn;
  }

  @override
  Future<String?> uploadEqualityCard({
    required File file,
    required String uid,
    required String side,
  }) async {
    uploadedUids.add(uid);
    return urlToReturn;
  }

  @override
  void deleteFile(String fileUrl) {
    // no-op — jamais implémenté côté client dans le vrai service non plus
  }
}
