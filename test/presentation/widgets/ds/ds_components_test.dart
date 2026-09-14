import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/core/theme/app_theme.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

/// UX-redesign F2 — state coverage for the shared components.
///
/// The point of each test is a rule the design system makes, not a pixel:
/// disabled means not tappable, loading does not resize a button, an unknown
/// amount shows an em dash rather than zero, and every tap target clears
/// 48 px.
Widget _host(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(khmer: false),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('TButton', () {
    testWidgets('renders its label and reports taps', (WidgetTester t) async {
      int taps = 0;
      await t.pumpWidget(
        _host(TButton(label: 'Accept', onPressed: () => taps++)),
      );

      expect(find.text('Accept'), findsOneWidget);
      await t.tap(find.byType(TButton));
      expect(taps, 1);
    });

    testWidgets('a null callback disables it', (WidgetTester t) async {
      await t.pumpWidget(
        _host(const TButton(label: 'Accept', onPressed: null)),
      );

      // Nothing to assert but the absence of a crash on tap; the button must
      // simply ignore it.
      await t.tap(find.byType(TButton));
      await t.pump();
      expect(find.text('Accept'), findsOneWidget);
    });

    testWidgets('loading shows a spinner and swallows taps',
        (WidgetTester t) async {
      int taps = 0;
      await t.pumpWidget(
        _host(TButton(label: 'Accept', loading: true, onPressed: () => taps++)),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await t.tap(find.byType(TButton));
      expect(taps, 0, reason: 'an in-flight action must not fire twice');
    });

    testWidgets('loading keeps the button the same width',
        (WidgetTester t) async {
      await t.pumpWidget(
        _host(
          SizedBox(
            width: 300,
            child: TButton(
              label: 'Payment done',
              expand: false,
              onPressed: () {},
            ),
          ),
        ),
      );
      final double idle = t.getSize(find.byType(TButton)).width;

      await t.pumpWidget(
        _host(
          SizedBox(
            width: 300,
            child: TButton(
              label: 'Payment done',
              expand: false,
              loading: true,
              onPressed: () {},
            ),
          ),
        ),
      );
      final double loading = t.getSize(find.byType(TButton)).width;

      expect(loading, idle);
    });

    testWidgets('every variant renders', (WidgetTester t) async {
      for (final TButtonVariant v in TButtonVariant.values) {
        await t.pumpWidget(
          _host(TButton(label: v.name, variant: v, onPressed: () {})),
        );
        expect(find.text(v.name), findsOneWidget);
      }
    });

    testWidgets('regular is 56 tall and small clears the touch target',
        (WidgetTester t) async {
      await t.pumpWidget(_host(TButton(label: 'A', onPressed: () {})));
      expect(t.getSize(find.byType(TButton)).height,
          greaterThanOrEqualTo(Sizes.primaryButton));

      await t.pumpWidget(
        _host(
          TButton(
            label: 'A',
            size: TButtonSize.small,
            onPressed: () {},
          ),
        ),
      );
      expect(t.getSize(find.byType(TButton)).height,
          greaterThanOrEqualTo(Sizes.touchTarget));
    });
  });

  group('TIconButton', () {
    testWidgets('is at least 48x48', (WidgetTester t) async {
      await t.pumpWidget(
        _host(
          TIconButton(
            icon: DsIcons.menu,
            semanticLabel: 'Menu',
            onPressed: () {},
          ),
        ),
      );
      final Size size = t.getSize(find.byType(TIconButton));
      expect(size.width, greaterThanOrEqualTo(Sizes.touchTarget));
      expect(size.height, greaterThanOrEqualTo(Sizes.touchTarget));
    });
  });

  group('TTextField', () {
    testWidgets('shows label, hint and error', (WidgetTester t) async {
      await t.pumpWidget(
        _host(
          const TTextField(
            label: 'Phone number',
            hint: 'Enter phone number',
            errorText: 'Please check your phone number',
          ),
        ),
      );

      expect(find.text('Phone number'), findsOneWidget);
      expect(find.text('Enter phone number'), findsOneWidget);
      expect(find.text('Please check your phone number'), findsOneWidget);
    });

    testWidgets('the phone variant shows the +855 prefix',
        (WidgetTester t) async {
      await t.pumpWidget(_host(TTextField.phone(label: 'Phone')));
      expect(find.text('+855'), findsOneWidget);
    });
  });

  group('TBadge', () {
    testWidgets('every tone renders its label', (WidgetTester t) async {
      for (final TBadgeTone tone in TBadgeTone.values) {
        await t.pumpWidget(_host(TBadge(label: tone.name, tone: tone)));
        expect(find.text(tone.name), findsOneWidget);
      }
    });
  });

  group('TChip and TTabs', () {
    testWidgets('a chip reports taps and clears the touch target',
        (WidgetTester t) async {
      int taps = 0;
      await t.pumpWidget(
        _host(TChip(label: 'All', selected: false, onTap: () => taps++)),
      );

      expect(t.getSize(find.byType(TChip)).height,
          greaterThanOrEqualTo(Sizes.touchTarget));
      await t.tap(find.byType(TChip));
      expect(taps, 1);
    });

    testWidgets('tabs report the tapped index', (WidgetTester t) async {
      int? picked;
      await t.pumpWidget(
        _host(
          TTabs(
            labels: const <String>['Completed', 'Cancelled'],
            index: 0,
            onChanged: (int i) => picked = i,
          ),
        ),
      );

      await t.tap(find.text('Cancelled'));
      expect(picked, 1);
    });
  });

  group('TAvatar', () {
    testWidgets('falls back to initials when there is no photo',
        (WidgetTester t) async {
      await t.pumpWidget(_host(const TAvatar(name: 'Sok Dara')));
      expect(find.text('SD'), findsOneWidget);
    });

    testWidgets('handles a single-word name', (WidgetTester t) async {
      await t.pumpWidget(_host(const TAvatar(name: 'Dara')));
      expect(find.text('D'), findsOneWidget);
    });
  });

  group('TKeyValueRow', () {
    testWidgets('an unknown value is an em dash, never zero',
        (WidgetTester t) async {
      await t.pumpWidget(
        _host(const TKeyValueRow(label: 'Distance', value: null)),
      );
      expect(find.text('—'), findsOneWidget);
    });
  });

  group('TAmount', () {
    testWidgets('marks an estimate and renders unknown as an em dash',
        (WidgetTester t) async {
      await t.pumpWidget(
        _host(const TAmount(text: '៛8,300', isEstimate: true)),
      );
      expect(find.text('≈ ៛8,300'), findsOneWidget);

      await t.pumpWidget(_host(const TAmount(text: null)));
      expect(find.text('—'), findsOneWidget);
    });
  });

  group('TAddressRow', () {
    testWidgets('shows a placeholder while the address is geocoding',
        (WidgetTester t) async {
      await t.pumpWidget(
        _host(
          const TAddressRow(
            kind: TAddressKind.pickup,
            overline: 'Pickup',
            primary: '',
            loading: true,
          ),
        ),
      );
      expect(find.text('Pickup'), findsOneWidget);
    });
  });
}
