// ignore_for_file: avoid_print
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:otp_text_field/otp_field.dart';
import 'package:otp_text_field/style.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_parking/models/pages/widgets/header_widget.dart';
import 'package:smart_parking/models/theme_helper.dart';
import 'package:smart_parking/screens/authenticate/test_register.dart';
import 'package:smart_parking/screens/inside_app/testhome.dart';
import 'package:smart_parking/services/firebase/firebase_service.dart';
import 'package:smart_parking/screens/authenticate/reset_password.dart';
import 'package:smart_parking/services/firebase/firestore_service.dart';
import 'package:smart_parking/models/user.dart';
import 'package:smart_parking/l10n/generated/app_localizations.dart';

class TestLogin extends StatefulWidget {
  const TestLogin({super.key});

  @override
  TestLoginState createState() => TestLoginState();
}

enum LoginMethod { emailPassword, phone, none }

class TestLoginState extends State<TestLogin> {
  late Timer _timer;
  int _start = 5, otpTimeoutDuration = 40;
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
  LoginMethod loginMethod = LoginMethod.none;
  late FocusNode myFocusNode;
  final double _headerHeight = 250;
  bool obscurText = true,
      listeningForOTP = false,
      numberAlreadyRegistered = false,
      pinSuccess = false,
      enableResend = false,
      showOtpUi = false,
      loadingSigningUserEmail = false;
  int? tokenToResend;
  String selectedLoginMethodDropDown = 'Select A Login Method',
      theCodeForPhone = 'ok',
      otpPin = '';

  ConnectivityResult connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> connectivitySubscription;
  final OtpFieldController otpFieldController = OtpFieldController();

  final internatKey = GlobalKey<FormState>(),
      _pinMobileFormKey = GlobalKey<FormState>();
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
  UserProfile userProfile = UserProfile(
      id: '',
      fullName: '',
      email: '',
      phoneNumber: '',
      timeStamp: FieldValue.serverTimestamp(),
      profileImage: '');
  final logEmailformKey = GlobalKey<FormState>(),
      phonelogFormKey = GlobalKey<FormState>();
  final List<String> loginMethodsDropDown = <String>[
    'Select A Login Method',
    'Email - Password',
    'Phone Number'
  ];

  final TextEditingController _emailController = TextEditingController(),
      _passwordController = TextEditingController(),
      _numberController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseService service = FirebaseService();
  FirestoreUserService firestoreService = FirestoreUserService();
  User? currentUser;

  @override
  void initState() {
    const oneSec = Duration(seconds: 1);

    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {},
    );

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
    myFocusNode = FocusNode();

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

    initConnectivity();

    connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    setState(
      () {},
    );
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    myFocusNode.dispose();
    _numberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _timer.cancel();

    super.dispose();
  }

