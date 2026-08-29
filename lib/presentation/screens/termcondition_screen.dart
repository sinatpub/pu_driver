import 'package:flutter/material.dart';

class TermsOfServicePage extends StatefulWidget {
  const TermsOfServicePage({super.key});

  @override
  State<TermsOfServicePage> createState() => _TermsOfServicePageState();
}

class _TermsOfServicePageState extends State<TermsOfServicePage> {
  @override
  Widget build(BuildContext context) {
    final terms = [
      "All payments are made directly to the driver and are accepted in cash or with QR code.",
      "The company and its member drivers cannot be held responsible for any actual or consequential financial or professional loss due to the late or non-arrival of any rickshaw or cab.",
      "The company cannot be held responsible for losses consequential from missed connections due to adverse weather or any other events.",
      "The company and its member drivers reserve the right to refuse to carry passengers who are deeply under the influence of alcohol or drugs.",
      "All bookings accepted by the company will be bound by these terms and conditions.",
    ];
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
            // const SizedBox(height: 20),
            // SizedBox(
            //   width: double.infinity,
            //   child: ElevatedButton(
            //     onPressed: () {
            //       // Handle agreement here
            //       // Navigator.pop(context);
            //     },
            //     child: const Text("I Agree"),
            //   ),
            // )
          ],
        ),
      ),
    );
  }
}
