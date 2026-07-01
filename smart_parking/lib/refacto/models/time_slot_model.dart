import 'package:flutter/material.dart';

/// Modèle créneau horaire YSP Smart Parking
///
/// Représente un créneau de 30 minutes pour la réservation.
/// Remplace la logique complexe de getTimeSlotsIntervals()
class TimeSlotModel {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isAvailable;
  final bool isSelected;

  const TimeSlotModel({
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
    this.isSelected = false,
  });

  TimeSlotModel copyWith({bool? isAvailable, bool? isSelected}) =>
      TimeSlotModel(
        startTime: startTime,
        endTime: endTime,
        isAvailable: isAvailable ?? this.isAvailable,
        isSelected: isSelected ?? this.isSelected,
      );

  int get durationMinutes {
    final startTotal = startTime.hour * 60 + startTime.minute;
    final endTotal = endTime.hour * 60 + endTime.minute;
    return endTotal - startTotal;
  }

  String get label => '${_fmt(startTime)} - ${_fmt(endTime)}';

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  DateTime toDateTime(DateTime date) => DateTime(
        date.year, date.month, date.day,
        startTime.hour, startTime.minute,
      );

  @override
  String toString() => 'TimeSlot($label, available: $isAvailable)';
}

/// Génère tous les créneaux de 30 min entre openingHour et closingHour
/// Ex: generateTimeSlots("07:30", "18:00") →
/// [07:30-08:00, 08:00-08:30, ..., 17:30-18:00]
List<TimeSlotModel> generateTimeSlots(
  String openingHour,
  String closingHour, {
  List<TimeSlotModel> bookedSlots = const [],
}) {
  final slots = <TimeSlotModel>[];
  final openParts = openingHour.split(':');
  final closeParts = closingHour.split(':');

  int h = int.parse(openParts[0]);
  int m = int.parse(openParts[1]);
  final closeH = int.parse(closeParts[0]);
  final closeM = int.parse(closeParts[1]);

  while (h < closeH || (h == closeH && m < closeM)) {
    int endM = m + 30;
    int endH = h;
    if (endM >= 60) { endM -= 60; endH++; }
    if (endH > closeH || (endH == closeH && endM > closeM)) break;

    final start = TimeOfDay(hour: h, minute: m);
    final end = TimeOfDay(hour: endH, minute: endM);
    final isBooked = bookedSlots.any(
      (b) => b.startTime.hour == h && b.startTime.minute == m,
    );

    slots.add(TimeSlotModel(
      startTime: start,
      endTime: end,
      isAvailable: !isBooked,
    ));

    m = endM;
    h = endH;
  }
  return slots;
}
