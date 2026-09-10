import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import 'logic.dart';

/// Tab body inside `DrawerScreen`; binding attached to [AppRoutes.home]
/// (`14` §3.5).
class TermConditionPage extends StatelessWidget {
  const TermConditionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final terms = Get.find<TermConditionLogic>().state.terms;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: terms.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${index + 1}. ",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Text(
                          terms[index],
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
