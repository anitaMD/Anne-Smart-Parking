// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:otp_text_field/otp_field.dart';
import 'package:otp_text_field/style.dart';
import 'package:phone_number/phone_number.dart' as prefix;
import 'package:smart_parking/models/pages/widgets/header_widget.dart';
import 'package:smart_parking/models/theme_helper.dart';
import 'package:smart_parking/screens/inside_app/home.dart';
import 'package:smart_parking/services/firebase/firebase_service.dart';
import 'package:smart_parking/services/firebase/firestore_service.dart';
import 'package:smart_parking/models/user.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class TestRegister extends StatefulWidget {
  const TestRegister({Key? key}) : super(key: key);

  @override
  TestRegisterState createState() => TestRegisterState();
}

enum FormType { login, register }
//enum UserType { normalUser, owner }

class TestRegisterState extends State<TestRegister> {
  List<Map<String, dynamic>> countries = [
    {"name": "Afghanistan", "flag": "🇦🇫", "code": "AF", "dial_code": "+93"},
    {"name": "Åland Islands", "flag": "🇦🇽", "code": "AX", "dial_code": "+358"},
    {"name": "Albania", "flag": "🇦🇱", "code": "AL", "dial_code": "+355"},
    {"name": "Algeria", "flag": "🇩🇿", "code": "DZ", "dial_code": "+213"},
    {"name": "American Samoa", "flag": "🇦🇸", "code": "AS", "dial_code": "+1684"},
    {"name": "Andorra", "flag": "🇦🇩", "code": "AD", "dial_code": "+376"},
    {"name": "Angola", "flag": "🇦🇴", "code": "AO", "dial_code": "+244"},
    {"name": "Anguilla", "flag": "🇦🇮", "code": "AI", "dial_code": "+1264"},
    {"name": "Antarctica", "flag": "🇦🇶", "code": "AQ", "dial_code": "+672"},
    {"name": "Antigua and Barbuda", "flag": "🇦🇬", "code": "AG", "dial_code": "+1268"},
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
    {"name": "Bolivia, Plurinational State of bolivia", "flag": "🇧🇴", "code": "BO", "dial_code": "+591"},
    {"name": "Bosnia and Herzegovina", "flag": "🇧🇦", "code": "BA", "dial_code": "+387"},
    {"name": "Botswana", "flag": "🇧🇼", "code": "BW", "dial_code": "+267"},
    {"name": "Bouvet Island", "flag": "🇧🇻", "code": "BV", "dial_code": "+47"},
    {"name": "Brazil", "flag": "🇧🇷", "code": "BR", "dial_code": "+55"},
    {"name": "British Indian Ocean Territory", "flag": "🇮🇴", "code": "IO", "dial_code": "+246"},
    {"name": "Brunei Darussalam", "flag": "🇧🇳", "code": "BN", "dial_code": "+673"},
    {"name": "Bulgaria", "flag": "🇧🇬", "code": "BG", "dial_code": "+359"},
    {"name": "Burkina Faso", "flag": "🇧🇫", "code": "BF", "dial_code": "+226"},
    {"name": "Burundi", "flag": "🇧🇮", "code": "BI", "dial_code": "+257"},
    {"name": "Cambodia", "flag": "🇰🇭", "code": "KH", "dial_code": "+855"},
    {"name": "Cameroon", "flag": "🇨🇲", "code": "CM", "dial_code": "+237"},
    {"name": "Canada", "flag": "🇨🇦", "code": "CA", "dial_code": "+1"},
    {"name": "Cape Verde", "flag": "🇨🇻", "code": "CV", "dial_code": "+238"},
    {"name": "Cayman Islands", "flag": "🇰🇾", "code": "KY", "dial_code": "+345"},
    {"name": "Central African Republic", "flag": "🇨🇫", "code": "CF", "dial_code": "+236"},
    {"name": "Chad", "flag": "🇹🇩", "code": "TD", "dial_code": "+235"},
    {"name": "Chile", "flag": "🇨🇱", "code": "CL", "dial_code": "+56"},
    {"name": "China", "flag": "🇨🇳", "code": "CN", "dial_code": "+86"},
    {"name": "Christmas Island", "flag": "🇨🇽", "code": "CX", "dial_code": "+61"},
    {"name": "Cocos (Keeling) Islands", "flag": "🇨🇨", "code": "CC", "dial_code": "+61"},
    {"name": "Colombia", "flag": "🇨🇴", "code": "CO", "dial_code": "+57"},
    {"name": "Comoros", "flag": "🇰🇲", "code": "KM", "dial_code": "+269"},
    {"name": "Congo", "flag": "🇨🇬", "code": "CG", "dial_code": "+242"},
    {"name": "Congo, The Democratic Republic of the Congo", "flag": "🇨🇩", "code": "CD", "dial_code": "+243"},
    {"name": "Cook Islands", "flag": "🇨🇰", "code": "CK", "dial_code": "+682"},
    {"name": "Costa Rica", "flag": "🇨🇷", "code": "CR", "dial_code": "+506"},
    {"name": "Cote d'Ivoire", "flag": "🇨🇮", "code": "CI", "dial_code": "+225"},
    {"name": "Croatia", "flag": "🇭🇷", "code": "HR", "dial_code": "+385"},
    {"name": "Cuba", "flag": "🇨🇺", "code": "CU", "dial_code": "+53"},
    {"name": "Cyprus", "flag": "🇨🇾", "code": "CY", "dial_code": "+357"},
    {"name": "Czech Republic", "flag": "🇨🇿", "code": "CZ", "dial_code": "+420"},
    {"name": "Denmark", "flag": "🇩🇰", "code": "DK", "dial_code": "+45"},
    {"name": "Djibouti", "flag": "🇩🇯", "code": "DJ", "dial_code": "+253"},
    {"name": "Dominica", "flag": "🇩🇲", "code": "DM", "dial_code": "+1767"},
    {"name": "Dominican Republic", "flag": "🇩🇴", "code": "DO", "dial_code": "+1849"},
    {"name": "Ecuador", "flag": "🇪🇨", "code": "EC", "dial_code": "+593"},
    {"name": "Egypt", "flag": "🇪🇬", "code": "EG", "dial_code": "+20"},
    {"name": "El Salvador", "flag": "🇸🇻", "code": "SV", "dial_code": "+503"},
    {"name": "Equatorial Guinea", "flag": "🇬🇶", "code": "GQ", "dial_code": "+240"},
    {"name": "Eritrea", "flag": "🇪🇷", "code": "ER", "dial_code": "+291"},
    {"name": "Estonia", "flag": "🇪🇪", "code": "EE", "dial_code": "+372"},
    {"name": "Ethiopia", "flag": "🇪🇹", "code": "ET", "dial_code": "+251"},
    {"name": "Falkland Islands (Malvinas)", "flag": "🇫🇰", "code": "FK", "dial_code": "+500"},
    {"name": "Faroe Islands", "flag": "🇫🇴", "code": "FO", "dial_code": "+298"},
    {"name": "Fiji", "flag": "🇫🇯", "code": "FJ", "dial_code": "+679"},
    {"name": "Finland", "flag": "🇫🇮", "code": "FI", "dial_code": "+358"},
    {"name": "France", "flag": "🇫🇷", "code": "FR", "dial_code": "+33"},
    {"name": "French Guiana", "flag": "🇬🇫", "code": "GF", "dial_code": "+594"},
    {"name": "French Polynesia", "flag": "🇵🇫", "code": "PF", "dial_code": "+689"},
    {"name": "French Southern Territories", "flag": "🇹🇫", "code": "TF", "dial_code": "+262"},
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
    {"name": "Guinea-Bissau", "flag": "🇬🇼", "code": "GW", "dial_code": "+245"},
    {"name": "Guyana", "flag": "🇬🇾", "code": "GY", "dial_code": "+592"},
    {"name": "Haiti", "flag": "🇭🇹", "code": "HT", "dial_code": "+509"},
    {"name": "Heard Island and Mcdonald Islands", "flag": "🇭🇲", "code": "HM", "dial_code": "+672"},
    {"name": "Holy See (Vatican City State)", "flag": "🇻🇦", "code": "VA", "dial_code": "+379"},
    {"name": "Honduras", "flag": "🇭🇳", "code": "HN", "dial_code": "+504"},
    {"name": "Hong Kong", "flag": "🇭🇰", "code": "HK", "dial_code": "+852"},
    {"name": "Hungary", "flag": "🇭🇺", "code": "HU", "dial_code": "+36"},
    {"name": "Iceland", "flag": "🇮🇸", "code": "IS", "dial_code": "+354"},
    {"name": "India", "flag": "🇮🇳", "code": "IN", "dial_code": "+91"},
    {"name": "Indonesia", "flag": "🇮🇩", "code": "ID", "dial_code": "+62"},
    {"name": "Iran, Islamic Republic of Persian Gulf", "flag": "🇮🇷", "code": "IR", "dial_code": "+98"},
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
    {"name": "Korea, Democratic People's Republic of Korea", "flag": "🇰🇵", "code": "KP", "dial_code": "+850"},
    {"name": "Korea, Republic of South Korea", "flag": "🇰🇷", "code": "KR", "dial_code": "+82"},
    {"name": "Kosovo", "flag": "🇽🇰", "code": "XK", "dial_code": "+383"},
    {"name": "Kuwait", "flag": "🇰🇼", "code": "KW", "dial_code": "+965"},
    {"name": "Kyrgyzstan", "flag": "🇰🇬", "code": "KG", "dial_code": "+996"},
    {"name": "Laos", "flag": "🇱🇦", "code": "LA", "dial_code": "+856"},
    {"name": "Latvia", "flag": "🇱🇻", "code": "LV", "dial_code": "+371"},
    {"name": "Lebanon", "flag": "🇱🇧", "code": "LB", "dial_code": "+961"},
    {"name": "Lesotho", "flag": "🇱🇸", "code": "LS", "dial_code": "+266"},
    {"name": "Liberia", "flag": "🇱🇷", "code": "LR", "dial_code": "+231"},
    {"name": "Libyan Arab Jamahiriya", "flag": "🇱🇾", "code": "LY", "dial_code": "+218"},
    {"name": "Liechtenstein", "flag": "🇱🇮", "code": "LI", "dial_code": "+423"},
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
    {"name": "Marshall Islands", "flag": "🇲🇭", "code": "MH", "dial_code": "+692"},
    {"name": "Martinique", "flag": "🇲🇶", "code": "MQ", "dial_code": "+596"},
    {"name": "Mauritania", "flag": "🇲🇷", "code": "MR", "dial_code": "+222"},
    {"name": "Mauritius", "flag": "🇲🇺", "code": "MU", "dial_code": "+230"},
    {"name": "Mayotte", "flag": "🇾🇹", "code": "YT", "dial_code": "+262"},
    {"name": "Mexico", "flag": "🇲🇽", "code": "MX", "dial_code": "+52"},
    {"name": "Micronesia, Federated States of Micronesia", "flag": "🇫🇲", "code": "FM", "dial_code": "+691"},
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
    {"name": "Netherlands Antilles", "flag": "", "code": "AN", "dial_code": "+599"},
    {"name": "New Caledonia", "flag": "🇳🇨", "code": "NC", "dial_code": "+687"},
    {"name": "New Zealand", "flag": "🇳🇿", "code": "NZ", "dial_code": "+64"},
    {"name": "Nicaragua", "flag": "🇳🇮", "code": "NI", "dial_code": "+505"},
    {"name": "Niger", "flag": "🇳🇪", "code": "NE", "dial_code": "+227"},
    {"name": "Nigeria", "flag": "🇳🇬", "code": "NG", "dial_code": "+234"},
    {"name": "Niue", "flag": "🇳🇺", "code": "NU", "dial_code": "+683"},
    {"name": "Norfolk Island", "flag": "🇳🇫", "code": "NF", "dial_code": "+672"},
    {"name": "Northern Mariana Islands", "flag": "🇲🇵", "code": "MP", "dial_code": "+1670"},
    {"name": "Norway", "flag": "🇳🇴", "code": "NO", "dial_code": "+47"},
    {"name": "Oman", "flag": "🇴🇲", "code": "OM", "dial_code": "+968"},
    {"name": "Pakistan", "flag": "🇵🇰", "code": "PK", "dial_code": "+92"},
    {"name": "Palau", "flag": "🇵🇼", "code": "PW", "dial_code": "+680"},
    {"name": "Palestinian Territory, Occupied", "flag": "🇵🇸", "code": "PS", "dial_code": "+970"},
    {"name": "Panama", "flag": "🇵🇦", "code": "PA", "dial_code": "+507"},
    {"name": "Papua New Guinea", "flag": "🇵🇬", "code": "PG", "dial_code": "+675"},
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
    {"name": "Saint Barthelemy", "flag": "🇧🇱", "code": "BL", "dial_code": "+590"},
    {"name": "Saint Helena, Ascension and Tristan Da Cunha", "flag": "🇸🇭", "code": "SH", "dial_code": "+290"},
    {"name": "Saint Kitts and Nevis", "flag": "🇰🇳", "code": "KN", "dial_code": "+1869"},
    {"name": "Saint Lucia", "flag": "🇱🇨", "code": "LC", "dial_code": "+1758"},
    {"name": "Saint Martin", "flag": "🇲🇫", "code": "MF", "dial_code": "+590"},
    {"name": "Saint Pierre and Miquelon", "flag": "🇵🇲", "code": "PM", "dial_code": "+508"},
    {"name": "Saint Vincent and the Grenadines", "flag": "🇻🇨", "code": "VC", "dial_code": "+1784"},
    {"name": "Samoa", "flag": "🇼🇸", "code": "WS", "dial_code": "+685"},
    {"name": "San Marino", "flag": "🇸🇲", "code": "SM", "dial_code": "+378"},
    {"name": "Sao Tome and Principe", "flag": "🇸🇹", "code": "ST", "dial_code": "+239"},
    {"name": "Saudi Arabia", "flag": "🇸🇦", "code": "SA", "dial_code": "+966"},
    {"name": "Senegal", "flag": "🇸🇳", "code": "SN", "dial_code": "+221"},
    {"name": "Serbia", "flag": "🇷🇸", "code": "RS", "dial_code": "+381"},
    {"name": "Seychelles", "flag": "🇸🇨", "code": "SC", "dial_code": "+248"},
    {"name": "Sierra Leone", "flag": "🇸🇱", "code": "SL", "dial_code": "+232"},
    {"name": "Singapore", "flag": "🇸🇬", "code": "SG", "dial_code": "+65"},
    {"name": "Slovakia", "flag": "🇸🇰", "code": "SK", "dial_code": "+421"},
    {"name": "Slovenia", "flag": "🇸🇮", "code": "SI", "dial_code": "+386"},
    {"name": "Solomon Islands", "flag": "🇸🇧", "code": "SB", "dial_code": "+677"},
    {"name": "Somalia", "flag": "🇸🇴", "code": "SO", "dial_code": "+252"},
    {"name": "South Africa", "flag": "🇿🇦", "code": "ZA", "dial_code": "+27"},
    {"name": "South Sudan", "flag": "🇸🇸", "code": "SS", "dial_code": "+211"},
    {"name": "South Georgia and the South Sandwich Islands", "flag": "🇬🇸", "code": "GS", "dial_code": "+500"},
    {"name": "Spain", "flag": "🇪🇸", "code": "ES", "dial_code": "+34"},
    {"name": "Sri Lanka", "flag": "🇱🇰", "code": "LK", "dial_code": "+94"},
    {"name": "Sudan", "flag": "🇸🇩", "code": "SD", "dial_code": "+249"},
    {"name": "Suriname", "flag": "🇸🇷", "code": "SR", "dial_code": "+597"},
    {"name": "Svalbard and Jan Mayen", "flag": "🇸🇯", "code": "SJ", "dial_code": "+47"},
    {"name": "Swaziland", "flag": "🇸🇿", "code": "SZ", "dial_code": "+268"},
    {"name": "Sweden", "flag": "🇸🇪", "code": "SE", "dial_code": "+46"},
    {"name": "Switzerland", "flag": "🇨🇭", "code": "CH", "dial_code": "+41"},
    {"name": "Syrian Arab Republic", "flag": "🇸🇾", "code": "SY", "dial_code": "+963"},
    {"name": "Taiwan", "flag": "🇹🇼", "code": "TW", "dial_code": "+886"},
    {"name": "Tajikistan", "flag": "🇹🇯", "code": "TJ", "dial_code": "+992"},
    {"name": "Tanzania, United Republic of Tanzania", "flag": "🇹🇿", "code": "TZ", "dial_code": "+255"},
    {"name": "Thailand", "flag": "🇹🇭", "code": "TH", "dial_code": "+66"},
    {"name": "Timor-Leste", "flag": "🇹🇱", "code": "TL", "dial_code": "+670"},
    {"name": "Togo", "flag": "🇹🇬", "code": "TG", "dial_code": "+228"},
    {"name": "Tokelau", "flag": "🇹🇰", "code": "TK", "dial_code": "+690"},
    {"name": "Tonga", "flag": "🇹🇴", "code": "TO", "dial_code": "+676"},
    {"name": "Trinidad and Tobago", "flag": "🇹🇹", "code": "TT", "dial_code": "+1868"},
    {"name": "Tunisia", "flag": "🇹🇳", "code": "TN", "dial_code": "+216"},
    {"name": "Turkey", "flag": "🇹🇷", "code": "TR", "dial_code": "+90"},
    {"name": "Turkmenistan", "flag": "🇹🇲", "code": "TM", "dial_code": "+993"},
    {"name": "Turks and Caicos Islands", "flag": "🇹🇨", "code": "TC", "dial_code": "+1649"},
    {"name": "Tuvalu", "flag": "🇹🇻", "code": "TV", "dial_code": "+688"},
    {"name": "Uganda", "flag": "🇺🇬", "code": "UG", "dial_code": "+256"},
    {"name": "Ukraine", "flag": "🇺🇦", "code": "UA", "dial_code": "+380"},
    {"name": "United Arab Emirates", "flag": "🇦🇪", "code": "AE", "dial_code": "+971"},
    {"name": "United Kingdom", "flag": "🇬🇧", "code": "GB", "dial_code": "+44"},
    {"name": "United States", "flag": "🇺🇸", "code": "US", "dial_code": "+1"},
    {"name": "Uruguay", "flag": "🇺🇾", "code": "UY", "dial_code": "+598"},
    {"name": "Uzbekistan", "flag": "🇺🇿", "code": "UZ", "dial_code": "+998"},
    {"name": "Vanuatu", "flag": "🇻🇺", "code": "VU", "dial_code": "+678"},
    {"name": "Venezuela, Bolivarian Republic of Venezuela", "flag": "🇻🇪", "code": "VE", "dial_code": "+58"},
    {"name": "Vietnam", "flag": "🇻🇳", "code": "VN", "dial_code": "+84"},
    {"name": "Virgin Islands, British", "flag": "🇻🇬", "code": "VG", "dial_code": "+1284"},
    {"name": "Virgin Islands, U.S.", "flag": "🇻🇮", "code": "VI", "dial_code": "+1340"},
    {"name": "Wallis and Futuna", "flag": "🇼🇫", "code": "WF", "dial_code": "+681"},
    {"name": "Yemen", "flag": "🇾🇪", "code": "YE", "dial_code": "+967"},
    {"name": "Zambia", "flag": "🇿🇲", "code": "ZM", "dial_code": "+260"},
    {"name": "Zimbabwe", "flag": "🇿🇼", "code": "ZW", "dial_code": "+263"}
  ];

