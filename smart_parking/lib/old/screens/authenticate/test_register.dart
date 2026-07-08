// ignore_for_file: avoid_print, unused_local_variable, avoid_function_literals_in_foreach_calls
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:otp_text_field/otp_field.dart';
import 'package:otp_text_field/style.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_parking/old/models/new_user.dart';
import 'package:smart_parking/old/models/pages/widgets/header_widget.dart';
import 'package:smart_parking/old/models/theme_helper.dart';
import 'package:smart_parking/old/screens/authenticate/testlogin.dart';
import 'package:smart_parking/old/screens/inside_app/testhome.dart';
import 'package:smart_parking/old/services/firebase/firebase_service.dart';
import 'package:smart_parking/old/services/firebase/firebase_storage.dart';
import 'package:smart_parking/old/services/firebase/firestore_service.dart';
import 'package:smart_parking/l10n/generated/app_localizations.dart';
import 'package:gal/gal.dart';

import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class TestRegister extends StatefulWidget {
  const TestRegister({super.key});

  @override
  TestRegisterState createState() => TestRegisterState();
}

class TestRegisterState extends State<TestRegister>
    with SingleTickerProviderStateMixin {
  User? currentUser;
  XFile? profilePicture;
  List<XFile?> equalityCardRectoVerso = [];
  List<String> equalityCardUploadedStoragePath = [];
  final ImagePicker cardImagePicker = ImagePicker();
  String? appSignature;
  String? otpCode;

  final List<BarcodeFormat> formats = [BarcodeFormat.qrCode];
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  String? theCardRecognizedText;

  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  double headerHeight = 300;

  // ignore: unused_field
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseService service = FirebaseService();
  FirestoreUserService firestoreService = FirestoreUserService();
  AuthCredential? theCredential;
  var myDB = FirebaseFirestore.instance;
  var firestoreWalletService = FirestoreWalletService();

  late AnimationController _animationController;
  final rectoScreenshotController = ScreenshotController(),
      versoScreenshotController = ScreenshotController();

  List<Map<String, dynamic>> countries = [
    {"name": "Afghanistan", "flag": "🇦🇫", "code": "AF", "dial_code": "+93"},
    {
      "name": "Åland Islands",
      "flag": "🇦🇽",
      "code": "AX",
      "dial_code": "+358"
    },
    {"name": "Albania", "flag": "🇦🇱", "code": "AL", "dial_code": "+355"},
    {"name": "Algeria", "flag": "🇩🇿", "code": "DZ", "dial_code": "+213"},
    {
      "name": "American Samoa",
      "flag": "🇦🇸",
      "code": "AS",
      "dial_code": "+1684"
    },
    {"name": "Andorra", "flag": "🇦🇩", "code": "AD", "dial_code": "+376"},
    {"name": "Angola", "flag": "🇦🇴", "code": "AO", "dial_code": "+244"},
    {"name": "Anguilla", "flag": "🇦🇮", "code": "AI", "dial_code": "+1264"},
    {"name": "Antarctica", "flag": "🇦🇶", "code": "AQ", "dial_code": "+672"},
    {
      "name": "Antigua and Barbuda",
      "flag": "🇦🇬",
      "code": "AG",
      "dial_code": "+1268"
    },
    {"name": "Argentina", "flag": "🇦🇷", "code": "AR", "dial_code": "+54"},
    {"name": "Armenia", "flag": "🇦🇲", "code": "AM", "dial_code": "+374"},
    {"name": "Aruba", "flag": "🇦🇼", "code": "AW", "dial_code": "+297"},
    {"name": "Australia", "flag": "🇦🇺", "code": "AU", "dial_code": "+61"},
    {"name": "Austria", "flag": "🇦🇹", "code": "AT", "dial_code": "+43"},
    {"name": "Azerbaijan", "flag": "🇦🇿", "code": "AZ", "dial_code": "+994"},
    {"name": "Bahamas", "flag": "🇧🇸", "code": "BS", "dial_code": "+1242"},
    {"name": "Bahrain", "flag": "🇧🇭", "code": "BH", "dial_code": "+973"},
    {"name": "Bangladesh", "flag": "🇧🇩", "code": "BD", "dial_code": "+880"},
    {"name": "Barbados", "flag": "🇧🇧", "code": "BB", "dial_code": "+1246"},
    {"name": "Belarus", "flag": "🇧🇾", "code": "BY", "dial_code": "+375"},
    {"name": "Belgium", "flag": "🇧🇪", "code": "BE", "dial_code": "+32"},
    {"name": "Belize", "flag": "🇧🇿", "code": "BZ", "dial_code": "+501"},
    {"name": "Benin", "flag": "🇧🇯", "code": "BJ", "dial_code": "+229"},
    {"name": "Bermuda", "flag": "🇧🇲", "code": "BM", "dial_code": "+1441"},
    {"name": "Bhutan", "flag": "🇧🇹", "code": "BT", "dial_code": "+975"},
    {
      "name": "Bolivia, Plurinational State of bolivia",
      "flag": "🇧🇴",
      "code": "BO",
      "dial_code": "+591"
    },
    {
      "name": "Bosnia and Herzegovina",
      "flag": "🇧🇦",
      "code": "BA",
      "dial_code": "+387"
    },
    {"name": "Botswana", "flag": "🇧🇼", "code": "BW", "dial_code": "+267"},
    {"name": "Bouvet Island", "flag": "🇧🇻", "code": "BV", "dial_code": "+47"},
    {"name": "Brazil", "flag": "🇧🇷", "code": "BR", "dial_code": "+55"},
    {
      "name": "British Indian Ocean Territory",
      "flag": "🇮🇴",
      "code": "IO",
      "dial_code": "+246"
    },
    {
      "name": "Brunei Darussalam",
      "flag": "🇧🇳",
      "code": "BN",
      "dial_code": "+673"
    },
    {"name": "Bulgaria", "flag": "🇧🇬", "code": "BG", "dial_code": "+359"},
    {"name": "Burkina Faso", "flag": "🇧🇫", "code": "BF", "dial_code": "+226"},
    {"name": "Burundi", "flag": "🇧🇮", "code": "BI", "dial_code": "+257"},
    {"name": "Cambodia", "flag": "🇰🇭", "code": "KH", "dial_code": "+855"},
    {"name": "Cameroon", "flag": "🇨🇲", "code": "CM", "dial_code": "+237"},
    {"name": "Canada", "flag": "🇨🇦", "code": "CA", "dial_code": "+1"},
    {"name": "Cape Verde", "flag": "🇨🇻", "code": "CV", "dial_code": "+238"},
    {
      "name": "Cayman Islands",
      "flag": "🇰🇾",
      "code": "KY",
      "dial_code": "+345"
    },
    {
      "name": "Central African Republic",
      "flag": "🇨🇫",
      "code": "CF",
      "dial_code": "+236"
    },
    {"name": "Chad", "flag": "🇹🇩", "code": "TD", "dial_code": "+235"},
    {"name": "Chile", "flag": "🇨🇱", "code": "CL", "dial_code": "+56"},
    {"name": "China", "flag": "🇨🇳", "code": "CN", "dial_code": "+86"},
    {
      "name": "Christmas Island",
      "flag": "🇨🇽",
      "code": "CX",
      "dial_code": "+61"
    },
    {
      "name": "Cocos (Keeling) Islands",
      "flag": "🇨🇨",
      "code": "CC",
      "dial_code": "+61"
    },
    {"name": "Colombia", "flag": "🇨🇴", "code": "CO", "dial_code": "+57"},
    {"name": "Comoros", "flag": "🇰🇲", "code": "KM", "dial_code": "+269"},
    {"name": "Congo", "flag": "🇨🇬", "code": "CG", "dial_code": "+242"},
    {
      "name": "Congo, The Democratic Republic of the Congo",
      "flag": "🇨🇩",
      "code": "CD",
      "dial_code": "+243"
    },
    {"name": "Cook Islands", "flag": "🇨🇰", "code": "CK", "dial_code": "+682"},
    {"name": "Costa Rica", "flag": "🇨🇷", "code": "CR", "dial_code": "+506"},
    {
      "name": "Cote d'Ivoire",
      "flag": "🇨🇮",
      "code": "CI",
      "dial_code": "+225"
    },
    {"name": "Croatia", "flag": "🇭🇷", "code": "HR", "dial_code": "+385"},
    {"name": "Cuba", "flag": "🇨🇺", "code": "CU", "dial_code": "+53"},
    {"name": "Cyprus", "flag": "🇨🇾", "code": "CY", "dial_code": "+357"},
    {
      "name": "Czech Republic",
      "flag": "🇨🇿",
      "code": "CZ",
      "dial_code": "+420"
    },
    {"name": "Denmark", "flag": "🇩🇰", "code": "DK", "dial_code": "+45"},
    {"name": "Djibouti", "flag": "🇩🇯", "code": "DJ", "dial_code": "+253"},
    {"name": "Dominica", "flag": "🇩🇲", "code": "DM", "dial_code": "+1767"},
    {
      "name": "Dominican Republic",
      "flag": "🇩🇴",
      "code": "DO",
      "dial_code": "+1849"
    },
    {"name": "Ecuador", "flag": "🇪🇨", "code": "EC", "dial_code": "+593"},
    {"name": "Egypt", "flag": "🇪🇬", "code": "EG", "dial_code": "+20"},
    {"name": "El Salvador", "flag": "🇸🇻", "code": "SV", "dial_code": "+503"},
    {
      "name": "Equatorial Guinea",
      "flag": "🇬🇶",
      "code": "GQ",
      "dial_code": "+240"
    },
    {"name": "Eritrea", "flag": "🇪🇷", "code": "ER", "dial_code": "+291"},
    {"name": "Estonia", "flag": "🇪🇪", "code": "EE", "dial_code": "+372"},
    {"name": "Ethiopia", "flag": "🇪🇹", "code": "ET", "dial_code": "+251"},
    {
      "name": "Falkland Islands (Malvinas)",
      "flag": "🇫🇰",
      "code": "FK",
      "dial_code": "+500"
    },
    {
      "name": "Faroe Islands",
      "flag": "🇫🇴",
      "code": "FO",
      "dial_code": "+298"
    },
    {"name": "Fiji", "flag": "🇫🇯", "code": "FJ", "dial_code": "+679"},
    {"name": "Finland", "flag": "🇫🇮", "code": "FI", "dial_code": "+358"},
    {"name": "France", "flag": "🇫🇷", "code": "FR", "dial_code": "+33"},
    {
      "name": "French Guiana",
      "flag": "🇬🇫",
      "code": "GF",
      "dial_code": "+594"
    },
    {
      "name": "French Polynesia",
      "flag": "🇵🇫",
      "code": "PF",
      "dial_code": "+689"
    },
    {
      "name": "French Southern Territories",
      "flag": "🇹🇫",
      "code": "TF",
      "dial_code": "+262"
    },
    {"name": "Gabon", "flag": "🇬🇦", "code": "GA", "dial_code": "+241"},
    {"name": "Gambia", "flag": "🇬🇲", "code": "GM", "dial_code": "+220"},
    {"name": "Georgia", "flag": "🇬🇪", "code": "GE", "dial_code": "+995"},
    {"name": "Germany", "flag": "🇩🇪", "code": "DE", "dial_code": "+49"},
    {"name": "Ghana", "flag": "🇬🇭", "code": "GH", "dial_code": "+233"},
    {"name": "Gibraltar", "flag": "🇬🇮", "code": "GI", "dial_code": "+350"},
    {"name": "Greece", "flag": "🇬🇷", "code": "GR", "dial_code": "+30"},
    {"name": "Greenland", "flag": "🇬🇱", "code": "GL", "dial_code": "+299"},
    {"name": "Grenada", "flag": "🇬🇩", "code": "GD", "dial_code": "+1473"},
    {"name": "Guadeloupe", "flag": "🇬🇵", "code": "GP", "dial_code": "+590"},
    {"name": "Guam", "flag": "🇬🇺", "code": "GU", "dial_code": "+1671"},
    {"name": "Guatemala", "flag": "🇬🇹", "code": "GT", "dial_code": "+502"},
    {"name": "Guernsey", "flag": "🇬🇬", "code": "GG", "dial_code": "+44"},
    {"name": "Guinea", "flag": "🇬🇳", "code": "GN", "dial_code": "+224"},
    {
      "name": "Guinea-Bissau",
      "flag": "🇬🇼",
      "code": "GW",
      "dial_code": "+245"
    },
    {"name": "Guyana", "flag": "🇬🇾", "code": "GY", "dial_code": "+592"},
    {"name": "Haiti", "flag": "🇭🇹", "code": "HT", "dial_code": "+509"},
    {
      "name": "Heard Island and Mcdonald Islands",
      "flag": "🇭🇲",
      "code": "HM",
      "dial_code": "+672"
    },
    {
      "name": "Holy See (Vatican City State)",
      "flag": "🇻🇦",
      "code": "VA",
      "dial_code": "+379"
    },
    {"name": "Honduras", "flag": "🇭🇳", "code": "HN", "dial_code": "+504"},
    {"name": "Hong Kong", "flag": "🇭🇰", "code": "HK", "dial_code": "+852"},
    {"name": "Hungary", "flag": "🇭🇺", "code": "HU", "dial_code": "+36"},
    {"name": "Iceland", "flag": "🇮🇸", "code": "IS", "dial_code": "+354"},
    {"name": "India", "flag": "🇮🇳", "code": "IN", "dial_code": "+91"},
    {"name": "Indonesia", "flag": "🇮🇩", "code": "ID", "dial_code": "+62"},
    {
      "name": "Iran, Islamic Republic of Persian Gulf",
      "flag": "🇮🇷",
      "code": "IR",
      "dial_code": "+98"
    },
    {"name": "Iraq", "flag": "🇮🇶", "code": "IQ", "dial_code": "+964"},
    {"name": "Ireland", "flag": "🇮🇪", "code": "IE", "dial_code": "+353"},
    {"name": "Isle of Man", "flag": "🇮🇲", "code": "IM", "dial_code": "+44"},
    {"name": "Israel", "flag": "🇮🇱", "code": "IL", "dial_code": "+972"},
    {"name": "Italy", "flag": "🇮🇹", "code": "IT", "dial_code": "+39"},
    {"name": "Jamaica", "flag": "🇯🇲", "code": "JM", "dial_code": "+1876"},
    {"name": "Japan", "flag": "🇯🇵", "code": "JP", "dial_code": "+81"},
    {"name": "Jersey", "flag": "🇯🇪", "code": "JE", "dial_code": "+44"},
    {"name": "Jordan", "flag": "🇯🇴", "code": "JO", "dial_code": "+962"},
    {"name": "Kazakhstan", "flag": "🇰🇿", "code": "KZ", "dial_code": "+7"},
    {"name": "Kenya", "flag": "🇰🇪", "code": "KE", "dial_code": "+254"},
    {"name": "Kiribati", "flag": "🇰🇮", "code": "KI", "dial_code": "+686"},
    {
      "name": "Korea, Democratic People's Republic of Korea",
      "flag": "🇰🇵",
      "code": "KP",
      "dial_code": "+850"
    },
    {
      "name": "Korea, Republic of South Korea",
      "flag": "🇰🇷",
      "code": "KR",
      "dial_code": "+82"
    },
    {"name": "Kosovo", "flag": "🇽🇰", "code": "XK", "dial_code": "+383"},
    {"name": "Kuwait", "flag": "🇰🇼", "code": "KW", "dial_code": "+965"},
    {"name": "Kyrgyzstan", "flag": "🇰🇬", "code": "KG", "dial_code": "+996"},
    {"name": "Laos", "flag": "🇱🇦", "code": "LA", "dial_code": "+856"},
    {"name": "Latvia", "flag": "🇱🇻", "code": "LV", "dial_code": "+371"},
    {"name": "Lebanon", "flag": "🇱🇧", "code": "LB", "dial_code": "+961"},
    {"name": "Lesotho", "flag": "🇱🇸", "code": "LS", "dial_code": "+266"},
    {"name": "Liberia", "flag": "🇱🇷", "code": "LR", "dial_code": "+231"},
    {
      "name": "Libyan Arab Jamahiriya",
      "flag": "🇱🇾",
      "code": "LY",
      "dial_code": "+218"
    },
    {
      "name": "Liechtenstein",
      "flag": "🇱🇮",
      "code": "LI",
      "dial_code": "+423"
    },
    {"name": "Lithuania", "flag": "🇱🇹", "code": "LT", "dial_code": "+370"},
    {"name": "Luxembourg", "flag": "🇱🇺", "code": "LU", "dial_code": "+352"},
    {"name": "Macao", "flag": "🇲🇴", "code": "MO", "dial_code": "+853"},
    {"name": "Macedonia", "flag": "🇲🇰", "code": "MK", "dial_code": "+389"},
    {"name": "Madagascar", "flag": "🇲🇬", "code": "MG", "dial_code": "+261"},
    {"name": "Malawi", "flag": "🇲🇼", "code": "MW", "dial_code": "+265"},
    {"name": "Malaysia", "flag": "🇲🇾", "code": "MY", "dial_code": "+60"},
    {"name": "Maldives", "flag": "🇲🇻", "code": "MV", "dial_code": "+960"},
    {"name": "Mali", "flag": "🇲🇱", "code": "ML", "dial_code": "+223"},
    {"name": "Malta", "flag": "🇲🇹", "code": "MT", "dial_code": "+356"},
    {
      "name": "Marshall Islands",
      "flag": "🇲🇭",
      "code": "MH",
      "dial_code": "+692"
    },
    {"name": "Martinique", "flag": "🇲🇶", "code": "MQ", "dial_code": "+596"},
    {"name": "Mauritania", "flag": "🇲🇷", "code": "MR", "dial_code": "+222"},
    {"name": "Mauritius", "flag": "🇲🇺", "code": "MU", "dial_code": "+230"},
    {"name": "Mayotte", "flag": "🇾🇹", "code": "YT", "dial_code": "+262"},
    {"name": "Mexico", "flag": "🇲🇽", "code": "MX", "dial_code": "+52"},
    {
      "name": "Micronesia, Federated States of Micronesia",
      "flag": "🇫🇲",
      "code": "FM",
      "dial_code": "+691"
    },
    {"name": "Moldova", "flag": "🇲🇩", "code": "MD", "dial_code": "+373"},
    {"name": "Monaco", "flag": "🇲🇨", "code": "MC", "dial_code": "+377"},
    {"name": "Mongolia", "flag": "🇲🇳", "code": "MN", "dial_code": "+976"},
    {"name": "Montenegro", "flag": "🇲🇪", "code": "ME", "dial_code": "+382"},
    {"name": "Montserrat", "flag": "🇲🇸", "code": "MS", "dial_code": "+1664"},
    {"name": "Morocco", "flag": "🇲🇦", "code": "MA", "dial_code": "+212"},
    {"name": "Mozambique", "flag": "🇲🇿", "code": "MZ", "dial_code": "+258"},
    {"name": "Myanmar", "flag": "🇲🇲", "code": "MM", "dial_code": "+95"},
    {"name": "Namibia", "flag": "🇳🇦", "code": "NA", "dial_code": "+264"},
    {"name": "Nauru", "flag": "🇳🇷", "code": "NR", "dial_code": "+674"},
    {"name": "Nepal", "flag": "🇳🇵", "code": "NP", "dial_code": "+977"},
    {"name": "Netherlands", "flag": "🇳🇱", "code": "NL", "dial_code": "+31"},
    {
      "name": "Netherlands Antilles",
      "flag": "",
      "code": "AN",
      "dial_code": "+599"
    },
    {
      "name": "New Caledonia",
      "flag": "🇳🇨",
      "code": "NC",
      "dial_code": "+687"
    },
    {"name": "New Zealand", "flag": "🇳🇿", "code": "NZ", "dial_code": "+64"},
    {"name": "Nicaragua", "flag": "🇳🇮", "code": "NI", "dial_code": "+505"},
    {"name": "Niger", "flag": "🇳🇪", "code": "NE", "dial_code": "+227"},
    {"name": "Nigeria", "flag": "🇳🇬", "code": "NG", "dial_code": "+234"},
    {"name": "Niue", "flag": "🇳🇺", "code": "NU", "dial_code": "+683"},
    {
      "name": "Norfolk Island",
      "flag": "🇳🇫",
      "code": "NF",
      "dial_code": "+672"
    },
    {
      "name": "Northern Mariana Islands",
      "flag": "🇲🇵",
      "code": "MP",
      "dial_code": "+1670"
    },
    {"name": "Norway", "flag": "🇳🇴", "code": "NO", "dial_code": "+47"},
    {"name": "Oman", "flag": "🇴🇲", "code": "OM", "dial_code": "+968"},
    {"name": "Pakistan", "flag": "🇵🇰", "code": "PK", "dial_code": "+92"},
    {"name": "Palau", "flag": "🇵🇼", "code": "PW", "dial_code": "+680"},
    {
      "name": "Palestinian Territory, Occupied",
      "flag": "🇵🇸",
      "code": "PS",
      "dial_code": "+970"
    },
    {"name": "Panama", "flag": "🇵🇦", "code": "PA", "dial_code": "+507"},
    {
      "name": "Papua New Guinea",
      "flag": "🇵🇬",
      "code": "PG",
      "dial_code": "+675"
    },
    {"name": "Paraguay", "flag": "🇵🇾", "code": "PY", "dial_code": "+595"},
    {"name": "Peru", "flag": "🇵🇪", "code": "PE", "dial_code": "+51"},
    {"name": "Philippines", "flag": "🇵🇭", "code": "PH", "dial_code": "+63"},
    {"name": "Pitcairn", "flag": "🇵🇳", "code": "PN", "dial_code": "+64"},
    {"name": "Poland", "flag": "🇵🇱", "code": "PL", "dial_code": "+48"},
    {"name": "Portugal", "flag": "🇵🇹", "code": "PT", "dial_code": "+351"},
    {"name": "Puerto Rico", "flag": "🇵🇷", "code": "PR", "dial_code": "+1939"},
    {"name": "Qatar", "flag": "🇶🇦", "code": "QA", "dial_code": "+974"},
    {"name": "Romania", "flag": "🇷🇴", "code": "RO", "dial_code": "+40"},
    {"name": "Russia", "flag": "🇷🇺", "code": "RU", "dial_code": "+7"},
    {"name": "Rwanda", "flag": "🇷🇼", "code": "RW", "dial_code": "+250"},
    {"name": "Reunion", "flag": "🇷🇪", "code": "RE", "dial_code": "+262"},
    {
      "name": "Saint Barthelemy",
      "flag": "🇧🇱",
      "code": "BL",
      "dial_code": "+590"
    },
    {
      "name": "Saint Helena, Ascension and Tristan Da Cunha",
      "flag": "🇸🇭",
      "code": "SH",
      "dial_code": "+290"
    },
    {
      "name": "Saint Kitts and Nevis",
      "flag": "🇰🇳",
      "code": "KN",
      "dial_code": "+1869"
    },
    {"name": "Saint Lucia", "flag": "🇱🇨", "code": "LC", "dial_code": "+1758"},
    {"name": "Saint Martin", "flag": "🇲🇫", "code": "MF", "dial_code": "+590"},
    {
      "name": "Saint Pierre and Miquelon",
      "flag": "🇵🇲",
      "code": "PM",
      "dial_code": "+508"
    },
    {
      "name": "Saint Vincent and the Grenadines",
      "flag": "🇻🇨",
      "code": "VC",
      "dial_code": "+1784"
    },
    {"name": "Samoa", "flag": "🇼🇸", "code": "WS", "dial_code": "+685"},
    {"name": "San Marino", "flag": "🇸🇲", "code": "SM", "dial_code": "+378"},
    {
      "name": "Sao Tome and Principe",
      "flag": "🇸🇹",
      "code": "ST",
      "dial_code": "+239"
    },
    {"name": "Saudi Arabia", "flag": "🇸🇦", "code": "SA", "dial_code": "+966"},
    {"name": "Senegal", "flag": "🇸🇳", "code": "SN", "dial_code": "+221"},
    {"name": "Serbia", "flag": "🇷🇸", "code": "RS", "dial_code": "+381"},
    {"name": "Seychelles", "flag": "🇸🇨", "code": "SC", "dial_code": "+248"},
    {"name": "Sierra Leone", "flag": "🇸🇱", "code": "SL", "dial_code": "+232"},
    {"name": "Singapore", "flag": "🇸🇬", "code": "SG", "dial_code": "+65"},
    {"name": "Slovakia", "flag": "🇸🇰", "code": "SK", "dial_code": "+421"},
    {"name": "Slovenia", "flag": "🇸🇮", "code": "SI", "dial_code": "+386"},
    {
      "name": "Solomon Islands",
      "flag": "🇸🇧",
      "code": "SB",
      "dial_code": "+677"
    },
    {"name": "Somalia", "flag": "🇸🇴", "code": "SO", "dial_code": "+252"},
    {"name": "South Africa", "flag": "🇿🇦", "code": "ZA", "dial_code": "+27"},
    {"name": "South Sudan", "flag": "🇸🇸", "code": "SS", "dial_code": "+211"},
    {
      "name": "South Georgia and the South Sandwich Islands",
      "flag": "🇬🇸",
      "code": "GS",
      "dial_code": "+500"
    },
    {"name": "Spain", "flag": "🇪🇸", "code": "ES", "dial_code": "+34"},
    {"name": "Sri Lanka", "flag": "🇱🇰", "code": "LK", "dial_code": "+94"},
    {"name": "Sudan", "flag": "🇸🇩", "code": "SD", "dial_code": "+249"},
    {"name": "Suriname", "flag": "🇸🇷", "code": "SR", "dial_code": "+597"},
    {
      "name": "Svalbard and Jan Mayen",
      "flag": "🇸🇯",
      "code": "SJ",
      "dial_code": "+47"
    },
    {"name": "Swaziland", "flag": "🇸🇿", "code": "SZ", "dial_code": "+268"},
    {"name": "Sweden", "flag": "🇸🇪", "code": "SE", "dial_code": "+46"},
    {"name": "Switzerland", "flag": "🇨🇭", "code": "CH", "dial_code": "+41"},
    {
      "name": "Syrian Arab Republic",
      "flag": "🇸🇾",
      "code": "SY",
      "dial_code": "+963"
    },
    {"name": "Taiwan", "flag": "🇹🇼", "code": "TW", "dial_code": "+886"},
    {"name": "Tajikistan", "flag": "🇹🇯", "code": "TJ", "dial_code": "+992"},
    {
      "name": "Tanzania, United Republic of Tanzania",
      "flag": "🇹🇿",
      "code": "TZ",
      "dial_code": "+255"
    },
    {"name": "Thailand", "flag": "🇹🇭", "code": "TH", "dial_code": "+66"},
    {"name": "Timor-Leste", "flag": "🇹🇱", "code": "TL", "dial_code": "+670"},
    {"name": "Togo", "flag": "🇹🇬", "code": "TG", "dial_code": "+228"},
    {"name": "Tokelau", "flag": "🇹🇰", "code": "TK", "dial_code": "+690"},
    {"name": "Tonga", "flag": "🇹🇴", "code": "TO", "dial_code": "+676"},
    {
      "name": "Trinidad and Tobago",
      "flag": "🇹🇹",
      "code": "TT",
      "dial_code": "+1868"
    },
    {"name": "Tunisia", "flag": "🇹🇳", "code": "TN", "dial_code": "+216"},
    {"name": "Turkey", "flag": "🇹🇷", "code": "TR", "dial_code": "+90"},
    {"name": "Turkmenistan", "flag": "🇹🇲", "code": "TM", "dial_code": "+993"},
    {
      "name": "Turks and Caicos Islands",
      "flag": "🇹🇨",
      "code": "TC",
      "dial_code": "+1649"
    },
    {"name": "Tuvalu", "flag": "🇹🇻", "code": "TV", "dial_code": "+688"},
    {"name": "Uganda", "flag": "🇺🇬", "code": "UG", "dial_code": "+256"},
    {"name": "Ukraine", "flag": "🇺🇦", "code": "UA", "dial_code": "+380"},
    {
      "name": "United Arab Emirates",
      "flag": "🇦🇪",
      "code": "AE",
      "dial_code": "+971"
    },
    {
      "name": "United Kingdom",
      "flag": "🇬🇧",
      "code": "GB",
      "dial_code": "+44"
    },
    {"name": "United States", "flag": "🇺🇸", "code": "US", "dial_code": "+1"},
    {"name": "Uruguay", "flag": "🇺🇾", "code": "UY", "dial_code": "+598"},
    {"name": "Uzbekistan", "flag": "🇺🇿", "code": "UZ", "dial_code": "+998"},
    {"name": "Vanuatu", "flag": "🇻🇺", "code": "VU", "dial_code": "+678"},
    {
      "name": "Venezuela, Bolivarian Republic of Venezuela",
      "flag": "🇻🇪",
      "code": "VE",
      "dial_code": "+58"
    },
    {"name": "Vietnam", "flag": "🇻🇳", "code": "VN", "dial_code": "+84"},
    {
      "name": "Virgin Islands, British",
      "flag": "🇻🇬",
      "code": "VG",
      "dial_code": "+1284"
    },
    {
      "name": "Virgin Islands, U.S.",
      "flag": "🇻🇮",
      "code": "VI",
      "dial_code": "+1340"
    },
    {
      "name": "Wallis and Futuna",
      "flag": "🇼🇫",
      "code": "WF",
      "dial_code": "+681"
    },
    {"name": "Yemen", "flag": "🇾🇪", "code": "YE", "dial_code": "+967"},
    {"name": "Zambia", "flag": "🇿🇲", "code": "ZM", "dial_code": "+260"},
    {"name": "Zimbabwe", "flag": "🇿🇼", "code": "ZW", "dial_code": "+263"}
  ];

  TextStyle errorTextStle = const TextStyle(
      color: Colors.red, fontSize: 15, fontWeight: FontWeight.w600);

  String otpPin = '',
      verID = " ",
      dialCode = '',
      result = '',
      savedNumber = '',
      theCodeForPhone = 'ok',
      equalityCardID = "",
      userId = '',
      profilePictureStoragePath = '';

  int activeStep = 0,
      previouslyReachedStep = 0,
      indicatorCount = 2,
      secondsRemaining = 40,
      updateAndVerifNumCount = 0,
      navPopCounter = 0,
      listenableCounter = 0;
  int? resentToken;
  late Timer timer;

  bool isProfilePicturePicked = false,
      obscurText = true,
      obscurTextConfPass = true,
      isPhoneNumberValidated = false,
      pinSuccess = false,
      isSpecialAccessUser = false,
      textScanning = false,
      addedRectoCardImage = false,
      addedVersoCardImage = false,
      isEqualityCardValid = false,
      canShowCameraButtons = false,
      createdUserWithEmailAndPass = false,
      numberAutoVerfiedComplete = false,
      listeningForOTP = false,
      enableResend = false,
      backgroundWaiting = false;

  ValueNotifier<bool> foundPhoneMailMatch = ValueNotifier(true);

  PhoneNumber initializedNumber = PhoneNumber(
        isoCode: 'US',
        dialCode: '+1',
        phoneNumber: '',
      ),
      finalTest = PhoneNumber(
        isoCode: 'US',
        dialCode: '+1',
        phoneNumber: '',
      );

  final TextEditingController _emailController = TextEditingController(),
      _passwordController = TextEditingController(),
      _confirmPasswordController = TextEditingController(),
      _numberController = TextEditingController(),
      _fullNameController = TextEditingController();

  final OtpFieldController otpFieldController = OtpFieldController();

  final _pinMobileFormKey = GlobalKey<FormState>(),
      internatKey = GlobalKey<FormState>(),
      formKey = GlobalKey<FormState>(),
      regFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
    super.initState();

    getCarrierCode(countries).then((value) {
      setState(() {
        var ok = countries
            .where((element) => element['code'] == value.toUpperCase());
        initializedNumber = PhoneNumber(
            isoCode: value.toUpperCase(),
            dialCode: ok.first['dial_code'],
            phoneNumber: ' ');
      });
    });
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animationController.repeat(reverse: true);
    setState(() {});
    initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (listeningForOTP) {
        if (secondsRemaining != 0) {
          setState(() {
            secondsRemaining--;
          });
        } else {
          setState(() {
            enableResend = true;
          });
        }
      }
    });

    /*  SmsAutoFill().getAppSignature.then((signature) {
      setState(() {
        appSignature = signature;
      });
    }); */
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    //_numberController.dispose();
    _animationController.dispose();
    _numberController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _confirmPasswordController.dispose();
    _passwordController.dispose();
    _connectivitySubscription.cancel();
    _textRecognizer.close();

    super.dispose();
  }

  Future<String> getCarrierCode(List<Map<String, dynamic>> countries) async {
    String code = await countries.first['code'];
    return code;
  }

  Future<void> initConnectivity() async {
    late List<ConnectivityResult> result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print('Couldn\'t check connectivity status $e');
      return;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    setState(() {
      _connectionStatus = result.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    //previouslyReachedStep == 1 ? _numberController.clear() : null;
    currentUser = _auth.currentUser;
    //currentUser?.reload();
    currentUser != null ? print("CURRENTLY SIGNED IN USER $currentUser") : null;
    //foundNoMtachWhatsoever ? print("UHM AFTER SETSTATE $foundNoMtachWhatsoever") : null;

    _auth.setLanguageCode(Get.locale!.languageCode);
    equalityCardUploadedStoragePath.isEmpty
        ? null
        : equalityCardUploadedStoragePath.length == 2
            ? {
                print(
                    "equalityCardUploadedStoragePathYES $equalityCardUploadedStoragePath"),
                updateAndVerifNumCount < 1
                    ? updateEqualityCardStorageAndVerifyPhone()
                    : null,
                updateAndVerifNumCount += 1,
              }
            : null;

    var localLnSetting = AppLocalizations.of(context)!;
    var theCountry = countries.where((element) =>
        element['code'].toString().toLowerCase() == theCodeForPhone);
    theCountry.isNotEmpty
        ? {
            print(
                'HA ${theCountry.first} ${theCountry.first['flag'].runtimeType}'),
          }
        : null;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        backgroundColor: activeStep == 1 && isSpecialAccessUser
            ? Colors.grey.shade900
            : Colors.white,
        body: SingleChildScrollView(child: bodySwitch(localLnSetting)),
      ),
    );
  }

  Widget bodySwitch(AppLocalizations localLnSetting) {
    print(
        "THE DIALCODE: $dialCode ___ Connection Status: ${_connectionStatus.toString()}");
    var yesNoRadio = isSpecialAccessUser
        ? localLnSetting.regRadioYes
        : localLnSetting.regRadioNo;
    //email-already-exists add this case to register form ********************

    switch (activeStep) {
      case 0:
        return ValueListenableBuilder<bool>(
          valueListenable: foundPhoneMailMatch,
          builder: (context, listenableValue, child) {
            print("LISTENBALE VALUE $listenableValue");
            !listenableValue && listenableCounter < 1
                ? {
                    nextButtonSendOTP(
                        localLnSetting, regFormKey, listenableValue),
                    listenableCounter += 1
                  }
                : null;
            return Stack(
              children: [
                SizedBox(
                  height: 150,
                  child: HeaderWidget(
                    height: 150,
                    icon: Icons.person_add_alt_1_rounded,
                    showIcon: false,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(25, 50, 25, 10),
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Form(
                        key: regFormKey,
                        onChanged: () {
                          regFormKey.currentState!.save();
                          //print("THIS IS THE CURRENT STATE: ${regFormKey.currentState}");
                        },
                        child: Column(
                          children: [
                            GestureDetector(
                              child: Stack(
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    //padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(
                                          width: 5, color: Colors.white),
                                      color: Colors.white,
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 20,
                                          offset: Offset(5, 5),
                                        ),
                                      ],
                                    ),
                                    child: isProfilePicturePicked
                                        ? ClipOval(
                                            child: Image.file(
                                              File(profilePicture!.path),
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Icon(
                                            Icons.person,
                                            color: Colors.grey.shade300,
                                            size: 80.0,
                                          ),
                                  ),
                                  Container(
                                    padding:
                                        const EdgeInsets.fromLTRB(80, 80, 0, 0),
                                    child: IconButton(
                                        onPressed: () {
                                          getProfileOrCardImage(
                                              'profilePicture',
                                              '',
                                              localLnSetting);
                                        },
                                        icon: Icon(
                                          Icons.add_circle,
                                          color: Colors.grey.shade700,
                                          size: 25.0,
                                        )),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 30,
                            ),
                            Container(
                              decoration:
                                  ThemeHelper().inputBoxDecorationShaddow(),
                              child: TextFormField(
                                controller: _fullNameController,
                                autovalidateMode: AutovalidateMode.disabled,
                                keyboardType: TextInputType.name,
                                textCapitalization: TextCapitalization.words,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp("[A-Za-z' -]*"),
                                      replacementString: ''),
                                ],
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(),
                                ]),
                                decoration: ThemeHelper().textInputDecoration(
                                    Icons.perm_identity,
                                    localLnSetting.regFullNameLabel,
                                    localLnSetting.regFullNamePlaceholder),
                              ),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            Container(
                              decoration:
                                  ThemeHelper().inputBoxDecorationShaddow(),
                              child: TextFormField(
                                controller: _emailController,
                                decoration: ThemeHelper().textInputDecoration(
                                    Icons.email,
                                    localLnSetting.regEmailLabel,
                                    localLnSetting.regEmailPlaceholder),
                                keyboardType: TextInputType.emailAddress,
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(),
                                  FormBuilderValidators.match(
                                      RegExp(
                                        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$",
                                      ),
                                      errorText:
                                          localLnSetting.logErrorBadEmailFormat)
                                ]),
                              ),
                            ),
                            const SizedBox(height: 20.0),
                            InternationalPhoneNumberInput(
                              key: internatKey,
                              onInputChanged: (PhoneNumber changingNumber) {
                                print(
                                    "changingNumber ${changingNumber.phoneNumber}");
                              },
                              onInputValidated: (bool value) {
                                setState(() {
                                  isPhoneNumberValidated = value;
                                });
                                print('VALIDATED PHONE NUMBER $value');
                              },
                              locale: Get.locale!.languageCode,
                              selectorConfig: const SelectorConfig(
                                setSelectorButtonAsPrefixIcon: true,
                                trailingSpace: false,
                                selectorType: PhoneInputSelectorType.DROPDOWN,
                              ),
                              inputDecoration: InputDecoration(
                                labelText: localLnSetting.regNumberLabel,
                                hintText: localLnSetting.regNumberPlaceholder,
                                fillColor: Colors.white,
                                filled: true,
                                contentPadding:
                                    const EdgeInsets.fromLTRB(20, 10, 0, 10),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(100.0),
                                    borderSide:
                                        const BorderSide(color: Colors.grey)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(100.0),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade400)),
                                errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(100.0),
                                    borderSide: const BorderSide(
                                        color: Colors.red, width: 2.0)),
                                focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(100.0),
                                    borderSide: const BorderSide(
                                        color: Colors.red, width: 2.0)),
                              ),
                              ignoreBlank: false,
                              errorMessage: localLnSetting.regNumberError,
                              autoValidateMode: AutovalidateMode.disabled,
                              selectorTextStyle:
                                  const TextStyle(color: Colors.black),
                              initialValue: initializedNumber,
                              textFieldController: _numberController,
                              formatInput: false,
                              keyboardType:
                                  const TextInputType.numberWithOptions(),
                              onSaved: (PhoneNumber thenumber) {
                                print('On Saved: $thenumber');
                                setState(() {
                                  finalTest = thenumber;
                                });
                              },
                            ),
                            const SizedBox(height: 20.0),
                            Container(
                              decoration:
                                  ThemeHelper().inputBoxDecorationShaddow(),
                              child: TextFormField(
                                  autovalidateMode: AutovalidateMode.disabled,
                                  validator: FormBuilderValidators.compose([
                                    FormBuilderValidators.required(),
                                    FormBuilderValidators.match(
                                        RegExp(
                                            r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$'),
                                        errorText:
                                            localLnSetting.regPasswordHelper),
                                    FormBuilderValidators.minLength(8)
                                  ]),
                                  controller: _passwordController,
                                  obscureText: obscurText,
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(
                                      Icons.lock,
                                      size: 25,
                                      //color: Color.fromARGB(173, 0, 0, 0),
                                    ),
                                    suffixIcon: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          obscurText == true
                                              ? obscurText = false
                                              : obscurText = true;
                                        });
                                      },
                                      child: Icon(obscurText
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined),
                                    ),
                                    labelText: localLnSetting.regPasswordLabel,
                                    hintText:
                                        localLnSetting.regPasswordPlaceholder,
                                    fillColor: Colors.white,
                                    filled: true,
                                    helperText:
                                        localLnSetting.regPasswordHelper,
                                    helperMaxLines: 1,

                                    // helperStyle: TextStyle(height: 0.4),
                                    contentPadding: const EdgeInsets.fromLTRB(
                                        20, 10, 20, 10),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(100.0),
                                        borderSide: const BorderSide(
                                            color: Colors.grey)),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(100.0),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade400)),
                                    errorBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(100.0),
                                        borderSide: const BorderSide(
                                            color: Colors.red, width: 2.0)),
                                    focusedErrorBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(100.0),
                                        borderSide: const BorderSide(
                                            color: Colors.red, width: 2.0)),
                                  )),
                            ),
                            const SizedBox(height: 20.0),
                            Container(
                              decoration:
                                  ThemeHelper().inputBoxDecorationShaddow(),
                              child: TextFormField(
                                  autovalidateMode: AutovalidateMode.disabled,
                                  validator: FormBuilderValidators.compose([
                                    FormBuilderValidators.required(),
                                    FormBuilderValidators.match(
                                        RegExp(
                                            r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$'),
                                        errorText:
                                            localLnSetting.regConfirmPassError),
                                    FormBuilderValidators.minLength(8),
                                  ]),
                                  controller: _confirmPasswordController,
                                  obscureText: obscurTextConfPass,
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(
                                      Icons.lock,
                                      size: 25,
                                      //color: Color.fromARGB(173, 0, 0, 0),
                                    ),
                                    suffixIcon: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          obscurTextConfPass == true
                                              ? obscurTextConfPass = false
                                              : obscurTextConfPass = true;
                                        });
                                      },
                                      child: Icon(obscurTextConfPass
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined),
                                    ),
                                    labelText:
                                        localLnSetting.regConfirmPassLabel,
                                    hintText: localLnSetting
                                        .regConfirmPassPlaceholder,
                                    fillColor: Colors.white,
                                    filled: true,
                                    contentPadding: const EdgeInsets.fromLTRB(
                                        20, 10, 0, 10),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(100.0),
                                        borderSide: const BorderSide(
                                            color: Colors.grey)),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(100.0),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade400)),
                                    errorBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(100.0),
                                        borderSide: const BorderSide(
                                            color: Colors.red, width: 2.0)),
                                    focusedErrorBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(100.0),
                                        borderSide: const BorderSide(
                                            color: Colors.red, width: 2.0)),
                                  )),
                            ),
                            FormBuilderRadioGroup(
                              initialValue: yesNoRadio,
                              wrapSpacing: 10,
                              wrapAlignment: WrapAlignment.center,
                              decoration: InputDecoration(
                                prefixIcon: FadeTransition(
                                  opacity: _animationController,
                                  child: GestureDetector(
                                      onTap: () async {
                                        await showDialog(
                                            context: context,
                                            builder: (context) {
                                              return ThemeHelper().alartDialog(
                                                  'Description',
                                                  localLnSetting
                                                      .regEgaliteChancesDescription,
                                                  context);
                                            });
                                      },
                                      child: const Icon(
                                        Icons.accessible,
                                        size: 30,
                                        color: Colors.blue,
                                      )),
                                ),
                                alignLabelWithHint: true,
                                labelText: localLnSetting.regEgaliteDesChances,
                                labelStyle: const TextStyle(height: 2),
                                contentPadding:
                                    const EdgeInsets.fromLTRB(0, 10, 0, 0),
                              ),
                              name: 'egaliteDesChances',
                              validator: FormBuilderValidators.required(),
                              onSaved: (newValue) {
                                setState(() {
                                  newValue == localLnSetting.regRadioYes
                                      ? isSpecialAccessUser = true
                                      : isSpecialAccessUser = false;
                                });
                                print("ISSPECIALACCESS $isSpecialAccessUser");
                              },
                              options: [
                                localLnSetting.regRadioYes,
                                localLnSetting.regRadioNo
                              ]
                                  .map((lang) => FormBuilderFieldOption(
                                        value: lang,
                                      ))
                                  .toList(growable: false),
                            ),
                            const SizedBox(height: 55.0),
                            nextAndAnimatedSmoothIndic(
                                localLnSetting,
                                localLnSetting.regNextButton.toUpperCase(),
                                listenableValue),
                            Container(
                              margin: const EdgeInsets.fromLTRB(10, 20, 10, 20),
                              //child: Text('Don\'t have an account? Create'),
                              child: Text.rich(TextSpan(children: [
                                TextSpan(
                                    text: localLnSetting.alreadyHaveAccount),
                                TextSpan(
                                  text: localLnSetting.regGoToLogInLink,
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const TestLogin()));
                                    },
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      fontSize: 15),
                                ),
                              ])),
                            ),
                            const SizedBox(height: 30.0),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );

      case 1:
        const republiqueSenegalStyle =
            TextStyle(fontSize: 15, fontWeight: FontWeight.w500);
        const cardContentForLabel = TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
        );
        const cardlabelName = TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.underline);
        return isSpecialAccessUser == false
            ? Stack(children: [
                SizedBox(
                  height: 300,
                  child: HeaderWidget(
                    height: 300,
                    icon: Icons.person_add_alt_1_rounded,
                    showIcon: false,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(25, 50, 25, 10),
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            //color: Colors.white,
                            //padding: EdgeInsets.all(1),
                            onPressed: () {
                              backgroundWaiting
                                  ? null
                                  : setState(() {
                                      previouslyReachedStep = 1;
                                      backgroundWaiting = false;
                                      _numberController.clear();
                                      activeStep = 0;
                                    });
                            },
                            icon: const Icon(
                              Icons.keyboard_backspace_rounded,
                              size: 30,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 4),
                                    blurRadius: 5.0)
                              ],
                            ),
                            splashRadius: 20,
                          ),
                        ],
                      ),
                      CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: 0.5),
                        radius: 70,
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 200,
                        ),
                      ),
                      SafeArea(
                        child: Container(
                          margin: const EdgeInsets.only(top: 50),
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                alignment: Alignment.topLeft,
                                margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      localLnSetting.numVerifHeader,
                                      style: const TextStyle(
                                          fontSize: 35,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54),
                                      // textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      '${localLnSetting.numVerifBody} ${finalTest.phoneNumber}',
                                      style: const TextStyle(
                                          // fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54),
                                      // textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 40.0),
                              Form(
                                key: _pinMobileFormKey,
                                child: Column(
                                  children: <Widget>[
                                    SizedBox(
                                      width: 200,
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: OTPTextField(
                                              length: 6,
                                              width: 200,
                                              controller: otpFieldController,
                                              fieldWidth: 30,
                                              style:
                                                  const TextStyle(fontSize: 30),
                                              textFieldAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              fieldStyle: FieldStyle.underline,
                                              onChanged: (value) {
                                                setState(
                                                  () {
                                                    otpPin = value;
                                                  },
                                                );
                                              },
                                              onCompleted: (pin) {
                                                setState(() {
                                                  pinSuccess = true;
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 50.0),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: localLnSetting
                                                .numVerifDidntReceiveCode,
                                            style: const TextStyle(
                                              color: Colors.black38,
                                            ),
                                          ),
                                          TextSpan(
                                            text: localLnSetting
                                                .numVerifResendCode,
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                enableResend
                                                    ? resendCode(
                                                        "${finalTest.dialCode.toString()} ${_numberController.text}")
                                                    : null;
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return ThemeHelper()
                                                        .alartDialog(
                                                            "Successful",
                                                            "Verification code resend successful.",
                                                            context);
                                                  },
                                                );
                                              },
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 40.0),
                                    nextAndAnimatedSmoothIndic(
                                        localLnSetting,
                                        localLnSetting.numVerifButtonLabel
                                            .toUpperCase()),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ])
            : Column(
                children: [
                  SizedBox(
                    height: 150,
                    child: GestureDetector(
                      onTap: () {
                        print(
                            "JUST TAPPED ON BACK _ backgriundwaiitng $backgroundWaiting");
                        backgroundWaiting
                            ? null
                            : setState(() {
                                previouslyReachedStep = 1;
                                _numberController.clear();
                                backgroundWaiting = false;
                                activeStep = 0;
                              });
                      },
                      child: HeaderWidget(
                        height: 150,
                        icon: Icons.keyboard_backspace_rounded,
                        showIcon: true,
                        fromScanner: true,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            height: 300,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.grey.shade800,
                            ),
                            /*   child: Container(
                        decoration: BoxDecoration(
                            // borderRadius: BorderRadius.circular(25),
                            /* boxShadow: [
                                BoxShadow(
                                    color: Color.fromARGB(70, 255, 255, 255),
                                    blurRadius: 5.0, // soften the shadow
                                    spreadRadius: 3.0, //extend the shadow
                                    offset: Offset(
                                      5.0, // Move to right 5  horizontally
                                      5.0, // Move to bottom 5 Vertically
                                    )),
                              ],  */
                            color: Colors.grey[500]!,
                            border: Border.all(color: Colors.black, width: 2)),
                        padding: const EdgeInsets.all(10),
                        width: 400,
                        height: 300, */
                            child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: equalityCardRectoVerso.isNotEmpty
                                          ? Image.file(
                                              File(equalityCardRectoVerso
                                                  .first!.path),
                                            )
                                          : Container(),
                                    ),
                                    const SizedBox(width: 30),
                                    Flexible(
                                      child: equalityCardRectoVerso.length == 2
                                          ? Image.file(
                                              File(equalityCardRectoVerso
                                                  .last!.path),
                                            )
                                          : Container(),
                                    )
                                  ],
                                )),
                            //),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              canShowCameraButtons == false
                                  ? Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 5),
                                      padding: const EdgeInsets.only(top: 10),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.grey,
                                          backgroundColor: Colors.white,
                                          shadowColor: Colors.grey[400],
                                          elevation: 10,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0)),
                                        ),
                                        onPressed: () {
                                          getProfileOrCardImage('cardGallery',
                                              '', localLnSetting);
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 5, horizontal: 5),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.image,
                                                size: 30,
                                              ),
                                              Text(
                                                "Gallery",
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[600]),
                                              )
                                            ],
                                          ),
                                        ),
                                      ))
                                  : Container(),
                              canShowCameraButtons == true
                                  ? Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 5),
                                      padding: const EdgeInsets.only(top: 10),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.grey,
                                          backgroundColor: Colors.white,
                                          shadowColor: Colors.grey[400],
                                          elevation: 10,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0)),
                                        ),
                                        onPressed: () {
                                          getProfileOrCardImage('camera',
                                              'recto', localLnSetting);
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 5, horizontal: 5),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.camera_front,
                                                size: 30,
                                              ),
                                              Text(
                                                "Recto",
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[600]),
                                              )
                                            ],
                                          ),
                                        ),
                                      ))
                                  : Container(),
                              canShowCameraButtons == true
                                  ? Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 5),
                                      padding: const EdgeInsets.only(top: 10),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.grey,
                                          backgroundColor: Colors.white,
                                          shadowColor: Colors.grey[400],
                                          elevation: 10,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0)),
                                        ),
                                        onPressed: () {
                                          getProfileOrCardImage('camera',
                                              'verso', localLnSetting);
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 5, horizontal: 5),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.photo_camera_back,
                                                size: 30,
                                              ),
                                              Text(
                                                "Verso",
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[600]),
                                              )
                                            ],
                                          ),
                                        ),
                                      ))
                                  : Container(),
                              canShowCameraButtons == false
                                  ? Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 5),
                                      padding: const EdgeInsets.only(top: 10),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.grey,
                                          backgroundColor: Colors.white,
                                          shadowColor: Colors.yellow[400],
                                          elevation: 10,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0)),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            canShowCameraButtons = true;
                                            addedRectoCardImage = false;
                                            addedVersoCardImage = false;
                                          });
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 5, horizontal: 5),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.camera_alt,
                                                size: 30,
                                              ),
                                              Text(
                                                "Camera",
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[600]),
                                              )
                                            ],
                                          ),
                                        ),
                                      ))
                                  : Container(),
                            ],
                          ),
                          const SizedBox(
                            height: 40,
                          ),
                          nextAndAnimatedSmoothIndic(
                            localLnSetting,
                            localLnSetting.regNextButton.toUpperCase(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );

      case 2:
        const republiqueSenegalStyle =
            TextStyle(fontSize: 15, fontWeight: FontWeight.w500);
        const cardContentForLabel = TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
        );
        const cardlabelName = TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.underline);
        return Stack(children: [
          SizedBox(
            height: 300,
            child: HeaderWidget(
              height: 300,
              icon: Icons.person_add_alt_1_rounded,
              showIcon: false,
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(25, 50, 25, 10),
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            alignment: Alignment.center,
            child: Column(
              children: [
                /* Row(
                  children: [
                    IconButton(
                      //color: Colors.white,
                      //padding: EdgeInsets.all(1),
                      onPressed: () {
                        setState(() {
                          previouslyReachedStep = 1;
                          _numberController.clear();
                          activeStep = 0;
                        });
                      },
                      icon: const Icon(
                        Icons.keyboard_backspace_rounded,
                        size: 30,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 5.0)],
                      ),
                      splashRadius: 20,
                    ),
                  ],
                ), */
                CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.5),
                  radius: 70,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 200,
                  ),
                ),
                SafeArea(
                  child: Container(
                    margin: const EdgeInsets.only(top: 50),
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          alignment: Alignment.topLeft,
                          margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localLnSetting.numVerifHeader,
                                style: const TextStyle(
                                    fontSize: 35,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54),
                                // textAlign: TextAlign.center,
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Text(
                                '${localLnSetting.numVerifBody} ${finalTest.phoneNumber}',
                                style: const TextStyle(
                                    // fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54),
                                // textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40.0),
                        /*  Padding(
                          padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
                          child: Text(
                            "This is the current app signature: $appSignature",
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Builder(
                            builder: (_) {
                              if (otpCode == null) {
                                return Text("Listening for code...");
                              }
                              return Text("Code Received: $otpCode");
                            },
                          ),
                        ),
                        */
                        Form(
                          key: _pinMobileFormKey,
                          child: Column(
                            children: <Widget>[
                              SizedBox(
                                width: 200,
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: OTPTextField(
                                        length: 6,
                                        width: 200,
                                        controller: otpFieldController,
                                        fieldWidth: 30,
                                        style: const TextStyle(fontSize: 30),
                                        textFieldAlignment:
                                            MainAxisAlignment.spaceAround,
                                        fieldStyle: FieldStyle.underline,
                                        onChanged: (value) {
                                          setState(
                                            () {
                                              otpPin = value;
                                            },
                                          );
                                        },
                                        onCompleted: (pin) {
                                          setState(() {
                                            pinSuccess = true;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 50.0),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: localLnSetting
                                          .numVerifDidntReceiveCode,
                                      style: const TextStyle(
                                        color: Colors.black38,
                                      ),
                                    ),
                                    TextSpan(
                                      text: localLnSetting.numVerifResendCode,
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          enableResend
                                              ? resendCode(
                                                  "${finalTest.dialCode.toString()} ${_numberController.text}")
                                              : null;
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return ThemeHelper().alartDialog(
                                                  "Successful",
                                                  "Verification code resend successful.",
                                                  context);
                                            },
                                          );
                                        },
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 40.0),
                              nextAndAnimatedSmoothIndic(
                                  localLnSetting,
                                  localLnSetting.numVerifButtonLabel
                                      .toUpperCase()),

                              /*    AnimatedSmoothIndicator(
                                activeIndex: activeStep,
                                duration: const Duration(milliseconds: 400),
                                count: isSpecialAccessUser ? indicatorCount = 3 : indicatorCount = 2,
                                effect: const WormEffect(
                                    type: WormType.normal,
                                    spacing: 5.0,
                                    radius: 20.0,
                                    dotWidth: 10.0,
                                    dotHeight: 10.0,
                                    paintStyle: PaintingStyle.stroke,
                                    strokeWidth: 1.5,
                                    dotColor: Colors.black,
                                    activeDotColor: Colors.indigo),
                              ),
                              const SizedBox(height: 40.0),
                              Container(
                                decoration: _pinSuccess
                                    ? ThemeHelper().buttonBoxDecoration(context)
                                    : ThemeHelper().buttonBoxDecoration(context, "#AAAAAA", "#757575"),
                                child: ElevatedButton(
                                  style: ThemeHelper().buttonStyle(),
                                  onPressed: _pinSuccess
                                      ? () {
                                          if (otpPin.length >= 6) {
                                            /*  onAutoVerify(
                                                PhoneAuthProvider.credential(verificationId: verID, smsCode: otpPin)); */
                                            //  verifyOTP();
                                          }
                                          /*  Navigator.of(context).pushAndRemoveUntil(
                                            MaterialPageRoute(builder: (context) => const ProfilePage()),
                                            (Route<dynamic> route) => false); */
                                        }
                                      : null,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(40, 10, 40, 10),
                                    child: Text(
                                      localLnSetting.numVerifButtonLabel.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                           */
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        ]);

      default:
        return const SizedBox.shrink();
    }
  }

  Column nextAndAnimatedSmoothIndic(
      AppLocalizations localLnSetting, String buttonLabel,
      [bool listenableValue = true]) {
    return Column(
      children: [
        AnimatedSmoothIndicator(
          activeIndex: activeStep,
          duration: const Duration(milliseconds: 400),
          count: isSpecialAccessUser ? indicatorCount = 3 : indicatorCount = 2,
          effect: WormEffect(
              type: WormType.normal,
              spacing: 5.0,
              radius: 20.0,
              dotWidth: 10.0,
              dotHeight: 10.0,
              paintStyle: PaintingStyle.stroke,
              strokeWidth: 1.5,
              dotColor: activeStep == 1 && isSpecialAccessUser
                  ? Colors.white
                  : Colors.black,
              activeDotColor: activeStep == 1 && isSpecialAccessUser
                  ? Colors.brown
                  : Colors.indigo),
        ),
        const SizedBox(height: 25.0),
        Container(
          decoration: listeningForOTP
              ? ThemeHelper().buttonBoxDecoration(context, '808080', '7393B3')
              : ThemeHelper().buttonBoxDecoration(context),
          child: activeStep == 2 || (activeStep == 1 && !isSpecialAccessUser)
              ? Container()
              : ElevatedButton(
                  style: activeStep == 1 && isSpecialAccessUser
                      ? ThemeHelper().buttonStyle('scanner')
                      : ThemeHelper().buttonStyle(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(40, 10, 40, 10),
                    child: Text(
                      buttonLabel, //  localLnSetting.regNextButton.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  onPressed: () {
                    if (activeStep == 0 && isSpecialAccessUser) {
                      nextButtonGoToCardScanner(
                          localLnSetting, regFormKey, listenableValue);
                    } else {
                      print("BACKGROUND WAITING? $backgroundWaiting");
                      !backgroundWaiting
                          ? {
                              nextButtonSendOTP(
                                  localLnSetting, regFormKey, listenableValue),
                            }
                          : null;
                    }
                  }),
        ),
      ],
    );
  }

  void nextButtonSendOTP(AppLocalizations localLnSetting,
      GlobalKey<FormState> regFormKey, bool listenableValue) async {
    if (_connectionStatus.toString() == 'ConnectivityResult.none') {
      showSnackBarText(localLnSetting.noInternetError);
    } else {
      await formFieldsValidationAndAction(
              localLnSetting, listenableValue, regFormKey,
              action: 'sendOTP')
          .then((fieldsValideAndNoNumberEmailMatch) {
        print(
            "I WAITED. Proceed ? $fieldsValideAndNoNumberEmailMatch ________ $listenableValue ");
        listenableValue == false && fieldsValideAndNoNumberEmailMatch == true ||
                activeStep == 1 &&
                    fieldsValideAndNoNumberEmailMatch == true //put back true
            ? {
                //setState(() => backgroundWaiting = true),
                Future.delayed(
                    Duration.zero,
                    (() async => await showDialog(
                            barrierColor: activeStep != 1
                                ? Colors.black.withValues(alpha: 0.4)
                                : Colors.black87.withValues(alpha: 0.7),
                            context: context,
                            barrierDismissible: false,
                            builder: (context) {
                              return waitingBackgoundProcessDialog(
                                  context, localLnSetting);
                            }).then((value) {
                          /* setState(
                            () => backgroundWaiting = false,
                          ); */
                          print("YOU EXITED");
                        })))
              }
            : Container();
      });

      /* listenableValue == false
          ? {
              Future.delayed(
                  Duration.zero,
                  (() async => await showDialog(
                      barrierColor: Colors.black87,
                      context: context,
                      barrierDismissible: false,
                      builder: (context) {
                        print("PROCEED OTP? $proceed");
                        return waitingBackgoundProcessDialog(context, localLnSetting);
                      })))
            }
          : Container(); */
    }
  }

  AlertDialog waitingBackgoundProcessDialog(
      BuildContext context, AppLocalizations localLnSetting) {
    registerUserWithMailPass(localLnSetting);
    return AlertDialog(
        backgroundColor: activeStep != 1
            ? const Color.fromARGB(218, 255, 255, 255).withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.6),
        scrollable: true,
        content: Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 20),
          child: SpinKitFadingCircle(
              size: activeStep != 1 ? 50 : 60,
              itemBuilder: (BuildContext context, int index) {
                return DecoratedBox(
                  decoration: BoxDecoration(
                      color: activeStep != 1 ? Colors.green : Colors.brown,
                      shape: BoxShape.circle),
                );
              }),
        )

        /* actions: [
        TextButton(
          style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.black38)),
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            "OK",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ], */
        );
  }

  Future<bool> formFieldsValidationAndAction(AppLocalizations localLnSetting,
      bool listenableValue, GlobalKey<FormState> regFormKey,
      {required String action}) async {
    print("formFieldsValidationAndAction CALLED FIRST");
    var proceed = !listenableValue;
    action == 'goToScanner'
        ? print(
            "THIS IS THE CURRENT STATE GO SCANNER: ${_emailController.text}")
        : print("THIS IS THE CURRENT STATE SEND OTP}");

    var matchingPasswords =
        toastValidationMessages(_confirmPasswordController.text, localLnSetting)
            .toString();

    if (activeStep == 0) {
      /* MEANING action == 'goToScanner' || (action == 'sendOTP' &&  */
      Future.delayed(Duration.zero, () async {
        if (matchingPasswords.isEmpty && regFormKey.currentState!.validate()) {
          findMatchingPhoneAndEmailInDatabase(action).then((value) {
            proceed = value;
            print("FINDING MATCH ${!value}. PROCEED $proceed");
          });
        }
      });
    }

    /*  if (action != 'goToScanner' && activeStep == 1) {
      proceed = true;
      /* setState(() {
        activeStep = 2;
      }); //no need to specify here as the incremeent will be done after registerUser is called */
    } */

    return proceed;
  }

  void nextButtonGoToCardScanner(
    AppLocalizations localLnSetting,
    GlobalKey<FormState> regFormKey,
    bool listenableValue,
  ) {
    if (_connectionStatus.toString() == 'ConnectivityResult.none') {
      showSnackBarText(localLnSetting.noInternetError);
    } else {
      formFieldsValidationAndAction(localLnSetting, listenableValue, regFormKey,
          action: 'goToScanner');
    }
  }

  Future<void> updateEqualityCardStorageAndVerifyPhone() async {
    print("UPDATING EQUALITY CARD");
    if (currentUser != null) {
      print("ID OF USER ${currentUser!.uid}");
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({
        'Equality Card Images': equalityCardUploadedStoragePath
      }).whenComplete(() {
        setState(
          () {
            backgroundWaiting = false;
            isSpecialAccessUser ? activeStep = 2 : activeStep = 1;
          },
        );
        if (!mounted) return;
        Navigator.pop(context);
        verifyPhone(
            '${finalTest.dialCode.toString()} ${_numberController.text}');
      });
    } else {
      print("NOT EQUAL TO TWO");
    }
  }

  Future<void> registerUserWithMailPass(AppLocalizations localLnSetting) async {
    backgroundWaiting = true;
    List<String> testEquality = [];
    if (_connectionStatus.toString() != 'ConnectivityResult.none') {
      await registerWithEmailPassword().then((singingvalue) async {
        setState(() {
          singingvalue != null ? currentUser = singingvalue.user : null;
        });

        isProfilePicturePicked && singingvalue != null
            ? await StorageService()
                .updloadProfilePicture(File(profilePicture!.path))
                .then((value) => profilePictureStoragePath = value)
            : null;
        if (currentUser != null) {
          myDB
              .collection("users/${currentUser!.uid}/wallet")
              .get()
              .then((walletValue) async {
            debugPrint("CHECK MIC: ${walletValue.docs.length}");
            await firestoreWalletService
                .initializeWalletDebitTopUp(
                    currentUser, walletValue.docs.first.id)
                .whenComplete(
                    () => Future.delayed(const Duration(seconds: 2)).then(
                          (value) {
                            updateWalletFields(walletValue,
                                walletValue.docs.first.id, currentUser!);
                          },
                        ));
          });
        }
      });
      if (isSpecialAccessUser) {
        if (isEqualityCardValid) {
          equalityCardRectoVerso.forEach((element) async {
            await StorageService()
                .updloadEqualityCard(
                    File(element!.path), element.hashCode.toString())
                .then((value) {
              print("RESULT FROM UPLOAD :$value");
              equalityCardUploadedStoragePath.length < 2
                  ? equalityCardUploadedStoragePath.add(value)
                  : equalityCardUploadedStoragePath.length == 2
                      ? updateEqualityCardStorageAndVerifyPhone()
                      : null;
              print(
                  "testEquality.length :${equalityCardUploadedStoragePath.length}");
              setState(() {});
            });
          });
        } else {
          showSnackBarText("The card needs to be valid to proceed");
        }
      } else {
        print("NOT SPECIAL USER, going to otp screen");
        setState(
          () {
            backgroundWaiting = false;
            isSpecialAccessUser ? activeStep = 2 : activeStep = 1;
          },
        );
        if (!mounted) return;
        Navigator.pop(context);

        verifyPhone(
            '${finalTest.dialCode.toString()} ${_numberController.text}');
      }
    } else {
      showSnackBarText(localLnSetting.noInternetError);
    }
  }

  Future<void> takeQrScreenshot() async {
    final rectoScreenshot = await rectoScreenshotController.capture();
    if (rectoScreenshot == null) return;
    await saveImage(rectoScreenshot);
    final versoScreenshot = await versoScreenshotController.capture();
    if (versoScreenshot == null) return;
    await saveImage(versoScreenshot);
  }

  Future<dynamic> saveImage(Uint8List imageBytes) async {
    final result = await Gal.putImageBytes(imageBytes, name: 'cardScreenshot');
    return result;
  }

  Container displayEqualityCard(
      String codeBarQrPathImage,
      String wheelchairEmergentPathImage,
      TextStyle republiqueSenegalStyle,
      TextStyle cardContentForLabel,
      TextStyle cardlabelName) {
    return Container(
      width: 400,
      height: 600,
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.1), //color of shadow
          spreadRadius: 5, //spread radius
          blurRadius: 7, // blur radius
          offset: const Offset(0, 5), // changes position of shadow
          //first paramerter of offset is left-right
          //second parameter is top to down
        )
      ]),
      child: Card(
        elevation: 2,
        color: Colors.white24,
        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: const BorderSide(color: Colors.white)),
        child: Column(children: [
          Container(
            decoration: const BoxDecoration(
                color: Colors.white, //Colors.red,
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(25),
                    topLeft: Radius.circular(25))),
            height: 40,
            child: Align(
                child: Text('République du Sénégal',
                    style: republiqueSenegalStyle)),
          ),
          Container(
            height: 100,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/images/mayneed.png'),
                fit: BoxFit.fitWidth,
                colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.25), BlendMode.dstATop),
              ),
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Colors.orange,
                  Color.fromARGB(255, 255, 201, 39),
                  Colors.orange,
                  Color.fromARGB(255, 255, 201, 39),
                  Colors.red,
                ],
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'DGAS',
                  style: TextStyle(fontSize: 55, fontWeight: FontWeight.w900),
                ),
                Flexible(
                    child: Container(
                        margin: const EdgeInsets.only(left: 15, right: 15),
                        child: const Text(
                            "Direction Générale de l'Action Sociale",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800))))
              ],
            ),
          ),
          Flexible(
              child: Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(25),
                  bottomLeft: Radius.circular(25)),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Flexible(
                  child: Column(
                    children: [
                      Flexible(
                        child: Row(
                          children: [
                            Flexible(
                              child: Container(
                                decoration: BoxDecoration(
                                    image: const DecorationImage(
                                        image: AssetImage(
                                            'assets/images/no_profile_picture_grey.png'),
                                        fit: BoxFit.contain),
                                    color: Colors.grey.shade200 //Colors.blue,
                                    ),
                              ),
                            ),
                            Flexible(
                              child: Container(
                                padding: kTabLabelPadding,
                                //color: Colors.brown,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Flexible(
                                      child: FittedBox(
                                        child: Text(
                                          'Nom',
                                          style: cardlabelName,
                                        ),
                                      ),
                                    ),
                                    FittedBox(
                                      child: Text(
                                        'NOM',
                                        style: cardContentForLabel,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    FittedBox(
                                      child:
                                          Text('Prénom', style: cardlabelName),
                                    ),
                                    FittedBox(
                                      child: Text('PRENOM',
                                          style: cardContentForLabel),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    FittedBox(
                                        child: Text(
                                      'Date de naissance',
                                      style: cardlabelName,
                                    )),
                                    FittedBox(
                                      child: Text('JJ/MM/AAAA',
                                          style: cardContentForLabel),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    FittedBox(
                                      child: Text(
                                        'Lieu de naissance',
                                        style: cardlabelName,
                                      ),
                                    ),
                                    FittedBox(
                                        child: Text('LIEU',
                                            style: cardContentForLabel)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Row(
                          children: [
                            Flexible(
                              child: Column(
                                children: [
                                  Flexible(
                                      // ignore: avoid_unnecessary_containers
                                      child: Container(
                                    // color: Colors.pinkAccent,
                                    padding: const EdgeInsets.only(
                                        top: 10.0, left: 10, bottom: 10),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: wheelchairEmergentPathImage ==
                                              'assets/images/wheelchair.png'
                                          ? [
                                              const RotatedBox(
                                                  quarterTurns: -1,
                                                  child: Text('0000000000')),
                                              SizedBox(
                                                  width: 100,
                                                  child: QrImageView(
                                                    data:
                                                        '00000000000000000000',
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 10.0),
                                                  ))
                                            ]
                                          : [
                                              const RotatedBox(
                                                  quarterTurns: -1,
                                                  child: Text('12345678')),
                                              Flexible(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          15, 10, 0, 10),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                        image: DecorationImage(
                                                      image: AssetImage(
                                                          codeBarQrPathImage),
                                                      fit: BoxFit.fitWidth,
                                                    )),
                                                  ),
                                                ),
                                              )
                                            ],
                                    ),
                                  )),
                                  Flexible(
                                      child: Container(
                                    width: 200,
                                    decoration: const BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(25)),
                                      color: Colors.black87,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Text(
                                          'ME',
                                          style: cardContentForLabel.copyWith(
                                              fontSize: 25,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white),
                                        ),
                                        Text('00000',
                                            style: cardContentForLabel.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700)),
                                        Text('LIEU DELIVRANCE',
                                            style: cardContentForLabel.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ))
                                ],
                              ),
                            ),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.only(left: 10),
                                decoration: const BoxDecoration(
                                    //color: Colors.orange,
                                    ),
                                child: Container(
                                  decoration: BoxDecoration(
                                      image: DecorationImage(
                                    //  colorFilter: ColorFilter.mode(Colors.black.withValues(alpha:0.25), BlendMode.dstATop),
                                    image:
                                        AssetImage(wheelchairEmergentPathImage),
                                    fit: BoxFit.contain,
                                  )),
                                ),

                                //width: 172,
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 30,
                  decoration: const BoxDecoration(
                      // borderRadius: BorderRadius.only(bottomRight: Radius.circular(25)),
                      // color: Colors.black,
                      color: Colors.white),
                  child: const RotatedBox(
                    quarterTurns: -1,
                    child: Text(
                      'Certification de handicap',
                      style: TextStyle(
                          color: Colors.black,
                          wordSpacing: 2,
                          letterSpacing: 2,
                          fontSize: 18),
                    ),
                  ),
                )
              ],
            ),
          )),
        ]),
      ),
    );
  }

  void getProfileOrCardImage(String purpose, String cardRectoOrVerso,
      AppLocalizations localLnSetting) async {
    purpose == 'profilePicture'
        ? getProfilePicture(ImageSource.gallery)
        : purpose == 'cardGallery'
            ? getEqualityCardImage(ImageSource.gallery, '', localLnSetting)
            : getEqualityCardImage(
                ImageSource.camera, cardRectoOrVerso, localLnSetting);
  }

  void showSnackBarText(String text,
      [TextStyle snackStyle =
          const TextStyle(color: Colors.white, fontSize: 15)]) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 50,
          behavior: SnackBarBehavior.floating,
          content: Text(
            text,
            style: snackStyle,
          ),
        ),
      );
    }
  }

  String? toastValidationMessages(
      String? value, AppLocalizations localLnSetting) {
    String theMessage = '';
    if (_passwordController.text != _confirmPasswordController.text &&
        _passwordController.text.isNotEmpty) {
      theMessage = localLnSetting.regPasswordsNoMatch;
      Fluttertoast.showToast(
        msg: theMessage,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        fontSize: 16.0,
      );
    }
    return theMessage;
  }

  Future<void> verifyPhone(String number) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: number,
      timeout: const Duration(seconds: 40),
      verificationCompleted: (phoneAuthCredential) async {
        listeningForOTP = false;
        numberAutoVerfiedComplete = true;
        showSnackBarText("VERIFICATION COMPLETED!");
        //phoneAuthCredential = (PhoneAuthProvider.credential(verificationId: verID, smsCode: otpPin));
        print("COMPLETED AUTH: ${phoneAuthCredential.smsCode}");
        int i = 0;
        for (var digit in phoneAuthCredential.smsCode.toString().characters) {
          print("DIGIT : $digit");
          otpFieldController.setValue(digit, i++);
        }
        setState(
          () {},
        );
        await _auth.currentUser!.linkWithCredential(phoneAuthCredential);
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (context) => const TestHome(
                      timeUntilReservationStarts: 0,
                      newMoreUrgentBooking: {},
                    )),
            (Route<dynamic> route) => false);
      },
      verificationFailed: (FirebaseAuthException e) {
        showSnackBarText("Auth Failed! ${e.message}");
        if (e.code == 'invalid-phone-number') {
          showSnackBarText('The provided phone number is not valid.');
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        backgroundWaiting = false;
        showSnackBarText("OTP Sent!");
        setState(() {
          verID = verificationId;
          savedNumber = _numberController.text;
          listeningForOTP = true;
          resentToken = resendToken;
          // _numberController.clear();
          //isSpecialAccessUser ? activeStep = 2 : activeStep = 1;
        });
      },
      forceResendingToken: resentToken,
      codeAutoRetrievalTimeout: (String verificationId) {
        showSnackBarText("Timeout!"); // : showSnackBarText("Auth Completed!");
      },
    );
  }

  void updateWalletFields(QuerySnapshot<Map<String, dynamic>> walletCollection,
      String walletFirstAndOnlyDocID, User currentlySignedInUser) {
    CollectionReference debitsCollection = myDB.collection(
        "users/${currentlySignedInUser.uid}/wallet/$walletFirstAndOnlyDocID/debits");
    CollectionReference topUpsCollection = myDB.collection(
        "users/${currentlySignedInUser.uid}/wallet/$walletFirstAndOnlyDocID/topUps");

    debugPrint("WALLETDOCS :${walletCollection.docs.first.id}");
    final theDocToUpdate = myDB
        .collection("users/${currentlySignedInUser.uid}/wallet")
        .doc(walletCollection.docs.first.id);

    var ok = walletCollection.docs.first.data()['Transactions']['Top Ups']
        as Map<String, dynamic>;
    topUpsCollection.get().then((value) {
      List allIDList = [];
      for (var element in value.docs) {
        allIDList.add(element.id);
        debugPrint("YOURE HERE _ $ok _ _ $allIDList");
      }

      theDocToUpdate.update({'Transactions.Top Ups.IDs': allIDList});
    });
  }

  Future<UserCredential?> registerWithEmailPassword() async {
    //UserProfile fetchedUP = userProfile;
    UserCredential? user;
    String walletFirstAndOnlyDocID = '';
    bool canUpdateFields = false;
    try {
      user = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text, password: _passwordController.text);
      user.user != null
          ? {
              user.user!.updateDisplayName(_fullNameController.text),
              user.user!.updatePhotoURL(profilePictureStoragePath),
              await firestoreService.createNewUser(NewUserProfile(
                  id: user.user!.uid,
                  fullName: _fullNameController.text,
                  email: _emailController.text,
                  phoneNumber: finalTest.phoneNumber.toString(),
                  profileImage: !isProfilePicturePicked
                      ? 'none'
                      : profilePictureStoragePath,
                  isSpecialAccessUser: isSpecialAccessUser,
                  equalityCardUploadedStoragePath:
                      equalityCardUploadedStoragePath)),

              await myDB
                  .collection("users/${user.user!.uid}/wallet")
                  .get()
                  .then((value) async {
                value.docs.isEmpty
                    ? await firestoreWalletService
                        .addUserWalletInfoToFirebase(user!.user)
                        .then((value) {
                        myDB
                            .collection("users/${user!.user!.uid}/wallet")
                            .get()
                            .then((value) => value.docs.first.id)
                            .then(
                          (value) {
                            debugPrint("WALLET ID: $value}");
                            walletFirstAndOnlyDocID = value;
                          },
                        );
                      })
                    : null;
              }),

              //
            }
          : null;

      setState(
        () {
          createdUserWithEmailAndPass = true;
        },
      );
      // _auth.signOut();

      Fluttertoast.showToast(
          msg: 'Sucessfully registered. Welcome.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          fontSize: 16.0);

      _auth.authStateChanges().listen((user) async {
        if (user != null) {
          print(
              "THE CURRENT USER ${FirebaseAuth.instance.currentUser} ____ profilePicPath $profilePictureStoragePath");
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setBool("isLoggedIn", false);
          user.updateDisplayName(_fullNameController.text);
          user.updatePhotoURL(profilePictureStoragePath);
          //user.displayName
          //displayname and photoURL will be null at first because we are signing in with password and email and because we are not signing in with google or a known provider.
          /*     print(
              'USER IS REGISTERED PERFECT! ------------- USER ID :${user.uid} '); //this is for me to view on the debugging console};
          print(
              'CURRENT USERS DISPLAYNAME : ${currentUser!.displayName} ---- Users DN ${user.displayName}----- EMAIL: ${currentUser!.email}------  ID ${currentUser!.uid} ');

          print(
              'CURRENT USERS DISPLAYNAME AFTER UPDATE: ${thisCurrently?.displayName} ____ DISPLAYNAME ${userProfile.fullName}  ____ ProfileIMAGE ${thisCurrently?.photoURL} '); */
        } else {
          //currentUser?.reload();
          print('USER IS SIGNED OUT PERFECT! FROM SIGN UP WITH EMAIL');
        }
      });
    } //
    on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "invalid-email":
        case "user-not-found":
          {
            Fluttertoast.showToast(
                msg: e.message!,
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                fontSize: 16.0);
            print(e.code); //for me to see on the debugging console
          }
          break;

        case 'email-already-exists':
          {
            Fluttertoast.showToast(
                msg: e.message!,
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                fontSize: 16.0);
            print(e.code); //for me to see on the debugging console
          }
          break;

        default:
          {}
      }
      print('Error: $e');
    } finally {
      user == null
          ? setState(
              () => backgroundWaiting = false,
            )
          : null;
    }
    return user;
  } //closing brackets

  /*  bool savedFormFields() {
    final form = formKey.currentState;

    if (form!.validate() && _passwordController.text == _confirmPasswordController.text) {
      form.save();
      print(
          'Form is valid. Full Name : $_fullNameController, Email: $_emailController , Password: $_passwordController, Phone number: ${finalTest.phoneNumber.toString()}');
      return true;
    } else if (_passwordController.text != _confirmPasswordController.text) {
      Fluttertoast.showToast(
          msg: 'The passwords do not match!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          fontSize: 16.0);
      return false;
    }
    return false;
  }
 */
  Future<void> getEqualityCardImage(ImageSource cameraOrGallery,
      String rectoOrVerso, AppLocalizations localLnSetting) async {
    try {
      final cardImage = await ImagePicker().pickImage(source: cameraOrGallery);
      if (cameraOrGallery == ImageSource.camera) {
        if (rectoOrVerso == 'recto' && cardImage != null) {
          if (equalityCardRectoVerso.isEmpty) {
            equalityCardRectoVerso.add(cardImage);
            setState(() {
              addedRectoCardImage = true;
            });
          }
          if (equalityCardRectoVerso.length == 1 &&
              addedRectoCardImage == false) {
            equalityCardRectoVerso.insert(0, cardImage);
            setState(() {
              addedRectoCardImage = true;
            });
          }

          if (equalityCardRectoVerso.length == 1 &&
              addedRectoCardImage == true) {
            equalityCardRectoVerso.first = cardImage;
            // getBarCodeText(equalityCardRectoVerso.first!, 'camera');

            setState(() {});
          }
          if (equalityCardRectoVerso.length == 2) {
            equalityCardRectoVerso.first = cardImage;
            getBarCodeText(
                equalityCardRectoVerso.first!, 'camera', localLnSetting);
            setState(() {
              canShowCameraButtons == true
                  ? addedRectoCardImage = true
                  : addedRectoCardImage = false;
            });
          }
        }

        if (rectoOrVerso == 'verso' && cardImage != null) {
          if (equalityCardRectoVerso.isEmpty) {
            equalityCardRectoVerso.add(cardImage);
            setState(() {
              addedVersoCardImage = true;
            });
          }
          if (equalityCardRectoVerso.length == 1 &&
              addedVersoCardImage == false) {
            equalityCardRectoVerso.add(cardImage);

            setState(() {
              addedVersoCardImage = true;
            });
          }

          if (equalityCardRectoVerso.length == 1 &&
              addedVersoCardImage == true) {
            equalityCardRectoVerso.first = cardImage;
            setState(() {});
          }
          if (equalityCardRectoVerso.length == 2) {
            equalityCardRectoVerso.last = cardImage;
            getBarCodeText(
                equalityCardRectoVerso.first!, 'camera', localLnSetting);
            setState(() {
              canShowCameraButtons == true
                  ? addedVersoCardImage = true
                  : addedVersoCardImage = false;
            });
          }
        }
        print(
            "CAN YOU SHOW CAMERA BUTTONS $addedRectoCardImage _______ $addedVersoCardImage");
        addedRectoCardImage && addedVersoCardImage
            ? setState(() {
                canShowCameraButtons = false;
              })
            : null;
      } else {
        final List<XFile?> selectedImages =
            await cardImagePicker.pickMultiImage();
        if (selectedImages.isNotEmpty && selectedImages.length == 2) {
          equalityCardRectoVerso = selectedImages;
          setState(() {});
          getBarCodeText(equalityCardRectoVerso.first!, 'gallery',
              localLnSetting, equalityCardRectoVerso);
        }
        //print("Image List Length:" + imageFileList!.length.toString());
      }
    } catch (e) {
      print("error $e");
    }
  }

  Future<void> getProfilePicture(ImageSource gallery) async {
    try {
      final pickedImage = await ImagePicker().pickImage(source: gallery);
      if (pickedImage != null) {
        profilePicture = pickedImage;
        isProfilePicturePicked = true;
        setState(() {});
      }
    } catch (e) {
      print("error $e");
    }
  }

  void getBarCodeText(
      XFile image, String fromGalleryOrCamera, AppLocalizations localLnSetting,
      [List<XFile?> localEqualityCardRectoVersoList = const []]) async {
    InputImage rectoInputImage, versoInputImage;
    int theRightGalleryCardImageIndex = -1;
    final barcodeScanner = BarcodeScanner(formats: formats);
    List<Barcode> barcodesList = [];
    debugPrint(
        "image.path^equalityCardRectoVersoList${localEqualityCardRectoVersoList.length}");
    if (fromGalleryOrCamera == 'gallery') {
      for (XFile? element in localEqualityCardRectoVersoList) {
        rectoInputImage = InputImage.fromFilePath(element!.path);
        debugPrint("image.path^${image.path}");
        barcodesList = await barcodeScanner.processImage(rectoInputImage);
        barcodesList.isNotEmpty
            ? {
                setState(() {
                  theRightGalleryCardImageIndex =
                      localEqualityCardRectoVersoList.indexOf(element);
                }),
              }
            : print("DEFINITELY EMPYT");
        print("THE RIGHT IMAGE: $theRightGalleryCardImageIndex");
      }
      rectoInputImage = theRightGalleryCardImageIndex != -1
          ? InputImage.fromFilePath(localEqualityCardRectoVersoList
              .elementAt(theRightGalleryCardImageIndex)!
              .path)
          : InputImage.fromFilePath(
              localEqualityCardRectoVersoList.first!.path);
      versoInputImage = theRightGalleryCardImageIndex != -1
          ? InputImage.fromFilePath(localEqualityCardRectoVersoList
              .elementAt(localEqualityCardRectoVersoList.length -
                  1 -
                  theRightGalleryCardImageIndex)!
              .path)
          : InputImage.fromFilePath(localEqualityCardRectoVersoList.last!.path);
    } else {
      rectoInputImage = InputImage.fromFilePath(image.path);
      versoInputImage =
          InputImage.fromFilePath(equalityCardRectoVerso.last!.path);
      barcodesList = await barcodeScanner.processImage(rectoInputImage);
      debugPrint("SOURCE IS :$barcodesList ___ ${barcodesList.length}");
    }
    await barcodeScanner.close();

    final textDetector = TextRecognizer(script: TextRecognitionScript.latin);
    RecognizedText recognisedTextRecto =
        await textDetector.processImage(rectoInputImage);
    await textDetector.close();

    RecognizedText recognisedTextVerso =
        await textDetector.processImage(versoInputImage);
    await textDetector.close();

    String textFetchedCardRecto = "", textFetchedCardVerso = '';

    for (TextBlock block in recognisedTextRecto.blocks) {
      for (TextLine line in block.lines) {
        textFetchedCardRecto = "$textFetchedCardRecto${line.text}\n";
      }
    }

    for (TextBlock block in recognisedTextVerso.blocks) {
      for (TextLine line in block.lines) {
        textFetchedCardVerso = "$textFetchedCardVerso${line.text}\n";
      }
    }

    debugPrint("recognisedText recto $textFetchedCardRecto");
    debugPrint("recognisedText verso $textFetchedCardVerso");

    bool rectoContainsAll = textFetchedCardRecto
            .isCaseInsensitiveContains('DGAS') &&
        textFetchedCardRecto
            .isCaseInsensitiveContains('Certification de handicap') &&
        textFetchedCardRecto.isCaseInsensitiveContains('Direction Générale') &&
        textFetchedCardRecto.isCaseInsensitiveContains("de l'action sociale");

    bool versoContainsAll = rectoContainsAll &&
        textFetchedCardVerso.isCaseInsensitiveContains('SENEGAL') &&
        textFetchedCardVerso.isCaseInsensitiveContains('EMERGENT');

    rectoContainsAll && versoContainsAll
        ? isEqualityCardValid = true
        : isEqualityCardValid = false;
    print("CONTAINS ALL? $versoContainsAll");

    /* !rectoContainsAll
        ? ThemeHelper().alartDialog('Incorrect Image Format', 'Please re-submit the recto part of your card', context)
        : null; */
    !rectoContainsAll && versoContainsAll
        ? showSnackBarText(localLnSetting.scanCECrectoError, errorTextStle)
        : !versoContainsAll && rectoContainsAll
            ? showSnackBarText(localLnSetting.scanCECversoError, errorTextStle)
            : !rectoContainsAll && !versoContainsAll
                ? showSnackBarText(
                    localLnSetting.scanCECbothRectoVersoError, errorTextStle)
                : null;

    debugPrint("containsAll $rectoContainsAll __________ $versoContainsAll");

    for (Barcode barcode in barcodesList) {
      final BarcodeType type = barcode.type;
      final Rect boundingBox = barcode.boundingBox;
      final String? displayValue = barcode.displayValue;
      final String? rawValue = barcode.rawValue;

      switch (type) {
        case BarcodeType.unknown:
          //  scannedText = 'ENCRYPTED';
          print("UNKNOWN BACRODE type}");
          break;

        case BarcodeType.text:
          print("THE SCANNED BARCODE ${barcode.displayValue.toString()}");
          equalityCardID = barcode.displayValue.toString();
          break;

        default:
          print(
              "THE SCANNED BARCODE IS ENCRYPTED ${barcode.displayValue.toString()}");
          break;
      }
    }

    setState(() {});
  }

  void resendCode(String userPhoneNumber) {
    verifyPhone(userPhoneNumber);
    /* _auth.verifyPhoneNumber(
        forceResendingToken: resentToken,
        phoneNumber: userPhoneNumber,
        codeAutoRetrievalTimeout: (String verificationId) {
          showSnackBarText("Request Timed Out");
        },
        codeSent: (String verificationId, int? forceResendingToken) {},
        verificationFailed: (FirebaseAuthException error) {},
        verificationCompleted: (PhoneAuthCredential phoneAuthCredential) {
          showSnackBarText("COMPLETED");
        }); */
  }

  Future<bool> findMatchingPhoneAndEmailInDatabase(String action) async {
    var theEmail = _emailController.text;
    try {
      var foundMatchForBoth = await FirebaseFirestore.instance
          .collection("users")
          .get()
          .then((element) {
        /*  element.docChanges.forEach((change) {
          print("SOMETHING CHANGED ${change.type} ____ ${change.doc.exists}");
          change.type == DocumentChangeType.removed ? theEmail = '' : null;
        }); */
        var matchingEmail = element.docs.any((element1) {
          Map<String, dynamic> data = element1.data();
          return data['Email'] == theEmail;
        });
        print("THIS IS MATCHING EMAIL: $matchingEmail");
        matchingEmail
            ? {print("EMAIL EXISTS IN THE DATABASE FROM FIRESTORE")}
            : print("EMAIL DOES NOT EXISTS IN THE DATABASE FROM FIRESTORE");

        var matchingPhone = element.docs.any((element1) {
          Map<String, dynamic> data = element1.data();
          return data['Phone Number'] ==
              finalTest.phoneNumber
                  .toString(); //== finalTest.phoneNumber.toString()
        });
        matchingPhone
            ? print("NUMBER EXISTS IN THE DATABASE FROM FIRESTORE")
            : print("NUMBER DOES NOT EXISTS IN THE DATABASE FROM FIRESTORE");

        if (matchingPhone &&
            !matchingEmail) /*  if (numberAlreadyRegistered && !emailAlreadyRegistered) */ {
          showSnackBarText('Number already in use.');
        }
        if (matchingEmail &&
            !matchingPhone) /*if (emailAlreadyRegistered && !numberAlreadyRegistered)  */ {
          showSnackBarText('Email already in use.');
        }
        if (matchingEmail &&
            matchingPhone) /*if (emailAlreadyRegistered && numberAlreadyRegistered)  */ {
          showSnackBarText('Email and number already in use.');
        }
        if (!matchingEmail && !matchingPhone) {
          print("PREVIOUSLY REACHEDSTEP $result _ finalNum $finalTest");
          print("NO MATCHING NUMBER OR EMAIL FOUND");
          setState(
            () {
              foundPhoneMailMatch.value = false;
            },
          );
          if (activeStep == 0 && action == 'goToScanner') {
            print("is special user: going to scanner");
            setState(() {
              activeStep = 1;
            });
          }
          if (action == 'sendOTP') {
            activeStep == 0
                ? print("VALIDATION FOR OTP: not special user")
                : print(
                    "VALIDATION FOR OTP:SPECIAL USER"); /* setState(() {
              foundPhoneMailMatch.value == false ? backgroundWaiting = true : null;k
            }); */
          }
        }

        return foundPhoneMailMatch.value; //matchingEmail || matchingPhone;
      });

      return foundMatchForBoth;
    } catch (e) {
      print("EXCEPTION OCCURED");
      return true;
    }
  }
}

///ending crochet
///
