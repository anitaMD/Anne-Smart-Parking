// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GridDashboard extends StatefulWidget {
  const GridDashboard({Key? key}) : super(key: key);

  @override
  State<GridDashboard> createState() => _GridDashboardState();
}

class _GridDashboardState extends State<GridDashboard> {
  int currentIndex = 0;

  final Items item1 = Items(
      id: 0,
      title: "My Vehicles",
      subtitle: "OK",
      event: "3 Events",
      img: "assets/calendar.png");

  final Items item2 = Items(
    id: 1,
    title: "My Wallet",
    subtitle: "Bocali, Apple",
    event: "4 Items",
    img: "assets/food.png",
  );

  final Items item3 = Items(
    id: 2,
    title: "My Bookmarks",
    subtitle: "Saved parkings",
    event: "",
    img: "assets/map.png",
  );

  final Items item4 = Items(
    id: 3,
    title: "Reservation time left",
    subtitle: "Rose favirited your Post",
    event: "",
    img: "assets/festival.png",
  );

  @override
  Widget build(BuildContext context) {
    List<Items> myList = [item1, item2, item3, item4];
    var color = 0xff453658;
    return GridView.count(
        physics: const NeverScrollableScrollPhysics(), //thisiswhatsavedme
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        childAspectRatio: 1.0,
        padding: const EdgeInsets.only(left: 16, right: 16),
        crossAxisCount: 2,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        children: myList.asMap().entries.map((data) /* myList.map((data) */ {
          return Material(
            borderRadius: BorderRadius.circular(10),
            color: Color(color),
            child: TextButton(
              onPressed: () {
                if (myList[myList
                            .indexWhere((item) => item.title == 'Calendar')]
                        .id ==
                    data.value.id) {
                  print("THAT'STRUE 1");
                  setState(() {});
                } else {
                  print("NOPE");
                }
              },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(10)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image.asset(
                      data.value.img,
                      width: 42,
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    Text(
                      data.value.title,
                      style: GoogleFonts.openSans(
                          textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      data.value.subtitle,
                      style: GoogleFonts.openSans(
                          textStyle: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    Text(
                      data.value.event,
                      style: GoogleFonts.openSans(
                          textStyle: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList());
  }
}

class Items {
  int id;
  String title;
  String subtitle;
  String event;
  String img;
  Items(
      {required this.id,
      required this.title,
      required this.subtitle,
      required this.event,
      required this.img});
}
