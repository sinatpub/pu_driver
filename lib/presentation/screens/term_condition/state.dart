/// Static content — no backend. Held here rather than rebuilt inside
/// `build()` on every frame, which is what `termcondition_screen.dart` did.
///
/// P2: the five terms are locale keys (`TERM_1`…`TERM_5`), same text, same
/// order. The Khmer file carries the English text until a legal translation
/// is supplied — a machine or developer draft of legal terms is not shipped.
class TermConditionState {
  final List<String> termKeys = const [
    'TERM_1',
    'TERM_2',
    'TERM_3',
    'TERM_4',
    'TERM_5',
  ];
}
