import 'package:flutter/material.dart';

class StateManagement with ChangeNotifier {
  final initialDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  var selectedTime = TimeOfDay.now();
  String openingHour = '06:00', closingHour = '18:00'; //to initialize
  Duration interval = const Duration(minutes: 30);
  List<TimeOfDay> timeSlotsParsed = [];

  updateSelectedTime(TimeOfDay timeofday) {
    selectedTime = timeofday;
    notifyListeners();
  }

  updateOpeningAndClosingHours(String openingHourFromFirebase, String closingHourFromFirebase) {
    openingHour = openingHourFromFirebase;
    closingHour = closingHourFromFirebase;
  }

  Stream<TimeOfDay> getTimeSlotsIntervals(TimeOfDay startTime, TimeOfDay endTime, Duration interval) async* {
    var hour = startTime.hour;
    var minute = startTime.minute;
    yield TimeOfDay(hour: hour, minute: minute);

    do {
      minute += interval.inMinutes;
      while (minute >= 60) {
        minute -= 60;
        hour++;
      }

      yield hour == endTime.hour && minute + 30 >= endTime.minute
          ? TimeOfDay(hour: endTime.hour - 1, minute: 60 - endTime.minute - 5)
          : TimeOfDay(hour: hour, minute: minute);
      minute += 5;
      yield TimeOfDay(hour: minute == 60 ? hour + 1 : hour, minute: minute == 60 ? 00 : minute);
    } while (hour < endTime.hour || (hour == endTime.hour && minute <= endTime.minute));
    hour == endTime.hour && minute <= endTime.minute ? notifyListeners() : null;
    hour == endTime.hour + 2; //to break the loop

    /*  do {
      var previousMinute = minute;

      if (addedHour == false) {
        debugPrint(
            "TEST ADDED HOUR FALSE -- HOUR $hour previousMinute $previousMinute  --  minute $minute exitedPlusFiveLoop $exitedPlusFiveLoop");
        yield TimeOfDay(
            hour: hour,
            minute: exitedPlusFiveLoop == true ? minute + 10 : minute);
        exitedPlusFiveLoop == true
            ? minute += interval.inMinutes + 10
            : minute += interval.inMinutes;
        exitedPlusFiveLoop = false;
        while (minute >= 60) {
          minute -= 60;
          hour++;
          addedHour = true;
        }
        if (addedHour == true) {
          var newMinute = previousMinute;
          var newHour = hour - 1;
          var newAddedHour = false;
          do {
            //minute = newMinute + 5;
            // var ok = newMinute + 5;
            debugPrint(
                "TEST ADDED HOUR TRUE -- HOUR $hour newHour $newHour  --  minute $minute newMinute  $newMinute  -- itedPlusFiveLoop $exitedPlusFiveLoop");
            yield TimeOfDay(
                hour: newAddedHour == true ? newHour : hour - 1,
                minute:
                    newAddedHour == false ? previousMinute + 5 : newMinute + 5);

            newMinute += interval.inMinutes;
            while (newMinute >= 60) {
              newMinute -= 60;
              newHour++;
              newAddedHour = true;
            }
          } while (newHour <= hour && newMinute - minute == 0);
          exitedPlusFiveLoop = true;
          addedHour = false;
          debugPrint("TEST $hour h $minute _______ $newHour h $newMinute");
        }
      }
    } while (hour < endTime.hour ||
        (hour == endTime.hour && minute <= endTime.minute));
 */
    /*  do {
     
      yield (hour == startTime.hour && minute == startTime.minute) ||
              (hour == startTime.hour && minute == interval.inMinutes)
          ? TimeOfDay(hour: hour, minute: minute)
          : TimeOfDay(
              hour: addedHour == true ? hour - 1 : hour,
              minute: minute + interval.inMinutes);
      minute += interval.inMinutes; //30

      while (minute >= 60) {
        minute -= 60; // on rajoute un eheure à chaque fois qu'on enlève 60mn
        hour++;
      }
      /*   (hour == startTime.hour && minute == startTime.minute) ||
              (hour == startTime.hour && minute == interval.inMinutes)
          ? minute + 5
          : null; */
    } while (hour < endTime.hour ||
        (hour == endTime.hour && minute <= endTime.minute));

    hour == endTime.hour && minute <= endTime.minute ? notifyListeners() : null;
    hour == endTime.hour + 2; //to break the loop */
  }
}//closing brack
