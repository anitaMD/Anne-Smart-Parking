import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_parking/app/screens/settings/settings_screen.dart';
import 'package:smart_parking/app/services/notification_service.dart';
import 'package:smart_parking/l10n/app_localizations.dart';
import '../models/booking_model.dart';
import '../services/firestore_service.dart';
import 'auth_viewmodel.dart';
import 'user_viewmodel.dart';

// ─────────────────────────────────────────────────────────────
// BOOKING STATE
// ─────────────────────────────────────────────────────────────

class BookingState {
  final List<BookingModel> unArchivedBookings;
  final List<BookingModel> allArchivedBookings;
  final bool isLoading;
  final String? error;

  const BookingState({
    this.unArchivedBookings = const [],
    this.allArchivedBookings = const [],
    this.isLoading = false,
    this.error,
  });

  // ── Dashboard ─────────────────────────────────────────────

  /// La réservation à mettre en avant sur le dashboard — soit celle
  /// réellement en cours (bookingStart ≤ now ≤ bookingEnd), soit
  /// une réservation en dépassement actif (bookingEnd dépassé, mais
  /// le véhicule n'est pas encore confirmé parti). Sans ce deuxième
  /// cas, une réservation en dépassement disparaîtrait du dashboard
  /// pile au moment où l'utilisateur a le plus besoin d'être alerté
  /// qu'il est facturé en continu.
  BookingModel? get ongoingBooking {
    try {
      return unArchivedBookings
          .firstWhere((b) => b.isOngoing || b.isOverstaying);
    } catch (_) {
      return null;
    }
  }

  List<BookingModel> get upcomingBookings => unArchivedBookings
      .where((b) => b.status == BookingStatus.upcoming && b.hasNotStarted)
      .toList();

  List<BookingModel> get otherUnarchivedBookings => unArchivedBookings
      .where((b) => !b.isOngoing && !b.isOverstaying)
      .toList();

  bool get hasUnarchivedBookings => unArchivedBookings.isNotEmpty;
  bool get hasOngoing => ongoingBooking != null;
  bool get hasArchivedBookings => allArchivedBookings.isNotEmpty;

  // ── Historique complet — pour BookingHistoryScreen ────────
  // Combine non-archivés + archivés, triés par date décroissante

  List<BookingModel> get allBookings {
    final all = [...unArchivedBookings, ...allArchivedBookings];
    all.sort((a, b) => b.bookingStart.compareTo(a.bookingStart));
    return all;
  }

  // Alias pour compatibilité
  List<BookingModel> get bookings => unArchivedBookings;

