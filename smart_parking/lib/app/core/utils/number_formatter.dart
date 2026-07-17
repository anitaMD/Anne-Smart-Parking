import 'package:intl/intl.dart';

/// Formate un montant SPM avec séparateur de milliers.
/// Exemple : 12500 → "12 500", 1000000 → "1 000 000"
String formatSPM(int amount) {
  final formatter = NumberFormat('#,##0', 'en_US'); // force virgule
  return formatter.format(amount).replaceAll(',', ' ');
}
