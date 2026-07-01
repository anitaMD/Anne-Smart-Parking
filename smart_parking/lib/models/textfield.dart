// ignore_for_file: avoid_print

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:smart_parking/styling/styling.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

class MyTextField extends StatefulWidget {
  final Icon icon;
  final TextEditingController controller;
  final String hint;
  final bool isPassword, isNumber, isFullName;
  final TextInputType inputType;
  final FocusNode focusNode;
  final Color viewBgColor;

  const MyTextField({
    super.key,
    required this.isNumber,
    required this.focusNode,
    required this.icon,
    required this.hint,
    required this.controller,
    required this.inputType,
    required this.isPassword,
    required this.viewBgColor,
    required this.isFullName,
  });

  @override
  State<MyTextField> createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  // bool isObscure = false;
  bool isObscure = true;
  /* ------------- NUMBER VALIDATION FUNCTION -------------*/
  Future<void> validateNumber() async {
    String fetchedNumber = widget.controller.text;
    const isoCode = IsoCode.SN;

    try {
      final phone = PhoneNumber.parse(fetchedNumber, callerCountry: isoCode);
      bool validSnPhoneNumber = phone.isValid();
      if (!validSnPhoneNumber) {
        Fluttertoast.showToast(
            msg: 'Please check number format.',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            fontSize: 16.0);
      }
    } catch (e) {
      Fluttertoast.showToast(
          msg: 'Please enter a phone number.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          fontSize: 16.0);
      print(e);
    }
  }
  /* ------------- NUMBER VALIDATION FUNCTION - END -------------*/

  /* ------------- TOAST MESSAGES -------------*/
  String? toastValidationMessages(String? value) {
    if (widget.isPassword) {
      if (widget.controller.text.isEmpty) {
        Fluttertoast.showToast(
          msg: 'Please enter a password.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          fontSize: 16.0,
        );
      } else {
        String pattern =
            r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$';
        RegExp regex = RegExp(pattern);
        if (!regex.hasMatch(widget.controller.text)) {
          Fluttertoast.showToast(
              msg: 'Please check password format.',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              fontSize: 16.0);
        }
      }
    } else if (!widget.isPassword && !widget.isNumber && !widget.isFullName) {
      if (EmailValidator.validate(widget.controller.text)) {
      } else if (widget.controller.text.isEmpty) {
        Fluttertoast.showToast(
            msg: 'Email is required.',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            fontSize: 16.0);
      } else {
        Fluttertoast.showToast(
            msg: 'Please check email format.',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            fontSize: 16.0);
      }
    } else if (widget.isNumber) {
      validateNumber();
    } else if (widget.isFullName && widget.controller.text.isEmpty) {
      Fluttertoast.showToast(
          msg: 'Please enter your full name.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          fontSize: 16.0);
    }
    return null;
  }
  /* ------------- TOAST MESSAGES - END -------------*/

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.5),
      child: Material(
        borderRadius: BorderRadius.circular(10.0),
        color: widget.viewBgColor, //const Color(0xFF6CA8F1),
        elevation: 2.0,
        shadowColor: Colors.black45, //const Color(0xFF6CA8F1),
        child: TextFormField(
          validator: toastValidationMessages,
          controller: widget.controller,
          onTap: () => widget.focusNode.requestFocus(),
          decoration: passwordVisibility(),
          obscureText: isObscure,
          keyboardType: widget.inputType,
          onSaved: (value) => widget.controller.text = value.toString(),
        ),
      ),
    );
  }

  InputDecoration passwordVisibility() {
    if (widget.isPassword) {
      return InputDecoration(
        errorStyle: const TextStyle(
          color: Colors.white,
        ),
        prefixIcon: widget.icon,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(14.0),
        hintStyle: hintTextStyle,
        hintText: widget.hint,
        suffixIcon: IconButton(
          icon: Icon(!isObscure ? Icons.visibility_off : Icons.visibility),
          color: Colors.white,
          onPressed: () {
            setState(() {
              isObscure = !isObscure;
            });
          },
        ),
      );
    } else {
      isObscure = false;
      return InputDecoration(
        errorStyle: const TextStyle(
          color: Colors.white,
        ),
        prefixIcon: widget.icon,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(14.0),
        hintStyle: hintTextStyle,
        hintText: widget.hint,
      );
    }
  }
}
