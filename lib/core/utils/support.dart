import 'package:url_launcher/url_launcher.dart';

/// GRID's support line.
const supportPhone = '+233300000000';

/// Opens the dialler on [phone]. False when the device can't place calls.
Future<bool> dial(String phone) async {
  final number = phone.startsWith('+') ? phone : '+$phone';
  try {
    return await launchUrl(Uri(scheme: 'tel', path: number));
  } on Object {
    return false;
  }
}
