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
}
