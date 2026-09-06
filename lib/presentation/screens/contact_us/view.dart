import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import 'logic.dart';

/// Rendered as a tab body inside `DrawerScreen`, not as its own route — its
/// binding is attached to [AppRoutes.home] (`14` §3.5), mirroring how the
/// passenger app binds its `bottom_nav` tabs.
class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ContactUsLogic logic = Get.find<ContactUsLogic>();
    final state = logic.state;

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
            const SizedBox(height: 16),
            Text(
              state.blurb,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.phone),
              title: Text("Smart: ${state.smartPhone}"),
              onTap: () =>
                  logic.callPhone(state.smartPhone.replaceAll(' ', '')),
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: Text("Cellcard: ${state.cellcardPhone}"),
              onTap: () =>
                  logic.callPhone(state.cellcardPhone.replaceAll(' ', '')),
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: Text(state.email),
              onTap: () => logic.sendEmail(state.email),
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(state.address),
            ),
            const Spacer(),
            Text(
              state.copyright,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
