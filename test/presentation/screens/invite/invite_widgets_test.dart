import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tara_driver_application/core/theme/app_theme.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/screens/invite/widgets/invite_code_field.dart';
import 'package:tara_driver_application/presentation/screens/invite/widgets/invite_widgets.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

/// The invite screens' pieces (DD-45). The views themselves reach for GetX
/// and are not pumped; the rules are in `invite_presentation_test.dart`.
Widget _host(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(khmer: false),
    home: Scaffold(body: Center(child: SingleChildScrollView(child: child))),
  );
}

void main() {
  group('InviteQrCard', () {
    Widget card({VoidCallback? onCopy}) => InviteQrCard(
          data: 'https://putaxi.example/i/PU7K2M',
          code: 'PU7K2M',
          codeLabel: 'Invite code',
          copyLabel: 'Copy code',
          qrLabel: 'Your invite QR code',
          onCopy: onCopy ?? () {},
        );

    testWidgets('the QR holds the link, and the code is printed under it',
        (WidgetTester t) async {
      await t.pumpWidget(_host(card()));

      final QrImageView qr = t.widget(find.byType(QrImageView));
      expect(find.text('PU7K2M'), findsOneWidget);
      expect(find.text('Invite code'), findsOneWidget);
      // High error correction: the mark in the middle covers modules.
      expect(qr.errorCorrectionLevel, QrErrorCorrectLevel.H);
      expect(find.bySemanticsLabel('Your invite QR code'), findsOneWidget);
    });

    testWidgets('the QR is black on white, whatever the theme',
        (WidgetTester t) async {
      await t.pumpWidget(_host(card()));

      final QrImageView qr = t.widget(find.byType(QrImageView));
      expect(qr.backgroundColor, Colors.white);
      expect(qr.dataModuleStyle.color, Colors.black);
      expect(qr.eyeStyle.color, Colors.black);
    });

    testWidgets('the copy button copies', (WidgetTester t) async {
      int copied = 0;
      await t.pumpWidget(_host(card(onCopy: () => copied++)));

      await t.tap(find.bySemanticsLabel('Copy code'));
      expect(copied, 1);
    });
  });

  testWidgets('InviteFab is a labelled 56 px button', (WidgetTester t) async {
    int taps = 0;
    await t.pumpWidget(
      _host(InviteFab(semanticLabel: 'My QR', onPressed: () => taps++)),
    );

    expect(t.getSize(find.byType(InviteFab)), const Size(56, 56));
    await t.tap(find.bySemanticsLabel('My QR'));
    expect(taps, 1);
  });

  testWidgets('InviteRules shows a line per rule, and nothing with no rule',
      (WidgetTester t) async {
    await t.pumpWidget(
      _host(const InviteRules(driverRule: 'Driver: 1%', passengerRule: null)),
    );
    expect(find.text('Driver: 1%'), findsOneWidget);
    expect(find.byType(TCard), findsOneWidget);

    await t.pumpWidget(
      _host(const InviteRules(driverRule: null, passengerRule: null)),
    );
    expect(find.byType(TCard), findsNothing);
  });

  testWidgets('InviteSummaryCard shows what was earned and opens on tap',
      (WidgetTester t) async {
    int taps = 0;
    await t.pumpWidget(
      _host(
        InviteSummaryCard(
          title: 'Invite rewards',
          summary: '៛5,160 earned · 5 invited',
          onTap: () => taps++,
        ),
      ),
    );

    expect(find.text('៛5,160 earned · 5 invited'), findsOneWidget);
    await t.tap(find.text('Invite rewards'));
    expect(taps, 1);
  });

  group('RewardBalanceCard (DD-48)', () {
    Widget card({
      VoidCallback? onTransfer,
      VoidCallback? onTap,
      bool transferring = false,
      List<(String, String)> figures = const <(String, String)>[],
    }) =>
        RewardBalanceCard(
          label: 'Invite rewards',
          amount: '៛5,160',
          caption: 'Not in your balance yet · 5 invited',
          transferLabel: 'Transfer to balance',
          onTransfer: onTransfer,
          onTap: onTap,
          transferring: transferring,
          figures: figures,
        );

    testWidgets('the amount in green, and it says the money is not usable yet',
        (WidgetTester t) async {
      await t.pumpWidget(_host(card(onTransfer: () {})));
      final BuildContext context = t.element(find.byType(RewardBalanceCard));

      expect(t.widget<Text>(find.text('៛5,160')).style!.color,
          context.colors.success);
      expect(find.text('Not in your balance yet · 5 invited'), findsOneWidget);
    });

    testWidgets('the button transfers; the rest of the card opens the screen',
        (WidgetTester t) async {
      int transfers = 0;
      int opens = 0;
      await t.pumpWidget(
          _host(card(onTransfer: () => transfers++, onTap: () => opens++)));

      await t.tap(find.text('Transfer to balance'));
      expect((transfers, opens), (1, 0));
      await t.tap(find.text('៛5,160'));
      expect((transfers, opens), (1, 1));
    });

    testWidgets('nothing to transfer: no button', (WidgetTester t) async {
      await t.pumpWidget(_host(card(onTransfer: null)));

      expect(find.text('Transfer to balance'), findsNothing);
    });

    testWidgets('a transfer in flight cannot be started again',
        (WidgetTester t) async {
      int transfers = 0;
      await t.pumpWidget(
          _host(card(onTransfer: () => transfers++, transferring: true)));

      await t.tap(find.byType(TButton), warnIfMissed: false);
      expect(transfers, 0);
    });

    testWidgets('figures under the button on the rewards screen',
        (WidgetTester t) async {
      await t.pumpWidget(_host(card(figures: const <(String, String)>[
        ('Total earned', '៛8,660'),
        ('Transferred to balance', '៛3,500'),
      ])));

      expect(find.text('៛8,660'), findsOneWidget);
      expect(find.text('Transferred to balance'), findsOneWidget);
    });
  });

  group('TransferAmountBody (DD-49)', () {
    Widget sheet({
      ValueChanged<num>? onConfirm,
      VoidCallback? onCancel,
      num available = 5160,
    }) =>
        TransferAmountBody(
          availableText: 'Reward balance: ៛5,160',
          amountLabel: 'Amount',
          symbol: '៛',
          allLabel: 'All',
          allValue: '$available',
          wholeUnits: true,
          parse: (String text) {
            final int? v = int.tryParse(text);
            return v == null || v <= 0 ? null : v;
          },
          errorFor: (num amount) =>
              amount > available ? 'You have ៛5,160 to transfer.' : null,
          linesFor: (num amount) => <String>[
            'Balance after: ${85400 + amount}',
            'Rewards left: ${available - amount}',
          ],
          confirmLabelFor: (num? amount) =>
              amount == null ? 'Transfer' : 'Transfer $amount',
          warning: 'This cannot be moved back.',
          cancelLabel: 'Cancel',
          onConfirm: onConfirm ?? (_) {},
          onCancel: onCancel ?? () {},
        );

    TButton confirmButton(WidgetTester t) => t
        .widgetList<TButton>(find.byType(TButton))
        .firstWhere((TButton b) => b.label.startsWith('Transfer'));

    testWidgets("starts empty with the button off: the amount is the driver's",
        (WidgetTester t) async {
      num? confirmed;
      await t.pumpWidget(_host(sheet(onConfirm: (num a) => confirmed = a)));

      expect(t.widget<TextField>(find.byType(TextField)).controller!.text, '');
      expect(confirmButton(t).onPressed, isNull);
      expect(find.text('This cannot be moved back.'), findsOneWidget);
      await t.tap(find.text('Transfer'), warnIfMissed: false);
      expect(confirmed, isNull);
    });

    testWidgets('a typed amount shows where it goes and confirms that amount',
        (WidgetTester t) async {
      num? confirmed;
      await t.pumpWidget(_host(sheet(onConfirm: (num a) => confirmed = a)));

      await t.enterText(find.byType(TextField), '2000');
      await t.pump();

      expect(find.text('Balance after: 87400'), findsOneWidget);
      expect(find.text('Rewards left: 3160'), findsOneWidget);
      await t.tap(find.text('Transfer 2000'));
      expect(confirmed, 2000);
    });

    testWidgets('"All" fills in the whole reward balance',
        (WidgetTester t) async {
      num? confirmed;
      await t.pumpWidget(_host(sheet(onConfirm: (num a) => confirmed = a)));

      await t.tap(find.text('All'));
      await t.pump();

      expect(
          t.widget<TextField>(find.byType(TextField)).controller!.text, '5160');
      expect(find.text('Rewards left: 0'), findsOneWidget);
      await t.tap(find.text('Transfer 5160'));
      expect(confirmed, 5160);
    });

    testWidgets('more than the balance: an error, and the button stays off',
        (WidgetTester t) async {
      num? confirmed;
      await t.pumpWidget(_host(sheet(onConfirm: (num a) => confirmed = a)));

      await t.enterText(find.byType(TextField), '9000');
      await t.pump();

      expect(find.text('You have ៛5,160 to transfer.'), findsOneWidget);
      expect(find.textContaining('Balance after'), findsNothing);
      expect(confirmButton(t).onPressed, isNull);
      await t.tap(find.text('Transfer'), warnIfMissed: false);
      expect(confirmed, isNull);
    });

    testWidgets('riel takes digits only', (WidgetTester t) async {
      await t.pumpWidget(_host(sheet()));

      await t.enterText(find.byType(TextField), '2,0a0.5');
      expect(
          t.widget<TextField>(find.byType(TextField)).controller!.text, '2005');
    });

    testWidgets('cancel leaves without an amount', (WidgetTester t) async {
      int cancels = 0;
      num? confirmed;
      await t.pumpWidget(_host(sheet(
        onConfirm: (num a) => confirmed = a,
        onCancel: () => cancels++,
      )));

      await t.tap(find.text('Cancel'));
      expect(cancels, 1);
      expect(confirmed, isNull);
    });
  });

  testWidgets('RewardSplitCard shows both shares', (WidgetTester t) async {
    await t.pumpWidget(
      _host(
        const RewardSplitCard(
          driversLabel: 'From drivers',
          driversAmount: '៛4,500',
          passengersLabel: 'From passengers',
          passengersAmount: '៛660',
        ),
      ),
    );

    expect(find.text('៛4,500'), findsOneWidget);
    expect(find.text('៛660'), findsOneWidget);
  });

  testWidgets('RewardTile: an em dash for a missing name',
      (WidgetTester t) async {
    await t.pumpWidget(
      _host(
        const RewardTile(
          name: null,
          caption: 'Trip · 08:14',
          amount: '+៛120',
          icon: DsIcons.users,
        ),
      ),
    );

    expect(find.text('—'), findsOneWidget);
    expect(find.text('+៛120'), findsOneWidget);
  });

  testWidgets('RewardTile: a transfer out is neutral, not green',
      (WidgetTester t) async {
    await t.pumpWidget(
      _host(
        const RewardTile(
          name: 'Transferred to balance',
          caption: '12:00',
          amount: '−៛5,160',
          icon: DsIcons.wallet,
          moneyIn: false,
        ),
      ),
    );
    final BuildContext context = t.element(find.byType(RewardTile));

    expect(t.widget<Text>(find.text('−៛5,160')).style!.color,
        context.colors.textPrimary);
  });

  testWidgets('InviteeTile greys out "no rewards yet"', (WidgetTester t) async {
    await t.pumpWidget(
      _host(
        const InviteeTile(
          name: 'Vuthy Nhem',
          caption: 'Passenger · Joined 30 Sep',
          earned: 'No rewards yet',
          hasEarned: false,
        ),
      ),
    );
    final BuildContext context = t.element(find.byType(InviteeTile));

    expect(t.widget<Text>(find.text('No rewards yet')).style!.color,
        context.colors.textSecondary);
  });

  group('InviteCodeField', () {
    Widget field(
      InviteCodeStatus status, {
      TextEditingController? controller,
      ValueChanged<String>? onChanged,
      VoidCallback? onScan,
    }) =>
        InviteCodeField(
          controller: controller ?? TextEditingController(),
          status: status,
          label: 'Invite code (optional)',
          hint: 'Type or scan a code',
          scanLabel: 'Scan invite QR',
          note: 'Only at sign-up.',
          appliedText: 'Invited by Sokha Vann',
          errorText: 'Code not recognised.',
          onChanged: onChanged ?? (_) {},
          onScan: onScan ?? () {},
        );

    testWidgets('idle: the note, and a scan button', (WidgetTester t) async {
      int scans = 0;
      await t.pumpWidget(
          _host(field(InviteCodeStatus.idle, onScan: () => scans++)));

      expect(find.text('Only at sign-up.'), findsOneWidget);
      await t.tap(find.bySemanticsLabel('Scan invite QR'));
      expect(scans, 1);
    });

    testWidgets('typing is upper-cased and limited to letters and digits',
        (WidgetTester t) async {
      final TextEditingController controller = TextEditingController();
      await t.pumpWidget(
          _host(field(InviteCodeStatus.idle, controller: controller)));

      await t.enterText(find.byType(TextField), 'sokha-88 ');
      expect(controller.text, 'SOKHA88');
    });

    testWidgets('checking: a spinner replaces the scan button',
        (WidgetTester t) async {
      await t.pumpWidget(_host(field(InviteCodeStatus.checking)));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Scan invite QR'), findsNothing);
    });

    testWidgets('valid: who invited them', (WidgetTester t) async {
      await t.pumpWidget(_host(field(InviteCodeStatus.valid)));

      expect(find.text('Invited by Sokha Vann'), findsOneWidget);
      expect(find.text('Only at sign-up.'), findsNothing);
      expect(find.text('Code not recognised.'), findsNothing);
    });

    testWidgets('invalid: the error, not the note', (WidgetTester t) async {
      await t.pumpWidget(_host(field(InviteCodeStatus.invalid)));

      expect(find.text('Code not recognised.'), findsOneWidget);
      expect(find.text('Only at sign-up.'), findsNothing);
      expect(find.text('Invited by Sokha Vann'), findsNothing);
    });
  });
}
