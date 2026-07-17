import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Signature injectable pour la résolution DNS — permet de remplacer
/// le vrai InternetAddress.lookup par une fausse implémentation en
/// test, sans jamais toucher au réseau réel.
typedef DnsLookup = Future<List<InternetAddress>> Function(String host);

/// Vérifie qu'une connexion réseau annoncée par le système
/// (WiFi/données mobiles) correspond à un accès Internet réel.
///
/// Un téléphone peut être connecté au WiFi d'un routeur sans accès
/// Internet (portail captif, forfait épuisé, etc.) — le simple flag
/// ConnectivityResult ne suffit pas, d'où cette vérification par
/// résolution DNS.
///
/// Logique pure injectable — [lookup] par défaut utilise le vrai
/// InternetAddress.lookup, mais peut être remplacé en test.
Future<bool> checkRealInternet(
  ConnectivityResult status, {
  DnsLookup lookup = InternetAddress.lookup,
  Duration timeout = const Duration(seconds: 5),
}) async {
  if (status == ConnectivityResult.none) return false;

  try {
    final result = await lookup('google.com').timeout(timeout);
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}
