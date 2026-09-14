import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/presentation/screens/calculate_fee/widgets/receipt_card.dart';
import 'package:tara_driver_application/presentation/screens/booking/widgets/passenger_row.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

import '../../../helpers/localized_host.dart';

/// UX-redesign C6 — the payment receipt and total (`04 § B`).
///
/// `calculate_fee/view.dart` itself is not pumped: it reaches for a GetX
/// controller and `formatDateTime` string parsing. Its behaviour (both entry
/// payloads, emit-after-REST order, immediate navigation) is verified on a
/// device against the G0 baseline.
///
/// The assertions that matter: the hardcoded "Unknown Payment" is gone
/// (`DD-18`), there is no call button on the receipt, and the server amount
/// renders as a neutral hero figure (`DD-04`).
void main() {
  group('ReceiptCard', () {
    testWidgets('renders the trip facts and addresses, no call button',
        (WidgetTester t) async {
      await t.pumpWidget(
        localizedHost(
          const ReceiptCard(
            passengerName: 'Mey Lin',
            distance: '3.50 km',
            duration: '14:20',
            dateTime: 'Sat/12/Sep/2026 09:30 AM',
            startAddress: 'St. 271, Phnom Penh',
            endAddress: 'Sisowath Quay',
          ),
        ),
      );
      await t.pumpAndSettle();

      expect(find.text('Mey Lin'), findsOneWidget);
      expect(find.text('3.50 km'), findsOneWidget);
      expect(find.text('14:20'), findsOneWidget);
      expect(find.text('Sat/12/Sep/2026 09:30 AM'), findsOneWidget);
      expect(find.text('St. 271, Phnom Penh'), findsOneWidget);
      expect(find.text('Sisowath Quay'), findsOneWidget);
      // C6 (€3 §641): the receipt carries no call action.
      expect(find.byType(TIconButton), findsNothing);
      expect(find.byType(PassengerRow), findsOneWidget);
    });

    testWidgets('shows the real payment method from the payload',
        (WidgetTester t) async {
      await t.pumpWidget(
        localizedHost(
          const ReceiptCard(
            passengerName: 'Mey Lin',
            method: 'Cash',
            distance: '3.50 km',
            duration: '14:20',
            dateTime: 'Sat/12/Sep/2026 09:30 AM',
            startAddress: 'st',
            endAddress: 'end',
          ),
        ),
      );
      await t.pumpAndSettle();

      expect(find.text('Cash'), findsOneWidget);
      // The old hardcoded string is gone (DD-18).
      expect(find.textContaining('Unknown Payment'), findsNothing);
    });

    testWidgets('omits the badge when the payload has no method',
        (WidgetTester t) async {
      await t.pumpWidget(
        localizedHost(
          const ReceiptCard(
            passengerName: 'Mey Lin',
            distance: '3.50 km',
            duration: '14:20',
            dateTime: 'Sat/12/Sep/2026 09:30 AM',
            startAddress: 'st',
            endAddress: 'end',
          ),
        ),
      );
      await t.pumpAndSettle();

      expect(find.byType(TBadge), findsNothing);
    });
  });

  group('TotalBox', () {
    testWidgets('renders the total to collect as the one figure',
        (WidgetTester t) async {
      await t.pumpWidget(localizedHost(const TotalBox(amount: '៛7,600')));
      await t.pumpAndSettle();

      expect(find.text('Total to collect'), findsOneWidget);
      expect(find.text('៛7,600'), findsOneWidget);
      // Neutral money, no estimate line (DD-04, DD-18).
      expect(find.textContaining('≈'), findsNothing);
    });
  });
}
