import 'package:maps_launcher/maps_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service de navigation cartographique YSP Smart Parking
///
/// CONTEXTE : L'intégration Google Maps native dans l'app
/// (comme Yango/Uber qui affichent la carte directement)
/// nécessite l'activation de la facturation Google Cloud,
/// ce qui dépasse le cadre de ce projet académique.
///
/// WORKAROUND ADOPTÉ : on lance l'application de navigation
/// externe installée sur le téléphone (Google Maps, Waze, etc.)
/// via deep link. C'est le même comportement que la plupart
/// des apps de transport qui "transfèrent" la navigation
/// à l'app GPS par défaut.
///
/// PERSPECTIVE D'ÉVOLUTION : en production avec billing activé,
/// remplacer par google_maps_flutter avec affichage natif
/// de l'itinéraire dans l'app, sans quitter YSP.
class MapsService {

  // ── Navigation vers un parking ────────────────────────────

  /// Ouvre l'app de navigation par défaut (Google Maps, Waze...)
  /// avec les coordonnées du parking comme destination.
  /// Identique au bouton "Y aller" de la plupart des apps.
  Future<bool> navigateToParking({
    required double latitude,
    required double longitude,
    String? parkingName,
  }) async {
    try {
      if (parkingName != null) {
        await MapsLauncher.launchQuery(parkingName);
      } else {
        await MapsLauncher.launchCoordinates(latitude, longitude);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Ouvre Google Maps avec navigation GPS active
  /// vers les coordonnées du parking
  Future<bool> openGoogleMapsNavigation({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
      'google.navigation:q=$latitude,$longitude&mode=d',
    );
    final fallbackUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
    );

    // Essayer d'abord l'app Google Maps native
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    // Fallback vers Google Maps web
    if (await canLaunchUrl(fallbackUri)) {
      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  /// Affiche un parking sur la carte sans démarrer la navigation
  Future<bool> showParkingOnMap({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final query = label != null
        ? Uri.encodeComponent(label)
        : '$latitude,$longitude';
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }
}