//for AUTH LIMITS, check https://firebase.google.com/docs/auth/limits
// for otp timer, check https://medium.com/codex/resend-otp-timer-dd0d899a424f
  Future<String> getCarrierCode(List<Map<String, dynamic>> countries) async {
    //String code = await prefix.PhoneNumberUtil().carrierRegionCode();
    String code = await PhoneNumber.getRegionInfoFromPhoneNumber('', 'US')
        .then((value) => value.isoCode ?? 'US');

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
      connectionStatus = result.first;
    });
  }

  void startTimer() {
    _start = otpTimeoutDuration;
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  Future<void> logInWithEmailPassword(AppLocalizations localLnSetting) async {
    UserCredential? theUser;
    try {
      setState(() {
        loadingSigningUserEmail = true;
      });
      theUser = await _auth.signInWithEmailAndPassword(
          email: _emailController.text, password: _passwordController.text);

      theUser.user != null
          ? {
              await firestoreService
                  .testgetUserFullName(theUser.user!)
                  .then((value) {
                theUser!.user!.updateDisplayName(value);
                print("DISPNAME :$value");
              }),
              await firestoreService
                  .testgetUserProfileImage(theUser.user!)
                  .then((value) => value == 'none'
                      ? null
                      : theUser!.user!.updatePhotoURL(value))
            }
          : null;

      Fluttertoast.showToast(
          msg: 'Successfully logged in',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          fontSize: 16.0);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) => const TestHome(
                    timeUntilReservationStarts: 0,
                    newMoreUrgentBooking: {},
                  )),
          (Route<dynamic> route) => false);
      _auth.idTokenChanges().listen((user) async {
        if (user != null) {
          //currentUser = FirebaseAuth.instance.currentUser;
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setBool("isLoggedIn", false);
          print('USER IS SIGNED IN PERFECT! LOGIN');

          /*   if (currentUser != null) {
            await currentUser!.reload();
          } */
        } else {
          print('USER IS SIGNED OUT PERFECT! FROM LOGIN WITH EMAIL');
        }
      });
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "invalid-email":
          {
            Fluttertoast.showToast(
                msg: localLnSetting.logIncorrectEmailOrPass,
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                fontSize: 16.0);
            print(e.code); //for me to see on the debugging console
          }
          break;
        case "user-not-found":
          {
            Fluttertoast.showToast(
                msg: localLnSetting.logIncorrectEmailOrPass,
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                fontSize: 15.0);
            print(e.code); //for me to see on the debugging console
          }
          break;
        case 'wrong-password':
          {
            Fluttertoast.showToast(
                msg: localLnSetting.logIncorrectEmailOrPass,
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                fontSize: 16.0);
            print(e.code); //for me to see on the debugging console
          }
          break;

        case 'network-request-failed':
          {
            Fluttertoast.showToast(
                msg: localLnSetting.noInternetError,
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                fontSize: 16.0);
            print(e.code); //for me to see on the debugging console
          }
          break;

        default:
          {
            Fluttertoast.showToast(
                msg: e.message!,
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                fontSize: 16.0);
            print(e.code);
          }
      }
      print('Error: $e');
    } finally {
      currentUser == null
          ? setState(
              () => loadingSigningUserEmail = false,
            )
          : null;
    }
  } //closing brackets

  @override
  Widget build(BuildContext context) {
    var localLnSetting = AppLocalizations.of(context)!;
    print("listeningForOTP : $listeningForOTP");
    var theCountry = countries.where((element) =>
        element['code'].toString().toLowerCase() == theCodeForPhone);
    theCountry.isNotEmpty
        ? {
            print(
                'HA ${theCountry.first} ${theCountry.first['flag'].runtimeType}'),
          }
        : null;

    return Scaffold(
        body: GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(FocusNode());
            },
            child: Scaffold(
              backgroundColor: Colors.white,
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      fit: StackFit.passthrough,
                      children: [
                        SizedBox(
                          height: _headerHeight,
                          child: GestureDetector(
                            onTap: () {
                              print(
                                  "TAPPED ON BACK TO CHNAGE LOGIN NUMBER listeningForOTP $listeningForOTP");
                              listeningForOTP
                                  ? null
                                  : setState(() {
                                      showOtpUi = false;
                                      _numberController.clear();
                                      listeningForOTP = false;
                                    });
                            },
                            child: HeaderWidget(
                              height: _headerHeight,
                              icon: Icons.keyboard_backspace_rounded,
                              showIcon: false,
                              fromLoginVerif: showOtpUi,
                            ),
                          ), //let's create a common header widget
                        ),
                        CircleAvatar(
                          backgroundColor: Colors.white.withValues(alpha: 0.5),
                          radius: 60,
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 200,
                          ),
                        ),
                      ],
                    ),
                    showOtpUi
                        ? otpUI(localLnSetting)
                        : SafeArea(
                            child: Container(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 10, 20, 10),
                                margin: const EdgeInsets.fromLTRB(20, 10, 20,
                                    10), // This will be the login form
                                child: Column(
                                  children: [
                                    Text(
                                      localLnSetting.welcomeToApp,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.visible,
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight:
                                              FontWeight.bold), //fontSize: 60,
                                    ),
                                    const SizedBox(height: 15),
                                    Text(
                                      localLnSetting.login,
                                      style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 30.0),
                                    loginMethod == LoginMethod.none
                                        ? DropdownButton<String>(
                                            value: selectedLoginMethodDropDown,
                                            icon: const Icon(
                                                Icons.arrow_downward),
                                            elevation: 16,
                                            alignment: Alignment.center,
                                            style: const TextStyle(
                                                color: Colors.deepPurple),
                                            underline: Container(
                                              height: 2,
                                              color: Colors.deepPurpleAccent,
                                            ),
                                            onChanged: (String? value) {
                                              // This is called when the user selects an item.
                                              setState(() {
                                                selectedLoginMethodDropDown =
                                                    value!;
                                              });
                                            },
                                            items: loginMethodsDropDown
                                                .map<DropdownMenuItem<String>>(
                                                    (String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            }).toList(),
                                          )
                                        : Container(),
                                    loginMethod == LoginMethod.emailPassword
                                        ? Form(
                                            key: logEmailformKey,
                                            autovalidateMode:
                                                AutovalidateMode.disabled,
                                            child: Column(
                                              children: [
                                                Container(
                                                  decoration: ThemeHelper()
                                                      .inputBoxDecorationShaddow(),
                                                  child: TextFormField(
                                                    validator:
                                                        FormBuilderValidators
                                                            .compose([
                                                      FormBuilderValidators
                                                          .required(),
                                                      FormBuilderValidators.match(
                                                          RegExp(
                                                              r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$"),
                                                          errorText: localLnSetting
                                                              .logErrorBadEmailFormat)
                                                    ]),
                                                    controller:
                                                        _emailController,
                                                    keyboardType: TextInputType
                                                        .emailAddress,
                                                    onChanged: (value) {
                                                      print(
                                                          "THAT'S THE VALUE $value");
                                                    },
                                                    decoration: ThemeHelper()
                                                        .textInputDecoration(
                                                            Icons.mail,
                                                            localLnSetting
                                                                .loginEmailLabel,
                                                            localLnSetting
                                                                .loginEmailPlaceholder),
                                                  ),
                                                ),
                                                const SizedBox(height: 30.0),
                                                Container(
                                                  decoration: ThemeHelper()
                                                      .inputBoxDecorationShaddow(),
                                                  child: TextFormField(
                                                      autovalidateMode:
                                                          AutovalidateMode
                                                              .disabled,
                                                      validator:
                                                          FormBuilderValidators
                                                              .compose([
                                                        FormBuilderValidators
                                                            .required(),
                                                      ]),
                                                      controller:
                                                          _passwordController,
                                                      obscureText: obscurText,
                                                      decoration:
                                                          InputDecoration(
                                                        prefixIcon: const Icon(
                                                          Icons.lock,
                                                          size: 25,
                                                          //color: Color.fromARGB(173, 0, 0, 0),
                                                        ),
                                                        suffixIcon:
                                                            GestureDetector(
                                                          onTap: () {
                                                            setState(() {
                                                              obscurText == true
                                                                  ? obscurText =
                                                                      false
                                                                  : obscurText =
                                                                      true;
                                                            });
                                                          },
                                                          child: Icon(obscurText
                                                              ? Icons
                                                                  .visibility_off_outlined
                                                              : Icons
                                                                  .visibility_outlined),
                                                        ),
                                                        labelText: localLnSetting
                                                            .loginPasswordLabel,
                                                        hintText: localLnSetting
                                                            .loginPasswordPlaceholder,
                                                        fillColor: Colors.white,
                                                        filled: true,
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .fromLTRB(
                                                                20, 10, 20, 10),
                                                        focusedBorder: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        100.0),
                                                            borderSide:
                                                                const BorderSide(
                                                                    color: Colors
                                                                        .grey)),
                                                        enabledBorder: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        100.0),
                                                            borderSide: BorderSide(
                                                                color: Colors
                                                                    .grey
                                                                    .shade400)),
                                                        errorBorder: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        100.0),
                                                            borderSide:
                                                                const BorderSide(
                                                                    color: Colors
                                                                        .red,
                                                                    width:
                                                                        2.0)),
                                                        focusedErrorBorder: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        100.0),
                                                            borderSide:
                                                                const BorderSide(
                                                                    color: Colors
                                                                        .red,
                                                                    width:
                                                                        2.0)),
                                                      )),
                                                ),
                                                const SizedBox(height: 15.0),
                                                Container(
                                                  margin:
                                                      const EdgeInsets.fromLTRB(
                                                          10, 0, 10, 20),
                                                  alignment: Alignment.topRight,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                              builder: (context) =>
                                                                  const ResetPassword()));
                                                      /*   Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                                      ); */
                                                    },
                                                    child: Text(
                                                      localLnSetting
                                                          .forgotPassword,
                                                      style: const TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 15.0),
                                                /* Container(
                                              decoration: ThemeHelper().buttonBoxDecoration(context),
                                              child: ElevatedButton(
                                                style: ThemeHelper().buttonStyle(),
                                                child: Padding(
                                                  padding: const EdgeInsets.fromLTRB(40, 10, 40, 10),
                                                  child: Text(
                                                    localLnSetting.signin.toUpperCase(),
                                                    style: const TextStyle(
                                                        fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  submitLoginForm(localLnSetting);
                                                  //After successful login we will redirect to profile page. Let's create profile page now
                                                  /*  Navigator.pushReplacement(
                                          context, MaterialPageRoute(builder: (context) => const ProfilePage())); */
                                                },
                                              ),
                                            ),
                                             */
                                                loginButton(loginMethod,
                                                    localLnSetting),
                                                Container(
                                                  margin:
                                                      const EdgeInsets.fromLTRB(
                                                          10, 20, 10, 20),
                                                  //child: Text('Don\'t have an account? Create'),
                                                  child: Text.rich(
                                                      TextSpan(children: [
                                                    TextSpan(
                                                        text: localLnSetting
                                                            .noAccount),
                                                    TextSpan(
                                                      text: localLnSetting
                                                          .createAccount,
                                                      recognizer:
                                                          TapGestureRecognizer()
                                                            ..onTap = () {
                                                              Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                      builder:
                                                                          (context) =>
                                                                              const TestRegister() /*const TestingOTP() TestRegister() */));
                                                            },
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .secondary,
                                                          fontSize: 15),
                                                    ),
                                                  ])),
                                                ),
                                              ],
                                            ))
                                        : loginMethod == LoginMethod.phone
                                            ? Column(
                                                children: [
                                                  Form(
                                                    key: phonelogFormKey,
                                                    onChanged: () {
                                                      phonelogFormKey
                                                          .currentState!
                                                          .save();
                                                      //print("THIS IS THE CURRENT STATE: ${regFormKey.currentState}");
                                                    },
                                                    child:
                                                        InternationalPhoneNumberInput(
                                                      key: internatKey,
                                                      onInputChanged:
                                                          (PhoneNumber
                                                              changingNumber) {
                                                        print(
                                                            "changingNumber ${changingNumber.phoneNumber}");
                                                      },
                                                      locale: Get
                                                          .locale!.languageCode,
                                                      selectorConfig:
                                                          const SelectorConfig(
                                                        setSelectorButtonAsPrefixIcon:
                                                            true,
                                                        trailingSpace: false,
                                                        selectorType:
                                                            PhoneInputSelectorType
                                                                .DROPDOWN,
                                                      ),
                                                      inputDecoration:
                                                          InputDecoration(
                                                        labelText:
                                                            localLnSetting
                                                                .regNumberLabel,
                                                        hintText: localLnSetting
                                                            .regNumberPlaceholder,
                                                        fillColor: Colors.white,
                                                        filled: true,
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .fromLTRB(
                                                                20, 10, 0, 10),
                                                        focusedBorder: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        100.0),
                                                            borderSide:
                                                                const BorderSide(
                                                                    color: Colors
                                                                        .grey)),
                                                        enabledBorder: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        100.0),
                                                            borderSide: BorderSide(
                                                                color: Colors
                                                                    .grey
                                                                    .shade400)),
                                                        errorBorder: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        100.0),
                                                            borderSide:
                                                                const BorderSide(
                                                                    color: Colors
                                                                        .red,
                                                                    width:
                                                                        2.0)),
                                                        focusedErrorBorder: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        100.0),
                                                            borderSide:
                                                                const BorderSide(
                                                                    color: Colors
                                                                        .red,
                                                                    width:
                                                                        2.0)),
                                                      ),
                                                      ignoreBlank: false,
                                                      errorMessage:
                                                          localLnSetting
                                                              .regNumberError,
                                                      autoValidateMode:
                                                          AutovalidateMode
                                                              .disabled,
                                                      selectorTextStyle:
                                                          const TextStyle(
                                                              color:
                                                                  Colors.black),
                                                      initialValue:
                                                          initializedNumber,
                                                      textFieldController:
                                                          _numberController,
                                                      formatInput: false,
                                                      keyboardType:
                                                          const TextInputType
                                                              .numberWithOptions(),
                                                      onSaved: (PhoneNumber
                                                          thenumber) {
                                                        print(
                                                            'On Saved: $thenumber');
                                                        setState(() {
                                                          finalTest = thenumber;
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(height: 30.0),
                                                  loginButton(loginMethod,
                                                      localLnSetting),
                                                ],
                                              )
                                            : Container(
                                                margin: const EdgeInsets.only(
                                                    top: 30),
                                                decoration: ThemeHelper()
                                                    .buttonBoxDecoration(
                                                        context),
                                                child: ElevatedButton(
                                                  style:
                                                      selectedLoginMethodDropDown ==
                                                              loginMethodsDropDown
                                                                  .first
                                                          ? ButtonStyle(
                                                              shape: WidgetStateProperty
                                                                  .all<
                                                                      RoundedRectangleBorder>(
                                                                RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              30.0),
                                                                ),
                                                              ),
                                                              minimumSize:
                                                                  WidgetStateProperty.all(
                                                                      const Size(
                                                                          50,
                                                                          50)),
                                                              backgroundColor:
                                                                  WidgetStateProperty.all(Colors
                                                                      .white
                                                                      .withValues(
                                                                          alpha:
                                                                              0.4)),
                                                              shadowColor:
                                                                  WidgetStateProperty
                                                                      .all(Colors
                                                                          .brown),
                                                            )
                                                          : ThemeHelper()
                                                              .buttonStyle(),
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                        .fromLTRB(
                                                        40, 10, 40, 10),
                                                    child: Text(
                                                      localLnSetting
                                                          .regNextButton
                                                          .toUpperCase(),
                                                      style: const TextStyle(
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      selectedLoginMethodDropDown ==
                                                              loginMethodsDropDown
                                                                  .first
                                                          ? null
                                                          : selectedLoginMethodDropDown ==
                                                                  loginMethodsDropDown
                                                                      .elementAt(
                                                                          1)
                                                              ? loginMethod =
                                                                  LoginMethod
                                                                      .emailPassword
                                                              : loginMethod =
                                                                  LoginMethod
                                                                      .phone;
                                                    });

                                                    //After successful login we will redirect to profile page. Let's create profile page now
                                                    /*  Navigator.pushReplacement(
                                          context, MaterialPageRoute(builder: (context) => const ProfilePage())); */
                                                  },
                                                ),
                                              ),
                                    loginMethod != LoginMethod.none
                                        ? Column(
                                            children: [
                                              TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    loginMethod =
                                                        LoginMethod.none;
                                                  });
                                                },
                                                child: const Text(
                                                    "Choose another method"),
                                              ),
                                              listeningForOTP ||
                                                      loadingSigningUserEmail
                                                  ? SpinKitFadingCircle(
                                                      size: 50,
                                                      itemBuilder:
                                                          (BuildContext context,
                                                              int index) {
                                                        return const DecoratedBox(
                                                          decoration:
                                                              BoxDecoration(
                                                                  color: Colors
                                                                      .green,
                                                                  shape: BoxShape
                                                                      .circle),
                                                        );
                                                      })
                                                  : Container(),
                                            ],
                                          )
                                        : Container(
                                            margin: const EdgeInsets.fromLTRB(
                                                10, 20, 10, 20),
                                            //child: Text('Don\'t have an account? Create'),
                                            child:
                                                Text.rich(TextSpan(children: [
                                              TextSpan(
                                                  text:
                                                      localLnSetting.noAccount),
                                              TextSpan(
                                                text: localLnSetting
                                                    .createAccount,
                                                recognizer:
                                                    TapGestureRecognizer()
                                                      ..onTap = () {
                                                        Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        const TestRegister() /*const TestingOTP() TestRegister() */));
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
                                ))),
                  ],
                ),
              ),
            )));
  }

  SafeArea otpUI(AppLocalizations localLnSetting) {
    return SafeArea(
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
                            style: const TextStyle(fontSize: 30),
                            textFieldAlignment: MainAxisAlignment.spaceAround,
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
                  _start == 0
                      ? Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: localLnSetting.numVerifDidntReceiveCode,
                                style: const TextStyle(
                                  color: Colors.black38,
                                ),
                              ),
                              TextSpan(
                                text: localLnSetting.numVerifResendCode,
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    setState(() {
                                      _start = otpTimeoutDuration;
                                    });
                                    // enableResend = true; this is set to true when timer is over and no code received
                                    enableResend
                                        ? resendCode(
                                            "${finalTest.dialCode.toString()} ${_numberController.text}")
                                        : null;
                                  },
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange),
                              ),
                            ],
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Resend Code in",
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _start.toString(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange),
                            ),
                          ],
                        ),
                  const SizedBox(height: 40.0),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Column loginButton(LoginMethod loginMethod, AppLocalizations localLnSetting) {
    return Column(
      children: [
        Container(
            decoration: ThemeHelper().buttonBoxDecoration(context),
            child: ElevatedButton(
              style: ThemeHelper().buttonStyle(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 10, 40, 10),
                child: Text(
                  localLnSetting.signin.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              onPressed: () async {
                connectionStatus.toString() != 'ConnectivityResult.none'
                    ? loginMethod == LoginMethod.emailPassword ||
                            loginMethod == LoginMethod.phone
                        ? submitLoginForm(localLnSetting, loginMethod)
                        : null
                    : listeningForOTP
                        ? null
                        : showSnackBarText(localLnSetting.noInternetError);

                //After successful login we will redirect to profile page. Let's create profile page now
                /*  Navigator.pushReplacement(
                                              context, MaterialPageRoute(builder: (context) => const ProfilePage())); */
              },
            )),
        /* Container(
          margin: const EdgeInsets.fromLTRB(10, 20, 10, 20),
          //child: Text('Don\'t have an account? Create'),
          child: Text.rich(TextSpan(children: [
            TextSpan(text: localLnSetting.noAccount),
            TextSpan(
              text: localLnSetting.createAccount,
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const TestRegister() /*const TestingOTP() TestRegister() */));
                },
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary, fontSize: 15),
            ),
          ])),
        ),
        */
        const SizedBox(height: 30.0),
      ],
    );
  }

  /*  String? toastValidationMessages(String? value) {
    String theMessage = '';
    if (_passwordController.text.isEmpty) {
      theMessage = 'Password required!';
      /*  Fluttertoast.showToast(
        msg: 'Please enter a password.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        fontSize: 16.0,
      ); */
    } /* else {
      String pattern = r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$';
      RegExp regex = RegExp(pattern);
      if (!regex.hasMatch(_passwordController.text)) {
        theMessage = 'Please check password format.!';

        /*  Fluttertoast.showToast(
            msg: 'Please check password format.',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            fontSize: 16.0); */
      }
    } */
    return theMessage;
  }
 */

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

  Future<void> verifyPhone(String number,
      {required bool resendSMS, int? resendToken = 0}) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: number,
      timeout: Duration(seconds: otpTimeoutDuration),
      verificationCompleted: (phoneAuthCredential) async {
        //showSnackBarText("VERIFICATION COMPLETED!");
        //phoneAuthCredential = (PhoneAuthProvider.credential(verificationId: verID, smsCode: otpPin));
        print("COMPLETED AUTH: ${phoneAuthCredential.smsCode}");
        int i = 0;
        for (var digit in phoneAuthCredential.smsCode.toString().characters) {
          print("DIGIT : $digit");
          otpFieldController.setValue(digit, i++);
        }
        // phoneNumberAlreadyExists(finalTest);
        try {
          await _auth
              .signInWithCredential(phoneAuthCredential)
              .then((theUser) async {
            await firestoreService
                .testgetUserFullName(theUser.user!)
                .then((value) {
              theUser.user!.updateDisplayName(value);
              print("DISPNAME :$value");
            });
          }).whenComplete(() => setState(
                    () {
                      listeningForOTP = false;
                    },
                  ));
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (context) => const TestHome(
                        newMoreUrgentBooking: {},
                      )),
              (Route<dynamic> route) => false);

          _auth.idTokenChanges().listen((user) async {
            if (user != null) {
              // currentUser = FirebaseAuth.instance.currentUser;
              SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.setBool("isLoggedIn", false);
              print('USER IS SIGNED IN PERFECT! LOGIN');
              /*    if (currentUser != null) {
                await currentUser!.reload();
              } */
            } else {
              print('USER IS SIGNED OUT PERFECT! FROM LOGIN WITH EMAIL');
            }
          });
        } on FirebaseAuthException catch (e) {
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

            default:
              {}
          }
          print('Error: $e');
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        showSnackBarText("Auth Failed! ${e.message}");
        setState(() {
          enableResend = true;
          listeningForOTP = false;
        });
        if (e.code == 'invalid-phone-number') {
          showSnackBarText('The provided phone number is not valid.');
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        //handle timer restart on resent
        setState(
          () {
            showOtpUi = true;
          },
        );
        startTimer();
        resendSMS
            ? showSnackBarText("OTP Sent!")
            : {showSnackBarText("OTP Resent!")};
        setState(() {
          //verID = verificationId;
          //savedNumber = _numberController.text;
          resendSMS ? enableResend = false : null;
          //listeningForOTP = true;
          tokenToResend = resendToken;
        });
      },
      forceResendingToken: resendSMS ? tokenToResend : null,
      codeAutoRetrievalTimeout: (String verificationId) {
        showSnackBarText("Timeout!"); // : showSnackBarText("Auth Completed!");
        setState(() {
          enableResend = true;
          listeningForOTP = false;
        });
      },
    );
  }

  bool savedFormFields(GlobalKey<FormState> formKey) {
    final form = formKey.currentState;

    if (form!.validate()) {
      form.save();
      formKey == logEmailformKey
          ? {
              print(
                  'Form is valid. Email: $_emailController , Password: $_passwordController')
            }
          : print("Form is valid. PhoneNumber ${finalTest.phoneNumber}");
      return true;
    }
    return false;
  }

  void submitLoginForm(
      AppLocalizations localLnSetting, LoginMethod loginMethod) async {
    if (loginMethod == LoginMethod.emailPassword) {
      if (savedFormFields(logEmailformKey)) {
        logInWithEmailPassword(localLnSetting);
      }
    } else {
      if (savedFormFields(phonelogFormKey)) {
        phoneNumberAlreadyExists(finalTest);
      }
    }
  }

  void phoneNumberAlreadyExists(PhoneNumber finalTest) {
    firestoreService
        .doesPhoneNumberAlreadyExist(
            phoneNumber: finalTest.phoneNumber.toString())
        .then((value) {
      print("VALUE IS : $value __ ${finalTest.phoneNumber}");
      setState(
        () => numberAlreadyRegistered = value,
      );

      if (numberAlreadyRegistered) {
        setState(
          () => listeningForOTP = true,
        );

        verifyPhone(
            '${finalTest.dialCode.toString()} ${_numberController.text}',
            resendSMS: false);
      } else {
        showSnackBarText('No account linked to this number');
      }
    });
  }

  void resendCode(String userPhoneNumber) {
    verifyPhone(userPhoneNumber, resendSMS: true, resendToken: tokenToResend);
  }
}

///ending crochet
