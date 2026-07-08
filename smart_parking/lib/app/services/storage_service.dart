import 'dart:io';
/*import 'package:cloudinary_flutter/cloudinary_flutter.dart';
import 'package:cloudinary_flutter/image/cld_image.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';*/
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service de stockage YSP Smart Parking — Cloudinary
///
/// Remplace Firebase Storage (indisponible sur plan Spark).
/// Cloudinary offre 25GB gratuits sans carte bancaire.
///
/// SÉCURITÉ : on utilise un "unsigned upload preset" (ysp_bucket)
/// → pas besoin d'api_key ni api_secret dans le code mobile
/// → les fichiers sont publics mais l'URL est non-devinable
///
/// PERSPECTIVE : en production, migrer vers Firebase Storage
/// avec le plan Blaze activé pour plus de contrôle.
class StorageService {
  static const String _cloudName = 'dykj02hue';
  static const String _uploadPreset = 'ysp_bucket';
  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  // ── Upload générique ──────────────────────────────────────

  /// Upload une image vers Cloudinary
  /// [file]   : fichier image à uploader
  /// [folder] : dossier de destination (ex: "profiles", "cards")
  /// Retourne l'URL publique ou null si échec
  Future<String?> _uploadImage({
    required File file,
    required String folder,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = folder;

      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final url = jsonData['secure_url'] as String?;
        debugPrint('[StorageService] Upload réussi : $url');
        return url;
      } else {
        debugPrint('[StorageService] Erreur upload : ${jsonData['error']}');
        return null;
      }
    } catch (e) {
      debugPrint('[StorageService] Exception : $e');
      return null;
    }
  }

  // ── Photo de profil ───────────────────────────────────────

  /// Upload la photo de profil d'un utilisateur
  /// Stockée dans le dossier "ysp/profiles/{uid}/"
  Future<String?> uploadProfilePicture({
    required File file,
    required String uid,
  }) async {
    return await _uploadImage(
      file: file,
      folder: 'ysp/profiles/$uid',
    );
  }

  // ── Carte d'invalidité ────────────────────────────────────

  /// Upload le recto ou verso d'une carte d'invalidité
  /// [uid]  : identifiant de l'utilisateur
  /// [side] : "recto" ou "verso"
  /// Stockée dans "ysp/cards/{uid}/"
  Future<String?> uploadEqualityCard({
    required File file,
    required String uid,
    required String side, // "recto" ou "verso"
  }) async {
    return await _uploadImage(
      file: file,
      folder: 'ysp/cards/$uid',
    );
  }

  // ── Suppression ───────────────────────────────────────────

  /// Note : la suppression via API Cloudinary nécessite
  /// l'api_secret qui ne doit pas être dans le code mobile.
  /// En production : implémenter via une Cloud Function Firebase
  /// qui reçoit le public_id et supprime côté serveur.
  ///
  /// Pour l'instant on garde juste l'URL dans Firestore
  /// et on écrase lors d'un nouvel upload.
  void deleteFile(String fileUrl) {
    debugPrint('[StorageService] Suppression non implémentée côté client — '
        'utiliser une Cloud Function en production.');
  }
}
