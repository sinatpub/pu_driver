import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// UX-redesign P2 — the copy and localization sweep's guard rails.
///
/// Static checks over the source and the two locale files; nothing is pumped.
Map<String, dynamic> _load(String lang) =>
    json.decode(File('assets/translations/$lang.json').readAsStringSync())
        as Map<String, dynamic>;

Iterable<File> _dartFiles(String dir) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .where((File f) => f.path.endsWith('.dart'));

void main() {
  final Map<String, dynamic> en = _load('en');
  final Map<String, dynamic> km = _load('km');

  test('EN and KM define exactly the same keys, none empty', () {
    expect(en.keys.toSet().difference(km.keys.toSet()), isEmpty);
    expect(km.keys.toSet().difference(en.keys.toSet()), isEmpty);
    for (final MapEntry<String, dynamic> e in <MapEntry<String, dynamic>>[
      ...en.entries,
      ...km.entries,
    ]) {
      expect((e.value as String).trim(), isNotEmpty, reason: e.key);
    }
  });

  test('notification titles keep their values (06 §3, DD-29)', () {
    // `booking/logic.dart` reuses these as local-notification titles; the
    // redesign adds ACTION_* keys for the buttons instead of editing them.
    expect(en['ACCEPT'], 'Accept');
    expect(en['ARRIVE'], 'Arrive');
    expect(en['START_RIDE'], 'Start Ride');
    expect(km['ACCEPT'], 'ទទួលយក');
    expect(km['ARRIVE'], 'មកដល់');
    expect(km['START_RIDE'], 'ចាប់ផ្ដើមដឹក');
  });

  test('every literal key translated in lib/ exists', () {
    final RegExp literalTr = RegExp(r'''['"]([A-Z][A-Z0-9_]+)['"]\s*\.tr\(''');
    final Set<String> missing = <String>{};
    for (final File f in _dartFiles('lib')) {
      for (final RegExpMatch m in literalTr.allMatches(f.readAsStringSync())) {
        if (!en.containsKey(m.group(1)))
          missing.add('${m.group(1)} (${f.path})');
      }
    }
    expect(missing, isEmpty);
  });

  test('no hardcoded English copy in widget text parameters', () {
    // A literal with a lowercase word, passed where the driver reads it.
    final RegExp copy = RegExp(
      r'''(Text\(|title:|label:|message:|hint:|hintText:|description:|actionLabel:|semanticLabel:)\s*['"]([^'"$]*[a-z]{2,}[^'"]*)['"]\s*[,)]''',
    );
    final Set<String> found = <String>{};
    for (final File f in <File>[
      ..._dartFiles('lib/presentation'),
      ..._dartFiles('lib/app'),
    ]) {
      for (final RegExpMatch m in copy.allMatches(f.readAsStringSync())) {
        found.add('${f.path}: "${m.group(2)}"');
      }
    }
    // Not copy: a language name is shown in its own language; Smart and
    // Cellcard are carrier brand names in front of a phone number; the plate
    // hint is a format placeholder.
    const List<String> allowed = <String>[
      '"English"',
      r'"Smart: ${state.smartPhone}"',
      r'"Cellcard: ${state.cellcardPhone}"',
      '"xxx-xxxx"',
    ];
    found.removeWhere((String s) => allowed.any(s.endsWith));
    expect(found, isEmpty);
  });
}
