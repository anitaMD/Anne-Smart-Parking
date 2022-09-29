import 'package:flutter/material.dart';

class StateManagement with ChangeNotifier {
  final initialDate =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  var selectedTime = TimeOfDay.now();
  String openingHour = '06:00', closingHour = '18:00'; //to initialize
  Duration interval = const Duration(minutes: 30);
  var updatedSelected = TimeOfDay.now();
  List<TimeOfDay> timeSlotsParsed = [];

  updateSelectedTime(TimeOfDay timeofday) {
    selectedTime = timeofday;
    notifyListeners();
  }

  updateOpeningAndClosingHours(
      String openingHourFromFirebase, String closingHourFromFirebase) {
    openingHour = openingHourFromFirebase;
    closingHour = closingHourFromFirebase;
  }

  Stream<TimeOfDay> getTimeSlotsIntervals(
      TimeOfDay startTime, TimeOfDay endTime, Duration interval) async* {
    var hour = startTime.hour;
    var minute = startTime.minute;
    do {
      yield TimeOfDay(hour: hour, minute: minute);
      minute += interval.inMinutes;
      while (minute >= 60) {
        minute -= 60; // on rajoute un eheure à chaque fois qu'on enlève 60mn
        hour++;
      }
    } while (hour < endTime.hour ||
        (hour == endTime.hour && minute <= endTime.minute));

    hour == endTime.hour && minute <= endTime.minute ? notifyListeners() : null;
    hour == endTime.hour + 2; //to break the loop
  }
}//closing brack
