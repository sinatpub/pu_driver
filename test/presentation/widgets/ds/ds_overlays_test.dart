import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/core/theme/app_theme.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

/// UX-redesign F3 — the overlay layer.
///
/// Scope note: these cover the **widgets**. The `show…Dialog` *functions* are
/// not exercised here because they call `.tr()` and `Get`, which need
/// app-level localisation and GetX setup; their dismissal and navigation
/// semantics are verified on a device against the F1 baseline, per the
/// roadmap's F3 verification step. That is also where the two behaviours most
/// worth watching live: the error dialog's double pop (`DD-33`) and the
/// passenger-cancel dialog's 10 s timer (`DD-25`).
Widget _host(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(khmer: false),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('TDialog', () {
    testWidgets('renders title, message and actions', (WidgetTester t) async {
      int taps = 0;
      await t.pumpWidget(
        _host(
          TDialog(
            title: 'Cancel request?',
            message: 'The passenger is waiting.',
            actions: <Widget>[
              TButton(
                label: 'Stay',
                size: TButtonSize.small,
                onPressed: () => taps++,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Cancel request?'), findsOneWidget);
      expect(find.text('The passenger is waiting.'), findsOneWidget);

      await t.tap(find.text('Stay'));
      expect(taps, 1);
    });

    testWidgets('renders without a message or actions', (WidgetTester t) async {
      await t.pumpWidget(_host(const TDialog(title: 'Resuming your trip…')));
      expect(find.text('Resuming your trip…'), findsOneWidget);
    });
  });

  group('TAutoDismissBar', () {
    testWidgets('drains over its duration and never calls back',
        (WidgetTester t) async {
      await t.pumpWidget(
        _host(
          const SizedBox(
            width: 200,
            child: TAutoDismissBar(duration: Duration(seconds: 10)),
          ),
        ),
      );

      double valueOf() => t
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value!;

      expect(valueOf(), closeTo(1.0, 0.01));
      await t.pump(const Duration(seconds: 5));
      expect(valueOf(), lessThan(0.9));

      // Let it finish; the point is that nothing else happens when it does.
      await t.pump(const Duration(seconds: 6));
      expect(find.byType(TAutoDismissBar), findsOneWidget);
    });
  });

  group('TBanner', () {
    testWidgets('states the message', (WidgetTester t) async {
      await t.pumpWidget(
        _host(const TBanner(message: 'No internet — reconnecting…')),
      );
      expect(find.text('No internet — reconnecting…'), findsOneWidget);
    });
  });

  group('state views', () {
    testWidgets('empty state shows its action only when wired',
        (WidgetTester t) async {
      await t.pumpWidget(
        _host(const TEmptyState(title: 'No completed trips yet')),
      );
      expect(find.text('No completed trips yet'), findsOneWidget);
      expect(find.byType(TButton), findsNothing);

      int retried = 0;
      await t.pumpWidget(
        _host(
          TEmptyState(
            title: 'No completed trips yet',
            actionLabel: 'Refresh',
            onAction: () => retried++,
          ),
        ),
      );
      await t.tap(find.text('Refresh'));
      expect(retried, 1);
    });

    testWidgets('error state offers a retry', (WidgetTester t) async {
      int retried = 0;
      await t.pumpWidget(
        _host(
          TErrorState(
            title: 'Something went wrong',
            message: 'Please try again.',
            actionLabel: 'Try again',
            onAction: () => retried++,
          ),
        ),
      );

      expect(find.text('Please try again.'), findsOneWidget);
      await t.tap(find.text('Try again'));
      expect(retried, 1);
    });
  });

  group('TSheet', () {
    testWidgets('shows its title and content', (WidgetTester t) async {
      await t.pumpWidget(
        _host(
          const TSheet(title: 'Withdraw', child: Text('body')),
        ),
      );
      expect(find.text('Withdraw'), findsOneWidget);
      expect(find.text('body'), findsOneWidget);
    });
  });
}
