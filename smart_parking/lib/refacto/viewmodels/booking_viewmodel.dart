import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import '../services/firestore_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/user_viewmodel.dart';

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

  BookingModel? get ongoingBooking {
    try {
      return unArchivedBookings.firstWhere((b) => b.isOngoing);
    } catch (_) {
      return null;
    }
  }

  List<BookingModel> get upcomingBookings => unArchivedBookings
      .where((b) => b.status == BookingStatus.upcoming && b.hasNotStarted)
      .toList();

  List<BookingModel> get otherUnarchivedBookings =>
      unArchivedBookings.where((b) => !b.isOngoing).toList();

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

  @override
  BookingState build() {
    _firestoreService = ref.read(firestoreServiceProvider);

    ref.listen(authProvider, (_, next) {
      if (next is AuthAuthenticated) {
        loadBookings(next.user.id);
        loadArchivedBookings(next.user.id);
      }
      if (next is AuthUnauthenticated) state = const BookingState();
    });

    final authState = ref.read(authProvider);
    if (authState is AuthAuthenticated) {
      loadBookings(authState.user.id);
      loadArchivedBookings(authState.user.id);
    }

    return const BookingState();
  }

  // ── Chargement non-archivés (dashboard) ──────────────────

  Future<void> loadBookings(String uid) async {
    state = state.copyWith(isLoading: true);
    try {
      final bookings = await _firestoreService.getUserUnarchivedBookings(uid);
      debugPrint('[Booking] ${bookings.length} réservations actives');
      state = state.copyWith(
        unArchivedBookings: bookings,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('[Booking] loadBookings error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Chargement archivés (historique) ─────────────────────

  Future<void> loadArchivedBookings(String uid) async {
    try {
      final bookings = await _firestoreService.getUserArchivedBookings(uid);
      state = state.copyWith(archivedBookings: bookings);
      debugPrint('[Booking] ${bookings.length} réservations archivées');
    } catch (e) {
      debugPrint('[Booking] loadArchivedBookings error: $e');
    }
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
    debugPrint('[Booking] Créée : $bookingId');

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

    await loadBookings(clientId);
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
      debugPrint('[Booking] Aucune modification');
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

    await loadBookings(booking.clientId);
    if (diff > 0) {
      await ref.read(userProvider.notifier).loadUserData(booking.clientId);
    }
    debugPrint('[Booking] Éditée : ${booking.id} diff=$diff SPM');
  }

  // ── Annuler ───────────────────────────────────────────────

  Future<void> cancelBooking(String bookingId) async {
    try {
      await _firestoreService.updateBookingFields(bookingId, {
        'status': BookingStatus.canceled.name,
        'isArchived': true,
        'canceledAt': FieldValue.serverTimestamp(),
      });
      final updated =
          state.unArchivedBookings.where((b) => b.id != bookingId).toList();
      state = state.copyWith(unArchivedBookings: updated);
      debugPrint('[Booking] Annulée : $bookingId');
    } catch (e) {
      debugPrint('[Booking] cancelBooking error: $e');
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