  BookingState copyWith({
    List<BookingModel>? unArchivedBookings,
    List<BookingModel>? archivedBookings,
    bool? isLoading,
    String? error,
  }) =>
      BookingState(
        unArchivedBookings: unArchivedBookings ?? this.unArchivedBookings,
        allArchivedBookings: archivedBookings ?? allArchivedBookings,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ─────────────────────────────────────────────────────────────
// BOOKING VIEWMODEL
// ─────────────────────────────────────────────────────────────

class BookingNotifier extends Notifier<BookingState> {
  late FirestoreServiceBase _firestoreService;
  StreamSubscription? _unarchivedSubscription;
  StreamSubscription? _archivedSubscription;
  int _loadGeneration = 0;

  @override
  BookingState build() {
    _firestoreService = ref.read(firestoreServiceProvider);

    ref.onDispose(() {
      _unarchivedSubscription?.cancel();
      _archivedSubscription?.cancel();
    });

    ref.listen(authProvider, (_, next) {
      if (next is AuthAuthenticated) {
        loadBookings(next.user.id);
        loadArchivedBookings(next.user.id);
      }
      if (next is AuthUnauthenticated) {
        _loadGeneration++; // invalide tout stream en cours
        _unarchivedSubscription?.cancel();
        _archivedSubscription?.cancel();
        state = const BookingState();
      }
    });

    final authState = ref.read(authProvider);
    if (authState is AuthAuthenticated) {
      debugPrint('[Booking] build() - calling load for ${authState.user.id}');
      loadBookings(authState.user.id);
      loadArchivedBookings(authState.user.id);
    }

    return const BookingState();
  }

  // ── Chargement non-archivés (dashboard) — stream temps réel ──
  //
  // Converti d'un fetch ponctuel (Future) à un stream Firestore en
  // direct : sans ça, les écritures externes (script Raspberry Pi
  // confirmant une arrivée/un départ/un dépassement) n'étaient
  // jamais reflétées dans l'app tant que l'utilisateur ne
  // rafraîchissait pas manuellement ou ne relançait pas l'app.

  Future<void> loadBookings(String uid) async {
    state = state.copyWith(isLoading: true);
    final myGeneration = ++_loadGeneration;

    await _unarchivedSubscription?.cancel();
    _unarchivedSubscription =
        _firestoreService.watchUserUnarchivedBookings(uid).listen(
      (bookings) {
        if (myGeneration != _loadGeneration) return; // obsolète, ignoré
        debugPrint('[Booking] unarchived (stream): ${bookings.length}');
        state = state.copyWith(
          unArchivedBookings: bookings,
          isLoading: false,
        );
      },
      onError: (e) {
        if (myGeneration != _loadGeneration) return;
        state = state.copyWith(isLoading: false, error: e.toString());
      },
    );
  }

  // ── Chargement archivés (historique) — stream temps réel ─────

  Future<void> loadArchivedBookings(String uid) async {
    final myGeneration = _loadGeneration;

    await _archivedSubscription?.cancel();
    _archivedSubscription =
        _firestoreService.watchUserArchivedBookings(uid).listen(
      (bookings) {
        if (myGeneration != _loadGeneration) return;
        debugPrint('[Booking] archived (stream): ${bookings.length}');
        state = state.copyWith(archivedBookings: bookings);
      },
      onError: (e, stack) {
        if (myGeneration != _loadGeneration) return;
        debugPrint('[Booking] watchUserArchivedBookings ERROR: $e');
        debugPrint('[Booking] stack: $stack');
      },
    );
  }

  // ── Créer ─────────────────────────────────────────────────

  Future<void> createBooking({
    required String clientId,
    required String parkingId,
    required String spotId,
    required String vehicleId,
    required DateTime bookingStart,
    required DateTime bookingEnd,
    required int totalCost,
    required String parkingName,
  }) async {
    final booking = BookingModel(
      id: '',
      clientId: clientId,
      parkingId: parkingId,
      spotId: spotId,
      vehicleId: vehicleId,
      bookingStart: bookingStart,
      bookingEnd: bookingEnd,
      totalCost: totalCost,
      status: BookingStatus.upcoming,
      vehicleStatus: VehicleStatus.notYetParked,
      isArchived: false,
      createdAt: DateTime.now(),
    );

    final bookingId = await _firestoreService.createBookingAtomic(booking);

    // Langue choisie par l'utilisateur dans les Réglages (pas la
    // langue brute du téléphone) — cohérent avec le reste de l'app.
    final locale = ref.read(localeProvider);
    final l10n = lookupAppLocalizations(locale);

    // Notifier l'utilisateur
    await _firestoreService.saveNotification(
      uid: clientId,
      title: l10n.notifBookingConfirmedTitle,
      body: l10n.notifBookingConfirmedBody(spotId, parkingName),
    );

// Planifier les rappels
    final bookingWithId = BookingModel(
      id: bookingId,
      clientId: booking.clientId,
      parkingId: booking.parkingId,
      spotId: booking.spotId,
      vehicleId: booking.vehicleId,
      bookingStart: booking.bookingStart,
      bookingEnd: booking.bookingEnd,
      totalCost: booking.totalCost,
      status: booking.status,
      vehicleStatus: booking.vehicleStatus,
      isArchived: booking.isArchived,
      createdAt: booking.createdAt,
    );

    final notifSettings = ref.read(notifSettingsProvider);
    debugPrint(
        '[Notif] Settings: all=${notifSettings.allEnabled} 30min=${notifSettings.remind30min} 10min=${notifSettings.remind10min} start=${notifSettings.remindStart} end15=${notifSettings.remindEnd15min}');

    if (notifSettings.allEnabled) {
      ref.read(notificationServiceProvider).scheduleBookingReminders(
            bookingWithId,
            locale: locale,
            remind30min: notifSettings.remind30min,
            remind10min: notifSettings.remind10min,
            remindStart: notifSettings.remindStart,
            remindEnd15min: notifSettings.remindEnd15min,
          );
    }
    // Débiter le wallet
    final userState = ref.read(userProvider);
    final wallet = userState.wallet;
    if (wallet != null) {
      final newBalance = wallet.balance - totalCost;
      await _firestoreService.updateWalletBalance(
          clientId, wallet.id, newBalance);
      await _firestoreService.addDebit(
        uid: clientId,
        walletId: wallet.id,
        amount: totalCost,
        newBalance: newBalance,
        parkingId: parkingId,
        parkingName: parkingName,
      );
    }

    // Plus besoin de recharger explicitement — le stream Firestore
    // (watchUserUnarchivedBookings) reflète déjà automatiquement
    // cette nouvelle réservation dès son écriture.
    await ref.read(userProvider.notifier).loadUserData(clientId);
  }

  // ── Éditer ────────────────────────────────────────────────

  Future<void> editBooking({
    required BookingModel booking,
    required DateTime newStart,
    required DateTime newEnd,
    required String newSpotId,
    required String parkingName,
    required int feePerSlot,
  }) async {
    final edits = <BookingEdit>[];

    if (newStart != booking.bookingStart) {
      edits.add(BookingEdit(
        editedAt: DateTime.now(),
        field: 'bookingStart',
        oldValue: booking.bookingStart.toIso8601String(),
        newValue: newStart.toIso8601String(),
      ));
    }
    if (newEnd != booking.bookingEnd) {
      edits.add(BookingEdit(
        editedAt: DateTime.now(),
        field: 'bookingEnd',
        oldValue: booking.bookingEnd.toIso8601String(),
        newValue: newEnd.toIso8601String(),
      ));
    }
    if (newSpotId != booking.spotId) {
      edits.add(BookingEdit(
        editedAt: DateTime.now(),
        field: 'spotId',
        oldValue: booking.spotId,
        newValue: newSpotId,
      ));
    }

    if (edits.isEmpty) {
      return;
    }

    // Calcul différence de coût
    final oldMins = booking.durationMinutes;
    final newMins = newEnd.difference(newStart).inMinutes;
    final oldCost = (oldMins ~/ 30) * feePerSlot;
    final newCost = (newMins ~/ 30) * feePerSlot;
    final diff = newCost - oldCost;

    if (diff > 0) {
      final userState = ref.read(userProvider);
      final wallet = userState.wallet;
      if (wallet == null || wallet.balance < diff) {
        throw Exception('Solde insuffisant (+$diff SPM requis)');
      }
      final newBalance = wallet.balance - diff;
      await _firestoreService.updateWalletBalance(
          booking.clientId, wallet.id, newBalance);
      await _firestoreService.addDebit(
        uid: booking.clientId,
        walletId: wallet.id,
        amount: diff,
        newBalance: newBalance,
        parkingId: booking.parkingId,
        parkingName: parkingName,
      );
      edits.add(BookingEdit(
        editedAt: DateTime.now(),
        field: 'totalCost',
        oldValue: '${booking.totalCost} SPM',
        newValue: '${booking.totalCost + diff} SPM',
      ));
    }

    await _firestoreService.updateBookingFields(booking.id, {
      'bookingStart': Timestamp.fromDate(newStart),
      'bookingEnd': Timestamp.fromDate(newEnd),
      'spotId': newSpotId,
      if (diff > 0) 'totalCost': booking.totalCost + diff,
      'editHistory':
          FieldValue.arrayUnion(edits.map((e) => e.toMap()).toList()),
    });

    // Reprogrammer les rappels avec les nouvelles heures — sans ça,
    // les anciens rappels (calculés sur l'ancien bookingStart/End)
    // resteraient programmés aux mauvais moments après une édition
    // (ex: déjà passés si la réservation a été raccourcie, ou trop
    // tôt/tard si elle a été prolongée/décalée).
    final editedBooking = booking.copyWith(
      bookingStart: newStart,
      bookingEnd: newEnd,
      spotId: newSpotId,
      totalCost: diff > 0 ? booking.totalCost + diff : booking.totalCost,
    );

    final notifSettings = ref.read(notifSettingsProvider);
    final locale = ref.read(localeProvider);

    if (notifSettings.allEnabled) {
      await ref.read(notificationServiceProvider).scheduleBookingReminders(
            editedBooking,
            locale: locale,
            remind30min: notifSettings.remind30min,
            remind10min: notifSettings.remind10min,
            remindStart: notifSettings.remindStart,
            remindEnd15min: notifSettings.remindEnd15min,
          );
    } else {
      // Réglages désactivés — s'assurer qu'aucun ancien rappel ne
      // subsiste tout de même.
      await ref
          .read(notificationServiceProvider)
          .cancelBookingReminders(booking.id);
    }

    // Idem — le stream reflète déjà les nouveaux horaires/place.
    if (diff > 0) {
      await ref.read(userProvider.notifier).loadUserData(booking.clientId);
    }
    debugPrint('[Booking] Éditée : ${booking.id} diff=$diff SPM');
  }

  // ── Annuler ───────────────────────────────────────────────

  Future<void> cancelBooking(String bookingId) async {
    try {
      final booking =
          state.unArchivedBookings.where((b) => b.id == bookingId).firstOrNull;

      await _firestoreService.updateBookingFields(bookingId, {
        'status': BookingStatus.canceled.name,
        'isArchived': true,
        'canceledAt': FieldValue.serverTimestamp(),
      });

      // Nettoyer les rappels programmés
      await ref
          .read(notificationServiceProvider)
          .cancelBookingReminders(bookingId);

      // Notifier l'utilisateur de l'annulation
      if (booking != null) {
        final locale = ref.read(localeProvider);
        final l10n = lookupAppLocalizations(locale);
        await _firestoreService.saveNotification(
          uid: booking.clientId,
          title: l10n.notifBookingCanceledTitle,
          body: l10n.notifBookingCanceledBody(booking.spotId),
        );
      }

      final updated =
          state.unArchivedBookings.where((b) => b.id != bookingId).toList();
      state = state.copyWith(unArchivedBookings: updated);
    } catch (e) {
      debugPrint('[Booking] cancelBooking error: $e');
    }
  }

  /// Terminer volontairement une réservation avant sa fin prévue —
  /// uniquement disponible côté UI une fois que le capteur confirme
  /// déjà un départ physique réel (voir _CountdownCard, condition
  /// sur watchSensorStatus). Symétrique à la clôture automatique du
  /// script Raspberry Pi après dépassement : même notification de
  /// fin, pour un feedback cohérent peu importe comment la
  /// réservation se termine.
  Future<void> endBookingEarly(String bookingId) async {
    try {
      final booking =
          state.unArchivedBookings.where((b) => b.id == bookingId).firstOrNull;

      await _firestoreService.updateBookingFields(bookingId, {
        'status': 'completed',
        'isArchived': true,
        'completedAt': FieldValue.serverTimestamp(),
        'vehicleDepartedAt': FieldValue.serverTimestamp(),
        'vehicleStatus': 'gone',
      });
      await NotificationService().cancelBookingReminders(bookingId);

      // Notifier l'utilisateur — manquait jusqu'ici, contrairement
      // à la clôture automatique côté Pi qui, elle, notifie déjà.
      if (booking != null) {
        final locale = ref.read(localeProvider);
        final l10n = lookupAppLocalizations(locale);
        await _firestoreService.saveNotification(
          uid: booking.clientId,
          title: l10n.notifBookingEndedTitle,
          body: l10n.notifBookingEndedBody(booking.spotId),
        );
      }

      final updated =
          state.unArchivedBookings.where((b) => b.id != bookingId).toList();
      state = state.copyWith(unArchivedBookings: updated);
    } catch (e) {
      debugPrint('[Booking] endBookingEarly error: $e');
    }
  }
}

// ─────────────────────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────────────────────

final bookingProvider = NotifierProvider<BookingNotifier, BookingState>(
  BookingNotifier.new,
);

final ongoingBookingProvider = Provider<BookingModel?>((ref) {
  return ref.watch(bookingProvider).ongoingBooking;
});
