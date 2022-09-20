class InsideInfo {
  final num availableSlots;
  final num occupiedSlots;
  final num totalSlotsNumber;

  InsideInfo({
    required this.availableSlots,
    required this.occupiedSlots,
    required this.totalSlotsNumber,
  });

  InsideInfo.fromFirestore(Map<String, dynamic> firestore)
      : availableSlots = firestore['Available Slots'],
        occupiedSlots = firestore['Occupied Slots'],
        totalSlotsNumber = firestore['Total Slots Number'];
}
