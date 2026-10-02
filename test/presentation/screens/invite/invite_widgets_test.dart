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

  testWidgets('InviteEarnedCard: the amount in green, and it opens on tap',
      (WidgetTester t) async {
    int taps = 0;
    await t.pumpWidget(
      _host(
        InviteEarnedCard(
          label: 'Invite rewards earned',
          amount: '៛5,160',
          caption: 'Already in your balance · 5 invited',
          onTap: () => taps++,
        ),
      ),
    );
    final BuildContext context = t.element(find.byType(InviteEarnedCard));

    expect(t.widget<Text>(find.text('៛5,160')).style!.color,
        context.colors.success);
    // Says the money is not on top of the balance.
    expect(find.text('Already in your balance · 5 invited'), findsOneWidget);
    await t.tap(find.text('៛5,160'));
    expect(taps, 1);
  });

  testWidgets('RewardSplitCard shows both shares and where rewards are paid',
      (WidgetTester t) async {
    await t.pumpWidget(
      _host(
        const RewardSplitCard(
          driversLabel: 'From drivers',
          driversAmount: '៛4,500',
          passengersLabel: 'From passengers',
          passengersAmount: '៛660',
          note: 'Rewards are paid into your wallet balance.',
        ),
      ),
    );

    expect(find.text('៛4,500'), findsOneWidget);
    expect(find.text('៛660'), findsOneWidget);
    expect(find.text('Rewards are paid into your wallet balance.'),
        findsOneWidget);
  });

  testWidgets('RewardTile: an em dash for a missing name',
      (WidgetTester t) async {
    await t.pumpWidget(
      _host(
        const RewardTile(
          name: null,
          caption: 'Trip · 08:14',
          amount: '+៛120',
          fromDriver: false,
        ),
      ),
    );

    expect(find.text('—'), findsOneWidget);
    expect(find.text('+៛120'), findsOneWidget);
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
