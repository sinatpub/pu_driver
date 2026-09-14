import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/app/state.dart';
import 'package:tara_driver_application/core/theme/app_theme.dart';
import 'package:tara_driver_application/presentation/screens/drawer/widgets/approval_gate.dart';
import 'package:tara_driver_application/presentation/screens/drawer/widgets/online_status_pill.dart';

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
    testWidgets('unknown is shown as still checking, not as a verdict',
        (WidgetTester t) async {
      await t.pumpWidget(
        _host(
          const ApprovalGateView(
            status: DriverApprovalStatus.unknown,
            title: 'Checking your account…',
            message: 'We are confirming your approval status.',
            actionLabel: 'Please try again',
          ),
        ),
      );

      expect(find.text('Checking your account…'), findsOneWidget);
      // A spinner, not a clock or a cross: the answer has not arrived yet.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('pending and rejected read differently',
        (WidgetTester t) async {
      await t.pumpWidget(
        _host(
          const ApprovalGateView(
            status: DriverApprovalStatus.pending,
            title: 'Waiting approval from admin',
            message: 'Your account is pending admin approval.',
            actionLabel: 'Contact support',
          ),
        ),
      );
      expect(find.text('Waiting approval from admin'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await t.pumpWidget(
        _host(
          const ApprovalGateView(
            status: DriverApprovalStatus.rejected,
            title: 'Application not approved',
            message: 'Please re-submit your documents.',
            actionLabel: 'Contact support',
          ),
        ),
      );
      // The rejected driver is never told to wait — that was the old bug.
      expect(find.text('Application not approved'), findsOneWidget);
      expect(find.textContaining('Waiting'), findsNothing);
    });

    testWidgets('the action fires', (WidgetTester t) async {
      int taps = 0;
      await t.pumpWidget(
        _host(
          ApprovalGateView(
            status: DriverApprovalStatus.unknown,
            title: 'Checking your account…',
            message: 'We are confirming your approval status.',
            actionLabel: 'Please try again',
            onAction: () => taps++,
          ),
        ),
      );

      await t.tap(find.text('Please try again'));
      expect(taps, 1);
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