  int activeStep = 0, previouslyReachedStep = 0;
  late FocusNode myFocusNode;
  final _formKey = GlobalKey<FormState>();
  bool checkedValue = false, checkboxValue = false, isProfilePicturePicked = false;
  XFile? imageFile;
  UserProfile userProfile = UserProfile(
      id: '', fullName: '', email: '', phoneNumber: '', timeStamp: FieldValue.serverTimestamp(), profileImage: '');
  final formKey = GlobalKey<FormState>();
  //UserType _userType = UserType.normalUser;
  bool checkedValidNumber = false,
      isParkingOwner = false,
      fromLoginForm = false,
      isLogView = true,
      obscurText = true,
      obscurTextConfPass = true,
      isPhoneNumberValidated = false;

  final TextEditingController _emailController = TextEditingController(),
      _passwordController = TextEditingController(),
      _confirmPasswordController = TextEditingController(),
      _numberController = TextEditingController(),
      _fullNameController = TextEditingController();

  final GoogleSignIn _myGoogleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  var theCodeForPhone = 'ok';
  String savedFullName = '', savedEmail = '', savedNumber = '';
  FirebaseService service = FirebaseService();
  FirestoreUserService firestoreService = FirestoreUserService();
  User? currentUser;
  double headerHeight = 300;
  final _pin_formKey = GlobalKey<FormState>();
  bool _pinSuccess = false;

