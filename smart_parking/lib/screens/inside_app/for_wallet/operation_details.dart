import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_parking/screens/inside_app/for_wallet/light_color.dart';

class ShowOperationDetails extends StatelessWidget {
  final Map<String, dynamic> transactionData;
  final String transactionType;

  const ShowOperationDetails(
      {super.key,
      required this.transactionData,
      required this.transactionType});

  @override
  Widget build(BuildContext context) {
    final numFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '',
      decimalDigits: 0,
    );
    Map<String, dynamic> transactionDataValues = transactionData.values.first;
    String newBalance = transactionType == 'TopUp'
        ? transactionDataValues['New Balance'].toString()
        : transactionDataValues['New Balance'].toString();
    var ok = transactionDataValues['TimeStamp'] as Timestamp;
    var timeStampToDate = ok.toDate();
    const TextStyle opID = TextStyle(
        color: LightColor.navyBlue1,
        fontSize: 20,
        fontFamily: 'OpenSans',
        fontWeight: FontWeight.w900);
    const TextStyle title = TextStyle(
        color: Color.fromARGB(255, 50, 92, 151),
        fontSize: 18,
        fontFamily: 'OpenSans',
        fontWeight: FontWeight.w900);
    const TextStyle data = TextStyle(
        color: Colors.black,
        fontSize: 15,
        fontFamily: 'OpenSans',
        fontWeight: FontWeight.w500);

    String transactionAmount = transactionType == 'TopUp'
        ? numFormat.format(transactionDataValues['TopUp Amount'])
        : numFormat.format(transactionDataValues['Debit Amount']);
    var toDot = transactionAmount.characters
        .where((p0) => int.tryParse(p0).runtimeType != int);
    String operationAmounttWithDots = '';

    toDot.isNotEmpty
        ? {
            for (var element in transactionAmount.characters)
              {
                element == toDot.first
                    ? operationAmounttWithDots += '.'
                    : operationAmounttWithDots += element,
              }
          }
        : null;

    String newBalanceCurrencyFormat = numFormat.format(int.parse(newBalance));
    Characters newBalanceToDot = newBalanceCurrencyFormat.characters
        .where((p0) => int.tryParse(p0).runtimeType != int);
    String newBalanceWithDots = '';
    newBalanceToDot.isNotEmpty
        ? {
            for (var element in newBalanceCurrencyFormat.characters)
              {
                element == newBalanceToDot.first
                    ? newBalanceWithDots += '.'
                    : newBalanceWithDots += element,
              }
          }
        : null;

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 30, 15, 0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const FittedBox(child: Text('Operation ID', style: opID)),
                  Flexible(
                      child: Text(transactionData.keys.first, style: data)),
                ],
              ),
              whiteSpace(50),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(transactionType == 'TopUp' ? 'Received' : "Paid",
                      style: title),
                  Text(
                      transactionType == 'TopUp'
                          ? "$operationAmounttWithDots CFA"
                          : '- $operationAmounttWithDots CFA',
                      style: data),
                ],
              ),
              whiteSpace(50),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(transactionType == 'TopUp' ? 'From' : "To",
                      style: title),
                  Text(
                      transactionType == 'TopUp'
                          ? transactionDataValues['From']
                          : transactionDataValues['RecipientParking Name'],
                      style: data),
                ],
              ),
              whiteSpace(50),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Date', style: title),
                  Text(DateFormat().format(timeStampToDate), style: data),
                ],
              ),
              whiteSpace(50),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Context', style: title),
                  Text(
                      transactionType == 'TopUp'
                          ? transactionDataValues['Type']
                          : 'Spot Booking',
                      style: data),
                ],
              ),
              whiteSpace(50),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('New Balance', style: title),
                  Text("$newBalanceWithDots CFA", style: data),
                ],
              ),
              /*   Container(
                color: Colors.red,
                height: 100,
              ) */
            ],
          ),
        ),
      ),
    );
  }

  Container whiteSpace(double i) {
    return Container(
      color: Colors.white,
      height: i,
    );
  }
}
