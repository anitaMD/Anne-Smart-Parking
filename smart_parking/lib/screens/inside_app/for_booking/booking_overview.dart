import 'package:flutter/material.dart';

class BookingOverviewFinal extends StatefulWidget {
  final Map<String, dynamic> bookerFirstPageInfoFetched;
  const BookingOverviewFinal(
      {Key? key, required this.bookerFirstPageInfoFetched})
      : super(key: key);

  @override
  State<BookingOverviewFinal> createState() => _BookingOverviewFinalState();
}

class _BookingOverviewFinalState extends State<BookingOverviewFinal> {
  @override
  Widget build(BuildContext context) {
    debugPrint("THIS IS WHAT YOU GET: ${widget.bookerFirstPageInfoFetched}");
    return Container();
  }
}
