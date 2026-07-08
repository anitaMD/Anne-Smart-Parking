// ignore_for_file: prefer_typing_uninitialized_variables, avoid_print

import 'package:flutter/material.dart';
import 'package:smart_parking/old/notifiers/booking_state_management.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';

class MyOwnBooker extends StatefulWidget {
  const MyOwnBooker({super.key});

  @override
  State<MyOwnBooker> createState() => _MyOwnBookerState();
}

class _MyOwnBookerState extends State<MyOwnBooker> {
  //ADD OPENING AND CLOSING HOURS TO FIRESTORE LOCATIONS DOCU
  Set<TimeOfDay> fetchedTimes = {};
  CalendarFormat format = CalendarFormat.twoWeeks;
  Duration interval = const Duration(minutes: 30);
  DateTime selectedDay = DateTime.now(), focusedDay = DateTime.now();
  Color selectedTimeSlotColor = Colors.orange;

  @override
  Widget build(BuildContext context) {
    TimeOfDay startTime = TimeOfDay(
            hour: int.parse(context
                .watch<BookingStateManagement>()
                .openingHour
                .split(":")[0]),
            minute: int.parse(context
                .watch<BookingStateManagement>()
                .openingHour
                .split(":")[1])),
        endTime = TimeOfDay(
            hour: int.parse(context
                .watch<BookingStateManagement>()
                .closingHour
                .split(":")[0]),
            minute: int.parse(context
                .watch<BookingStateManagement>()
                .closingHour
                .split(":")[1]));

    context
        .watch<BookingStateManagement>()
        .getTimeSlotsIntervals(startTime, endTime, interval)
        .toList()
        .then((value) {
      for (var timeOfDay in value) {
        fetchedTimes.add(timeOfDay);
      }
      print("FETCHED LENGHT! ${fetchedTimes.length}");
    });

    print(
        "FROM NOTIFIER : ${context.watch<BookingStateManagement>().initialDate}");
    return SizedBox(
      height: 600,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 3.0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TableCalendar(
                    pageJumpingEnabled: true,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    focusedDay: focusedDay,
                    firstDay: DateTime.now(),
                    lastDay: DateTime(DateTime.now().year + 1),
                    selectedDayPredicate: (day) {
                      return isSameDay(selectedDay, day);
                    },
                    onDaySelected: (newSelectedDay, newFocusedDay) {
                      print(
                          "BEFORE  SELECTED $selectedDay FOCUSED $focusedDay");
                      setState(() {
                        (newSelectedDay.weekday == DateTime.sunday ||
                                newSelectedDay.weekday == DateTime.saturday)
                            ? null
                            : selectedDay = newSelectedDay;
                        focusedDay =
                            newFocusedDay; // update `_focusedDay` here as well
                      });
                      print("AFTERR SELECTED $selectedDay FOCUSED $focusedDay");
                    },
                    //STYLING OF CALENDAR
                    calendarFormat: format,
                    onFormatChanged: (newFormat) => setState(() {
                      format = newFormat;
                    }),
                    calendarStyle: const CalendarStyle(
                      //weekendDecoration: BoxDecoration(color: Colors.purple),
                      selectedDecoration: BoxDecoration(
                          color: Colors.green, shape: BoxShape.circle),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),

          Row(
            //COLOR LEGEND TIME
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                //AVAILABLE
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                        color: Colors.green, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 3),
                  const FittedBox(
                    child: Text(
                      'Available',
                      style: TextStyle(color: Colors.black, fontSize: 15),
                    ),
                  )
                ],
              ),
              Row(
                //SELECTED
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                        color: Colors.orange, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 3),
                  const FittedBox(
                    child: Text(
                      'Selected',
                      style: TextStyle(color: Colors.black, fontSize: 15),
                    ),
                  ),
                ],
              ),
              Row(
                //BOOKED
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 3),
                  const FittedBox(
                    child: Text(
                      'Booked',
                      style: TextStyle(color: Colors.black, fontSize: 15),
                    ),
                  )
                ],
              ),
            ],
          ),
          //GRID                      //edit height and shape of card

          const SizedBox(
            height: 20,
          ),
          Expanded(
            child: GridView.builder(
                itemCount: fetchedTimes.toList().isEmpty
                    ? 10
                    : fetchedTimes.toList().length - 1,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      context
                          .read<BookingStateManagement>()
                          .updateSelectedTime(fetchedTimes.elementAt(index));
                    },
                    child: Card(
                        margin: const EdgeInsets.all(8),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        color: getSelectedTimeSlotColor(index),
                        child: fetchedTimes.toList().isEmpty
                            ? null
                            : Center(
                                child:
                                    (index + 1) == fetchedTimes.toList().length
                                        ? null
                                        : GridTile(
                                            child: Text(
                                                "${fetchedTimes.elementAt(index).format(context)} - ${fetchedTimes.elementAt(index + 1).format(context)}"),
                                          ),
                              )),
                  );
                }),
          ),
        ],
      ),
    );
  }

  Color getSelectedTimeSlotColor(int index) {
    return context.watch<BookingStateManagement>().selectedTime ==
            fetchedTimes.elementAt(index)
        ? selectedTimeSlotColor
        : Colors.white;
  }
}

/* Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton(
              onPressed: () {},
              child: Text('${context.watch<StateManagement>().count}'),
            ),
            FloatingActionButton(
                child: Icon(Icons.remove),
                onPressed: () => context.read<StateManagement>().reset()),
          ],
        ),
      ), */
