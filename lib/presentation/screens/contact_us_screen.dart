import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

Future<void> _makePhoneCall(String phoneNumber) async {
  final Uri uri = Uri.parse('tel:$phoneNumber');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    debugPrint('Could not launch $phoneNumber');
  }
}

Future<void> _sendEmail(String email) async {
  final Uri uri = Uri(
    scheme: 'mailto',
    path: email,
  );
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    debugPrint('Could not launch $email');
  }
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Image(
                  image: AssetImage("assets/image/png/company_logo.png"),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // const Text(
            //   "តារា Tara Company",
            //   style: TextStyle(
            //     fontSize: 20,
            //     fontWeight: FontWeight.bold,
            //     color: AppColors.main,
            //   ),
            // ),
            const SizedBox(height: 16),
            const Text(
              "Feel free to reach out to us if you have any questions, feedback, or issues.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Contact Info
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text("Smart: +855 70 427 213"),
              onTap: () => _makePhoneCall("+85570427213"),
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text("Cellcard: +855 12 285 048"),
              onTap: () => _makePhoneCall("+85512285048"),
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text("tarataxi24@gmail.com"),
              onTap: () => _sendEmail("tarataxi24@gmail.com"),
            ),
            const ListTile(
              leading: Icon(Icons.location_on),
              title: Text(
                  "#74, Street 192, Sangkat Teuk Laok 3, Toul Kork District, Phnom Penh"),
            ),
            const Spacer(),
            const Text(
              "© 2025 TAARRAA. All rights reserved.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
