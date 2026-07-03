import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/parking_model.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import 'auth_viewmodel.dart';

// ─────────────────────────────────────────────────────────────
// PARKING STATE
// ─────────────────────────────────────────────────────────────

class ParkingState {
  final List<ParkingModel> parkings;
  final ParkingModel? selectedParking;
  final ParkingSpotsInfo? selectedParkingSpots;
  final bool isLoading;
  final String? error;

  const ParkingState({
    this.parkings = const [],
    this.selectedParking,
    this.selectedParkingSpots,
    this.isLoading = false,
    this.error,
  });

  bool get hasParkings => parkings.isNotEmpty;

  ParkingState copyWith({
    List<ParkingModel>? parkings,
    ParkingModel? selectedParking,
    ParkingSpotsInfo? selectedParkingSpots,
    bool? isLoading,
    String? error,
  }) =>
      ParkingState(
        parkings: parkings ?? this.parkings,
        selectedParking: selectedParking ?? this.selectedParking,
        selectedParkingSpots: selectedParkingSpots ?? this.selectedParkingSpots,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ─────────────────────────────────────────────────────────────
// PARKING VIEWMODEL
// ─────────────────────────────────────────────────────────────

class ParkingNotifier extends Notifier<ParkingState> {
  late FirestoreServiceBase _firestoreService;
  late LocationService _locationService;

  @override
  ParkingState build() {
    _firestoreService = ref.read(firestoreServiceProvider);
    _locationService = LocationService();

    ref.listen(authProvider, (_, next) {
      if (next is AuthAuthenticated) loadParkings();
    });

    final authState = ref.read(authProvider);
    if (authState is AuthAuthenticated) loadParkings();

    return const ParkingState();
  }

  Future<void> loadParkings() async {
    state = state.copyWith(isLoading: true);
    try {
      final parkings = await _firestoreService.getParkings();
      debugPrint('[Parking] ${parkings.length} parkings chargés');
      state = state.copyWith(parkings: parkings, isLoading: false);
    } catch (e) {
      debugPrint('[Parking] loadParkings error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> selectParking(ParkingModel parking) async {
    state = state.copyWith(selectedParking: parking);
    try {
      final spots = await _firestoreService.getParkingSpots(parking.id);
      state = state.copyWith(selectedParkingSpots: spots);
    } catch (e) {
      debugPrint('[Parking] selectParking error: $e');
    }
  }

  Future<String> getDistanceTo(ParkingModel parking) async {
    final position = await _locationService.getCurrentPosition();
    if (position == null) return '-- km';
    return _locationService.formattedDistance(
      startLat: position.latitude,
      startLng: position.longitude,
      endLat: parking.latitude,
      endLng: parking.longitude,
    );
  }
}

final parkingProvider = NotifierProvider<ParkingNotifier, ParkingState>(
  ParkingNotifier.new,
);
