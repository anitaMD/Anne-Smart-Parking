import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

/// Service Firebase Storage YSP Smart Parking
///
/// Responsabilité : upload/download d'images
/// (photo de profil, carte d'invalidité)
class StorageService {
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  StorageService({
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ── Upload photo de profil ────────────────────────────────

  /// Upload la photo de profil et retourne l'URL de téléchargement
  /// Retourne null si l'upload échoue
  Future<String?> uploadProfilePicture(File file) async {
    if (_uid == null) return null;
    try {
      final ref = _storage.ref().child('users/profile/$_uid');
      final task = await ref.putFile(file);
      final url = await task.ref.getDownloadURL();
      return url;
    } on FirebaseException catch (e) {
      _log('uploadProfilePicture error: ${e.code}');
      return null;
    }
  }

  // ── Upload carte d'invalidité ─────────────────────────────

  /// Upload une carte d'invalidité et retourne l'URL
  /// [path] : identifiant unique pour le fichier (ex: "card_1")
  Future<String?> uploadEqualityCard(File file, String path) async {
    if (_uid == null) return null;
    try {
      final ref = _storage.ref().child('users/equalityCard/$_uid/$path');
      final task = await ref.putFile(file);
      final url = await task.ref.getDownloadURL();
      return url;
    } on FirebaseException catch (e) {
      _log('uploadEqualityCard error: ${e.code}');
      return null;
    }
  }

  // ── Suppression ───────────────────────────────────────────

  /// Supprime un fichier depuis son URL
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } on FirebaseException catch (e) {
      _log('deleteFile error: ${e.code}');
    }
  }

  void _log(String message) => debugPrint('[StorageService] $message');
}
