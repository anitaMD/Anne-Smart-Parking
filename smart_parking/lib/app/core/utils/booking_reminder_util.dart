import 'package:flutter/material.dart';
import 'package:smart_parking/l10n/app_localizations.dart';
import '../../models/booking_model.dart';

/// Spécification d'un rappel à programmer — structure pure, sans
/// aucune dépendance à un plugin natif ou à Firebase. Contient tout
/// ce qu'il faut pour que NotificationService appelle ensuite
/// _scheduleReminder() (effet de bord isolé de la logique de décision).
class ReminderSpec {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledDate;

  const ReminderSpec({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
  });

  @override
  bool operator ==(Object other) =>
      other is ReminderSpec &&
      other.id == id &&
      other.title == title &&
      other.body == body &&
      other.scheduledDate == scheduledDate;

  @override
  int get hashCode => Object.hash(id, title, body, scheduledDate);

  @override
  String toString() =>
      'ReminderSpec(id: $id, title: $title, at: $scheduledDate)';
}

/// Génère un ID stable et unique pour un rappel donné, à partir de
/// l'ID de réservation et d'un suffixe (\_30, \_10, \_start, \_end15,
/// \_ended). Utilisé à la fois pour programmer ET pour annuler le
/// même rappel plus tard (cancelBookingReminders).
int reminderIdFor(String bookingId, String suffix) =>
    '$bookingId$suffix'.hashCode.abs() % 100000;

/// Calcule la liste des rappels à programmer pour une réservation,
/// selon l'heure actuelle et les préférences utilisateur.
///
/// Logique pure — aucun appel à Firebase, aucun plugin natif. C'est
/// cette fonction qui décide QUELS rappels doivent exister et QUAND,
/// laissant à NotificationService.scheduleBookingReminders() la seule
/// responsabilité de les transmettre au plugin de notifications.
///
/// Règles :
///   - Un rappel n'est inclus que si sa date calculée est encore dans
///     le futur par rapport à [now] (sinon il serait immédiatement
///     obsolète / déjà passé).
///   - Chaque rappel individuel peut être désactivé via les
///     paramètres remind30min / remind10min / remindStart /
///     remindEnd15min (réglages utilisateur, Settings > Notifications).
///   - Le rappel de fin de réservation ("ended") n'a pas de toggle
///     dédié — il est inclus tant que bookingEnd est dans le futur.
List<ReminderSpec> computeBookingReminders(
  BookingModel booking, {
  required DateTime now,
  required Locale locale,
  bool remind30min = true,
  bool remind10min = true,
  bool remindStart = true,
  bool remindEnd15min = true,
}) {
  final l10n = lookupAppLocalizations(locale);
  final specs = <ReminderSpec>[];

  if (remind30min) {
    final before30 =
        booking.bookingStart.subtract(const Duration(minutes: 30));
    if (before30.isAfter(now)) {
      specs.add(ReminderSpec(
        id: reminderIdFor(booking.id, '_30'),
        title: l10n.notifReminder30min,
        body: l10n.notif30MinFullBody(booking.spotId),
        scheduledDate: before30,
      ));
    }
  }

  if (remind10min) {
    final before10 =
        booking.bookingStart.subtract(const Duration(minutes: 10));
    if (before10.isAfter(now)) {
      specs.add(ReminderSpec(
        id: reminderIdFor(booking.id, '_10'),
        title: l10n.notifReminder10min(booking.spotId),
        body: l10n.notif10MinBody,
        scheduledDate: before10,
      ));
    }
  }

  if (remindStart) {
    if (booking.bookingStart.isAfter(now)) {
      final h = booking.bookingEnd.hour.toString().padLeft(2, '0');
      final m = booking.bookingEnd.minute.toString().padLeft(2, '0');
      specs.add(ReminderSpec(
        id: reminderIdFor(booking.id, '_start'),
        title: l10n.notifReminderStart(booking.spotId),
        body: l10n.notifStartBody('$h:$m'),
        scheduledDate: booking.bookingStart,
      ));
    }
  }

  if (remindEnd15min) {
    final before15End =
        booking.bookingEnd.subtract(const Duration(minutes: 15));
    if (before15End.isAfter(now)) {
      specs.add(ReminderSpec(
        id: reminderIdFor(booking.id, '_end15'),
        title: l10n.notifReminderEnd(booking.spotId),
        body: l10n.notifEnd15Body,
        scheduledDate: before15End,
      ));
    }
  }

  if (booking.bookingEnd.isAfter(now)) {
    specs.add(ReminderSpec(
      id: reminderIdFor(booking.id, '_ended'),
      title: l10n.notifBookingEndedTitle,
      body: l10n.notifBookingEndedBody(booking.spotId),
      scheduledDate: booking.bookingEnd,
    ));
  }

  return specs;
}
