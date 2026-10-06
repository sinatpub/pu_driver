import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pu_taxi_driver/app/state.dart';
import 'package:pu_taxi_driver/core/theme/app_theme.dart';
import 'package:pu_taxi_driver/presentation/screens/drawer/widgets/approval_gate.dart';
import 'package:pu_taxi_driver/presentation/screens/drawer/widgets/online_status_pill.dart';

/// UX-redesign C1 — the shell's two state-driven controls.
///
/// These exercise the **views**, which take their copy and callbacks as
/// parameters. The connected wrappers (`ApprovalGate`, `OnlineStatusPill`) are
/// not pumped here: they resolve `AppLogic` through GetX and call `.tr()`, so
/// they need an app-level setup. Their wiring — the fail-closed gate and the
/// online-only guard — is verified on a device per the roadmap's C1 step.
Widget _host(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(khmer: false),
    home: Scaffold(body: Stack(children: <Widget>[child])),
  );
}

void main() {
  group('ApprovalGateView', () {
    const List<ApprovalStep> steps = <ApprovalStep>[
      ApprovalStep('Documents sent', ApprovalStepState.done),
      ApprovalStep('Under review', ApprovalStepState.current),
      ApprovalStep('Ready to drive', ApprovalStepState.upcoming),
    ];

    testWidgets('waiting shows what happens next, and both ways out',
        (WidgetTester t) async {
      await t.pumpWidget(
        _host(
          const Positioned.fill(
            child: ApprovalGateView(
              status: DriverApprovalStatus.pending,
              title: 'Waiting approval from admin',
              message: 'Your account is pending admin approval.',
              steps: steps,
              supportLabel: 'Contact support',
              checkAgainLabel: 'Check again',
            ),
          ),
        ),
      );

      expect(find.text('Waiting approval from admin'), findsOneWidget);
      expect(find.text('Documents sent'), findsOneWidget);
      expect(find.text('Under review'), findsOneWidget);
      expect(find.text('Ready to drive'), findsOneWidget);
      expect(find.text('Contact support'), findsOneWidget);
      expect(find.text('Check again'), findsOneWidget);
      // Waiting is a verdict, not a check in flight: nothing spins.
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('rejected reads differently, and lists no steps',
        (WidgetTester t) async {
      await t.pumpWidget(
        _host(
          const Positioned.fill(
            child: ApprovalGateView(
              status: DriverApprovalStatus.rejected,
              title: 'Application not approved',
              message: 'Please re-submit your documents.',
              supportLabel: 'Contact support',
              checkAgainLabel: 'Check again',
            ),
          ),
        ),
      );

      // The rejected driver is never told to wait — that was the old bug.
      expect(find.text('Application not approved'), findsOneWidget);
      expect(find.textContaining('Waiting'), findsNothing);
      expect(find.text('Under review'), findsNothing);
      expect(find.text('Contact support'), findsOneWidget);
    });

    testWidgets('it is a page of its own: the home behind does not show',
        (WidgetTester t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(khmer: false),
          home: const Scaffold(
            body: Stack(
              children: <Widget>[
                Center(child: Text('the map')),
                Positioned.fill(
                  child: ApprovalGateView(
                    status: DriverApprovalStatus.pending,
                    title: 'Waiting approval from admin',
                    message: 'Your account is pending admin approval.',
                    supportLabel: 'Contact support',
                    checkAgainLabel: 'Check again',
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final ColoredBox page = t.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(ApprovalGateView),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(page.color.a, 1.0);
    });

    testWidgets('both buttons fire, and "check again" spins while it runs',
        (WidgetTester t) async {
      int support = 0;
      int checks = 0;
      Widget page({required bool checking}) => _host(
            Positioned.fill(
              child: ApprovalGateView(
                status: DriverApprovalStatus.pending,
                title: 'Waiting approval from admin',
                message: 'Your account is pending admin approval.',
                supportLabel: 'Contact support',
                onSupport: () => support++,
                checkAgainLabel: 'Check again',
                onCheckAgain: () => checks++,
                checking: checking,
              ),
            ),
          );

      await t.pumpWidget(page(checking: false));
      await t.tap(find.text('Contact support'));
      await t.tap(find.text('Check again'));
      expect(support, 1);
      expect(checks, 1);

      await t.pumpWidget(page(checking: true));
      await t.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('OnlineStatusPillView', () {
    testWidgets('shows the state it is given and reports taps',
        (WidgetTester t) async {
      int taps = 0;
      await t.pumpWidget(
        _host(
          OnlineStatusPillView(
            isOnline: false,
            label: 'Offline',
            onTap: () => taps++,
          ),
        ),
      );

      expect(find.text('Offline'), findsOneWidget);
      await t.tap(find.byType(OnlineStatusPillView));
      expect(taps, 1);

      await t.pumpWidget(
        _host(
          OnlineStatusPillView(
            isOnline: true,
            label: 'Online',
            onTap: () {},
          ),
        ),
      );
      expect(find.text('Online'), findsOneWidget);
    });

    testWidgets('clears the touch-target floor', (WidgetTester t) async {
      await t.pumpWidget(
        _host(
          OnlineStatusPillView(
            isOnline: true,
            label: 'Online',
            onTap: () {},
          ),
        ),
      );

      expect(
        t.getSize(find.byType(OnlineStatusPillView)).height,
        greaterThanOrEqualTo(48),
      );
    });
  });
}