  @override
  void initState() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
    myFocusNode = FocusNode();
    getCarrierCode(countries).then((value) => setState(
          () => theCodeForPhone = value,
        ));

    super.initState();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    myFocusNode.dispose();
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var localLnSetting = AppLocalizations.of(context)!;
    print("PREVIOUSLY REACHEDSTEP $previouslyReachedStep");

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(child: bodySwitch(localLnSetting)),
      ),
    );
  }

  myValidateNumber() async {
    bool validSnPhoneNumber = false;
    String fetchedNumber = _numberController.text;
    prefix.RegionInfo region = const prefix.RegionInfo(name: 'Senegal', code: 'SN', prefix: 221);

    try {
      validSnPhoneNumber = await prefix.PhoneNumberUtil().validate(fetchedNumber, regionCode: region.code);
      if (!validSnPhoneNumber) {
        Fluttertoast.showToast(
            msg: 'Please check number format.',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            fontSize: 16.0);

        return validSnPhoneNumber;
      }
    } catch (e) {
      Fluttertoast.showToast(
          msg: 'Please enter a phone number.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          fontSize: 16.0);
    }
    if (validSnPhoneNumber) {
      checkedValidNumber = true;
    } else {
      checkedValidNumber = false;
    }
    print(' CHECKED VALID NUMBER IS $checkedValidNumber');
  }

  registerWithEmailPassword() async {
    isLogView = false;

    //UserProfile fetchedUP = userProfile;
    try {
      UserCredential user =
          await _auth.createUserWithEmailAndPassword(email: _emailController.text, password: _passwordController.text);

      await firestoreService.createUser(UserProfile(
        id: user.user!.uid,
        fullName: _fullNameController.text,
        email: _emailController.text,
        phoneNumber: _numberController.text,
        /*userRole: _userType.toString()*/
        timeStamp: FieldValue.serverTimestamp(),
        profileImage: "assets/images/no_profile_picture_grey.png",
      ));

      userProfile = UserProfile(
        id: user.user!.uid,
        fullName: _fullNameController.text,
        email: _emailController.text,
        phoneNumber: _numberController.text,
        /* userRole: _userType.toString()*/
        timeStamp: FieldValue.serverTimestamp(),
        profileImage: "assets/images/no_profile_picture_grey.png",
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Home(
            fromLoginView: false,
            theUserProfile: userProfile,
            parkingToNavigateTo: const {},
            newIndex: 0,
            timeUntilResStarts: 0,
          ),
        ),
      );
      Fluttertoast.showToast(
          msg: 'Sucessfully registered. Welcome.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          fontSize: 16.0);

      _auth.authStateChanges().listen((user) async {
        if (user != null && isLogView == false) {
/*           user.reload();
 */
          currentUser = user;
          User? thisCurrently = FirebaseAuth.instance.currentUser;
          //displayname and photoURL will be null at first because we are signing in with password and email and because we are not signing in with google or a known provider.
          print(
              'USER IS REGISTERED PERFECT! ------------- USER ID :${user.uid} '); //this is for me to view on the debugging console};
          print(
              'CURRENT USERS DISPLAYNAME : ${currentUser!.displayName} ---- Users DN ${user.displayName}----- EMAIL: ${currentUser!.email}------  ID ${currentUser!.uid} ');

          thisCurrently?.updateDisplayName(userProfile.fullName);
          thisCurrently?.updatePhotoURL(userProfile.profileImage);
          print(
              'CURRENT USERS DISPLAYNAME AFTER UPDATE: ${thisCurrently?.displayName} ____ DISPLAYNAME ${userProfile.fullName}  ____ ProfileIMAGE ${thisCurrently?.photoURL} ');
        } else {
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

        default:
          {}
      }
      print('Error: $e');
    }
  } //closing brackets

  /* ------------- FETCH AND SAVE FIELDS DATA -------------*/
  bool savedFormFields() {
    final form = formKey.currentState;
    myValidateNumber();
    if (form!.validate() && checkedValidNumber && _passwordController.text == _confirmPasswordController.text) {
      form.save();
      print(
          'Form is valid. Full Name : $_fullNameController, Email: $_emailController , Password: $_passwordController, Phone number: $_numberController');
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

  void submitForm() async {
    if (savedFormFields()) {
      //In the newest version of firebase_auth, the class FirebaseUser was changed to User, and the class AuthResult was changed to UserCredential.

      registerWithEmailPassword();
    }
  }

  void moveToRegister() {
    formKey.currentState!.reset();
    setState(() {});

    super.deactivate();
  }

  void moveToLogIn() {
    formKey.currentState!.reset();

    setState(() {});
    super.deactivate();
  }

  void getImage(ImageSource source) async {
    try {
      final pickedImage = await ImagePicker().pickImage(source: source);
      if (pickedImage != null) {
        imageFile = pickedImage;
        isProfilePicturePicked = true;
        setState(() {});
      }
    } catch (e) {
      print("error $e");
    }
  }

  bodySwitch(AppLocalizations localLnSetting) {
    var ha = countries.where((element) => element['code'].toString().toLowerCase() == theCodeForPhone);
    ha.isNotEmpty
        ? {
            print('HA ${ha.first} ${ha.first['flag'].runtimeType}'),
          }
        : null;
    PhoneNumber number = PhoneNumber(isoCode: ha.isNotEmpty ? ha.first['code'] : 'SN');
    switch (activeStep) {
      case 0:
        return Stack(
          children: [
            const SizedBox(
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
                    key: _formKey,
                    onChanged: () {
                      _formKey.currentState!.save();
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
                                  border: Border.all(width: 5, color: Colors.white),
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
                                          File(imageFile!.path),
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
                                padding: const EdgeInsets.fromLTRB(80, 80, 0, 0),
                                child: IconButton(
                                    onPressed: () {
                                      getImage(ImageSource.gallery);
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
                          decoration: ThemeHelper().inputBoxDecorationShaddow(),
                          child: TextFormField(
                            controller: _fullNameController,
                            autovalidateMode: AutovalidateMode.disabled,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp("[A-Za-z' -]*"), replacementString: ''),
                            ],
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                            ]),
                            decoration: ThemeHelper().textInputDecoration(Icons.perm_identity,
                                localLnSetting.regFullNameLabel, localLnSetting.regFullNamePlaceholder),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Container(
                          decoration: ThemeHelper().inputBoxDecorationShaddow(),
                          child: TextFormField(
                            controller: _emailController,
                            decoration: ThemeHelper().textInputDecoration(
                                Icons.email, localLnSetting.regEmailLabel, localLnSetting.regEmailPlaceholder),
                            keyboardType: TextInputType.emailAddress,
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                              FormBuilderValidators.match(
                                  r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$",
                                  errorText: localLnSetting.logErrorBadEmailFormat)
                            ]),
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        /*   Container(
                          decoration: ThemeHelper().inputBoxDecorationShaddow(),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                color: Colors.red,
                              ),
                              Container(
                                width: 100,
                                height: 50,
                                color: Colors.green,
                              )
                            ],
                          ),
                        ),
                       */
                        InternationalPhoneNumberInput(
                          onInputChanged: (PhoneNumber number) {
                            print(number.phoneNumber);
                          },
                          onInputValidated: (bool value) {
                            setState(() {
                              isPhoneNumberValidated = true;
                            });
                            print('VALIDATED $value');
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
                            contentPadding: const EdgeInsets.fromLTRB(20, 10, 0, 10),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(100.0),
                                borderSide: const BorderSide(color: Colors.grey)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(100.0),
                                borderSide: BorderSide(color: Colors.grey.shade400)),
                            errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(100.0),
                                borderSide: const BorderSide(color: Colors.red, width: 2.0)),
                            focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(100.0),
                                borderSide: const BorderSide(color: Colors.red, width: 2.0)),
                          ),
                          ignoreBlank: false,
                          errorMessage: localLnSetting.regNumberError,
                          autoValidateMode: AutovalidateMode.disabled,
                          selectorTextStyle: const TextStyle(color: Colors.black),
                          initialValue: number,
                          textFieldController: _numberController,
                          formatInput: false,
                          keyboardType: const TextInputType.numberWithOptions(),
                          onSaved: (PhoneNumber number) {
                            print('On Saved: $number');
                          },
                        ),
                        const SizedBox(height: 20.0),
                        Container(
                          decoration: ThemeHelper().inputBoxDecorationShaddow(),
                          child: TextFormField(
                              autovalidateMode: AutovalidateMode.disabled,
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(),
                                FormBuilderValidators.match(
                                    r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$',
                                    errorText: localLnSetting.regPasswordHelper),
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
                                      obscurText == true ? obscurText = false : obscurText = true;
                                    });
                                  },
                                  child: Icon(obscurText ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                ),
                                labelText: localLnSetting.regPasswordLabel,
                                hintText: localLnSetting.regPasswordPlaceholder,
                                fillColor: Colors.white,
                                filled: true,
                                helperText: localLnSetting.regPasswordHelper,
                                helperMaxLines: 1,

                                // helperStyle: TextStyle(height: 0.4),
                                contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(100.0),
                                    borderSide: const BorderSide(color: Colors.grey)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(100.0),
                                    borderSide: BorderSide(color: Colors.grey.shade400)),
                                errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(100.0),
                                    borderSide: const BorderSide(color: Colors.red, width: 2.0)),
                                focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(100.0),
                                    borderSide: const BorderSide(color: Colors.red, width: 2.0)),
                              )),
                        ),
                        const SizedBox(height: 20.0),
                        Container(
                          decoration: ThemeHelper().inputBoxDecorationShaddow(),
                          child: TextFormField(
                              autovalidateMode: AutovalidateMode.disabled,
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(),
                                FormBuilderValidators.match(
                                    r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$',
                                    errorText: localLnSetting.regConfirmPassError),
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
                                  child: Icon(
                                      obscurTextConfPass ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                ),
                                labelText: localLnSetting.regConfirmPassLabel,
                                hintText: localLnSetting.regConfirmPassPlaceholder,
                                fillColor: Colors.white,
                                filled: true,
                                contentPadding: const EdgeInsets.fromLTRB(20, 10, 0, 10),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(100.0),
                                    borderSide: const BorderSide(color: Colors.grey)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(100.0),
                                    borderSide: BorderSide(color: Colors.grey.shade400)),
                                errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(100.0),
                                    borderSide: const BorderSide(color: Colors.red, width: 2.0)),
                                focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(100.0),
                                    borderSide: const BorderSide(color: Colors.red, width: 2.0)),
                              )),
                        ),
                        const SizedBox(height: 55.0),
                        AnimatedSmoothIndicator(
                          activeIndex: activeStep,
                          duration: const Duration(milliseconds: 400),
                          count: 2,
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
                        const SizedBox(height: 25.0),
                        Container(
                          decoration: ThemeHelper().buttonBoxDecoration(context),
                          child: ElevatedButton(
                              style: ThemeHelper().buttonStyle(),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(40, 10, 40, 10),
                                child: Text(
                                  localLnSetting.regNextButton.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              onPressed: () {
                                var matchingPasswords =
                                    toastValidationMessages(_confirmPasswordController.text, localLnSetting).toString();
                                matchingPasswords.isEmpty && _formKey.currentState!.validate()
                                    ? setState(() {
                                        previouslyReachedStep = 1;
                                        savedNumber = _numberController.text;
                                        _numberController.clear();
                                        activeStep = 1;
                                      })
                                    : null;
                                /* if (_formKey.currentState!.validate()) {
                                setState(() {
                                  activeStep = 1;
                                }); */
                                /*  Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(builder: (context) => const ProfilePage()),
                                      (Route<dynamic> route) => false); */
                              }),
                        ),
                        Container(
                          margin: const EdgeInsets.fromLTRB(10, 20, 10, 20),
                          //child: Text('Don\'t have an account? Create'),
                          child: Text.rich(TextSpan(children: [
                            TextSpan(text: localLnSetting.alreadyHaveAccount),
                            TextSpan(
                              text: localLnSetting.regGoToLogInLink,
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  /*  Navigator.push(context,
                                                    MaterialPageRoute(builder: (context) => const TestRegister())); */
                                },
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.secondary,
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

      case 1:
        return Stack(children: [
          const SizedBox(
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
                SizedBox(
                  height: headerHeight,
                  child: HeaderWidget(
                    height: headerHeight,
                    icon: Icons.privacy_tip_outlined,
                    showIcon: true,
                  ),
                ),
                SafeArea(
                  child: Container(
                    //margin: const EdgeInsets.fromLTRB(25, 10, 25, 10),
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: Column(
                      children: [
                        Container(
                          alignment: Alignment.topLeft,
                          margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Verification',
                                style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.black54),
                                // textAlign: TextAlign.center,
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                'Enter the verification code we just sent you on your email address.',
                                style: TextStyle(
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
                          key: _pin_formKey,
                          child: Column(
                            children: <Widget>[
                              Container(
                                width: 200,
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: OTPTextField(
                                        length: 6,
                                        width: 200,
                                        fieldWidth: 30,
                                        style: const TextStyle(fontSize: 30),
                                        textFieldAlignment: MainAxisAlignment.spaceAround,
                                        fieldStyle: FieldStyle.underline,
                                        onCompleted: (pin) {
                                          setState(() {
                                            _pinSuccess = true;
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
                                    const TextSpan(
                                      text: "If you didn't receive a code! ",
                                      style: TextStyle(
                                        color: Colors.black38,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Resend',
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return ThemeHelper().alartDialog(
                                                  "Successful", "Verification code resend successful.", context);
                                            },
                                          );
                                        },
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                                    ),
                                  ],
                                ),
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
                                          /*  Navigator.of(context).pushAndRemoveUntil(
                                            MaterialPageRoute(builder: (context) => const ProfilePage()),
                                            (Route<dynamic> route) => false); */
                                        }
                                      : null,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(40, 10, 40, 10),
                                    child: Text(
                                      "Verify".toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                ElevatedButton(
                    onPressed: () {
                      setState(() {
                        activeStep = 0;
                      });
                    },
                    child: Text('back')),
                AnimatedSmoothIndicator(
                  activeIndex: activeStep,
                  duration: const Duration(milliseconds: 400),
                  count: 2,
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
                Container(
                    decoration: ThemeHelper().buttonBoxDecoration(context),
                    child: ElevatedButton(
                      style: ThemeHelper().buttonStyle(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(40, 10, 40, 10),
                        child: Text(
                          localLnSetting.regNextButton.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      onPressed: () {
                        var matchingPasswords =
                            toastValidationMessages(_confirmPasswordController.text, localLnSetting).toString();
                        matchingPasswords.isEmpty && _pin_formKey.currentState!.validate()
                            ? setState(() {
                                previouslyReachedStep = 1;
                                savedNumber = _numberController.text;
                                _numberController.clear();
                                activeStep = 1;
                              })
                            : null;
                      },
                    ))
              ],
            ),
          )
        ]);

      case 2:
        return Container();
    }
  }

  String? toastValidationMessages(String? value, AppLocalizations localLnSetting) {
    String theMessage = '';
    if (_passwordController.text != _confirmPasswordController.text && _passwordController.text.isNotEmpty) {
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

  Future<String> getCarrierCode(List<Map<String, dynamic>> countries) async {
    String code = await prefix.PhoneNumberUtil().carrierRegionCode();
    return code;
  }
}///ending crochet


