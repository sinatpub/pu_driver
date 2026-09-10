/// Static content — no backend, no localization today (the strings are
/// English-only in the app as shipped). Held here rather than rebuilt inside
/// `build()` on every frame, which is what `termcondition_screen.dart` did.
class TermConditionState {
  final List<String> terms = const [
    "All payments are made directly to the driver and are accepted in cash or with QR code.",
    "The company and its member drivers cannot be held responsible for any actual or consequential financial or professional loss due to the late or non-arrival of any rickshaw or cab.",
    "The company cannot be held responsible for losses consequential from missed connections due to adverse weather or any other events.",
    "The company and its member drivers reserve the right to refuse to carry passengers who are deeply under the influence of alcohol or drugs.",
    "All bookings accepted by the company will be bound by these terms and conditions.",
  ];
}
