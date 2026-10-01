import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Trans;
import 'package:url_launcher/url_launcher.dart';

import 'state.dart';

/// `14` §3.3: launching a dialer/mail client is user intent, so it lives here
/// rather than in the view. Behavior is identical to the old
/// `contact_us_screen.dart` — same `canLaunchUrl` guard, same debugPrint on
/// failure.
class ContactUsLogic extends GetxController {
  final ContactUsState state = ContactUsState();

  Future<void> callPhone(String phoneNumber) async {
    final Uri uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('Could not launch $phoneNumber');
    }
  }

  Future<void> sendEmail(String email) async {
    final Uri uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('Could not launch $email');
    }
  }

  /// Opens the office address in the phone's maps app (DD-44).
  Future<void> openMap(String address) async {
    final Uri uri = Uri.https(
      'www.google.com',
      '/maps/search/',
      <String, String>{'api': '1', 'query': address},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not open the map for $address');
    }
  }
}

/// A Cambodian number as people there write and say it: "+855 70 427 213" →
/// "070 427 213". The country code becomes the leading 0 and the digits are
/// grouped in threes. A number that is not +855 is returned as given.
///
/// Display only — dialling still uses the full international number.
String formatLocalPhone(String phone) {
  final String digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  if (!digits.startsWith('+855')) return phone;
  final String local = '0${digits.substring(4)}';
  final List<String> groups = <String>[
    for (int i = 0; i < local.length; i += 3)
      local.substring(i, i + 3 > local.length ? local.length : i + 3),
  ];
  return groups.join(' ');
}
