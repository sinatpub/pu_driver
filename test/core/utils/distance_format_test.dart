import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pu_taxi_driver/core/utils/clock_format.dart';
import 'package:pu_taxi_driver/core/utils/distance_format.dart';

import '../../helpers/localized_host.dart';

/// DD-39 — the server's distance and duration text, read as the trip screens
/// show them.
void main() {
  testWidgets('distance text', (WidgetTester t) async {
    late List<String> out;
    await t.pumpWidget(localizedHost(Builder(builder: (_) {
      out = <String>[
        formatDistanceText('3.08 km'),
        formatDistanceText('3.08'),
        formatDistanceText('850 m'),
        formatDistanceText('about 3 km'),
      ];
      return const SizedBox();
    })));
    await t.pumpAndSettle();

    expect(out, <String>['3.1 KM', '3.1 KM', '850 M', 'about 3 km']);
  });

  test('duration text', () {
    expect(parseDurationText('8 mins 24 seconds'),
        const Duration(minutes: 8, seconds: 24));
    expect(parseDurationText('1 hours 5 mins'),
        const Duration(hours: 1, minutes: 5));
    expect(parseDurationText('14 min'), const Duration(minutes: 14));
    expect(parseDurationText('14:20'), isNull);
  });
}
