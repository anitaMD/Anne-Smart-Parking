import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// État d'une place individuelle
/// Correspond aux 4 couleurs LED de la maquette physique
enum SpotState {
  free, // Vert   — libre standard
  special, // Bleu   — libre handicapé
  reserved, // Orange — réservée via app
  occupied, // Rouge  — véhicule physiquement présent
}

/// Modèle place individuelle YSP Smart Parking
class ParkingSpotModel {
  final String id;
  final String alley;
  final bool isSpecial;
  final SpotState state;

  const ParkingSpotModel({
    required this.id,
    required this.alley,
    required this.isSpecial,
    required this.state,
  });

  factory ParkingSpotModel.fromSpotsInfo({
    required String spotId,
    required List<String> availableIds,
    required List<String> bookedIds,
    required List<String> occupiedFromWalkInIds,
    required List<String> occupiedFromBookingIds,
    required List<String> specialIds,
  }) {
    final isSpecial = specialIds.contains(spotId);
    SpotState state;

    if (occupiedFromWalkInIds.contains(spotId) ||
        occupiedFromBookingIds.contains(spotId)) {
      state = SpotState.occupied;
    } else if (bookedIds.contains(spotId)) {
      state = SpotState.reserved;
    } else if (availableIds.contains(spotId)) {
      state = isSpecial ? SpotState.special : SpotState.free;
    } else {
      state = SpotState.occupied;
    }

    return ParkingSpotModel(
      id: spotId,
      alley: spotId.isNotEmpty ? spotId[0] : '',
      isSpecial: isSpecial,
      state: state,
    );
  }

  ParkingSpotModel copyWith({SpotState? state}) => ParkingSpotModel(
        id: id,
        alley: alley,
        isSpecial: isSpecial,
        state: state ?? this.state,
      );

  Color get ledColor {
    switch (state) {
      case SpotState.free:
        return AppColors.spotFree;
      case SpotState.special:
        return AppColors.spotSpecial;
      case SpotState.reserved:
        return AppColors.spotReserved;
      case SpotState.occupied:
        return AppColors.spotOccupied;
    }
  }

  IconData get stateIcon {
    switch (state) {
      case SpotState.free:
        return Icons.check_circle_outline;
      case SpotState.special:
        return Icons.accessible;
      case SpotState.reserved:
        return Icons.schedule;
      case SpotState.occupied:
        return Icons.directions_car;
    }
  }

  String get stateLabel {
    switch (state) {
      case SpotState.free:
        return 'Libre';
      case SpotState.special:
        return 'Libre (PMR)';
      case SpotState.reserved:
        return 'Réservée';
      case SpotState.occupied:
        return 'Occupée';
    }
  }

  bool get isAvailable => state == SpotState.free || state == SpotState.special;

  @override
  String toString() => 'ParkingSpotModel(id: $id, state: ${state.name})';
}

/// Construit la liste complète des places depuis ParkingSpotsInfo
List<ParkingSpotModel> buildSpotList({
  required List<String> regularIds,
  required List<String> specialIds,
  required List<String> availableIds,
  required List<String> bookedIds,
  required List<String> occupiedFromWalkInIds,
  required List<String> occupiedFromBookingIds,
}) {
  final allIds = [...regularIds, ...specialIds];
  return allIds
      .map((spotId) => ParkingSpotModel.fromSpotsInfo(
            spotId: spotId,
            availableIds: availableIds,
            bookedIds: bookedIds,
            occupiedFromWalkInIds: occupiedFromWalkInIds,
            occupiedFromBookingIds: occupiedFromBookingIds,
            specialIds: specialIds,
          ))
      .toList()
    ..sort((a, b) => a.id.compareTo(b.id));
}
