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
  final List<BookingModel> bookings;
  final bool isLoading;
  final String? error;

  const BookingState({
    this.bookings = const [],
    this.isLoading = false,
    this.error,
  });

  BookingModel? get ongoingBooking {
    try {
      return bookings.firstWhere((b) => b.isOngoing);
    } catch (_) {
      return null;
    }
  }

  List<BookingModel> get upcomingBookings => bookings
      .where((b) => b.hasNotStarted && b.status == BookingStatus.upcoming)
      .toList();

  List<BookingModel> get otherBookings =>
      bookings.where((b) => !b.isOngoing).toList();

  bool get hasBookings => bookings.isNotEmpty;
  bool get hasOngoing => ongoingBooking != null;

  BookingState copyWith({
    List<BookingModel>? bookings,
    bool? isLoading,
    String? error,
  }) =>
      BookingState(
        bookings: bookings ?? this.bookings,
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
      if (next is AuthAuthenticated) loadBookings(next.user.id);
      if (next is AuthUnauthenticated) state = const BookingState();
    });

    final authState = ref.read(authProvider);
    if (authState is AuthAuthenticated) loadBookings(authState.user.id);

    return const BookingState();
  }

  // ── Chargement ────────────────────────────────────────────

  Future<void> loadBookings(String uid) async {
    state = state.copyWith(isLoading: true);
    try {
      final bookings = await _firestoreService.getUserBookings(uid);
      debugPrint('[Booking] ${bookings.length} réservations chargées');
      state = state.copyWith(bookings: bookings, isLoading: false);
    } catch (e) {
      debugPrint('[Booking] loadBookings error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Créer une réservation ─────────────────────────────────

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

    // Créer dans Firestore
    final bookingId = await _firestoreService.createBooking(booking);
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

    // Recharger les réservations
    await loadBookings(clientId);
  }

  // ── Annuler ───────────────────────────────────────────────

  Future<void> cancelBooking(String bookingId) async {
    try {
      await _firestoreService.updateBookingStatus(
          bookingId, BookingStatus.canceled);
      await _firestoreService.archiveBooking(bookingId);
      final updated = state.bookings.where((b) => b.id != bookingId).toList();
      state = state.copyWith(bookings: updated);
    } catch (e) {
      debugPrint('[Booking] cancelBooking error: $e');
    }
  }
}

final bookingProvider = NotifierProvider<BookingNotifier, BookingState>(
  BookingNotifier.new,
);

final ongoingBookingProvider = Provider<BookingModel?>((ref) {
  return ref.watch(bookingProvider).ongoingBooking;
});
