import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/core/theme/app_theme.dart';
import 'package:tara_driver_application/presentation/screens/home/state.dart';
import 'package:tara_driver_application/presentation/screens/home/widgets/driver_status_card.dart';
import 'package:tara_driver_application/presentation/screens/home/widgets/location_state_view.dart';

/// UX-redesign C2 — the home tab's two state-driven overlays.
///
/// Views only: the connected `DriverStatusCard` resolves `AppLogic` and calls
/// `.tr()`, so it needs an app-level setup. The map itself is not pumped —
/// `GoogleMap` needs a platform view.
Widget _host(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(khmer: false),
    home: Scaffold(body: child),
  );
}

void main() {
  group('DriverStatusCardView', () {
    testWidgets('says whether requests are coming', (WidgetTester t) async {
      await t.pumpWidget(
        _host(
          const DriverStatusCardView(
            isOnline: true,
            title: "You're online",
            message: 'Receiving requests',
            badgeLabel: 'Online',
          ),
        ),
      );

      expect(find.text("You're online"), findsOneWidget);
      expect(find.text('Receiving requests'), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);
    });

    testWidgets('offline tells the driver what to do about it',
        (WidgetTester t) async {
      await t.pumpWidget(
        _host(
          const DriverStatusCardView(
            isOnline: false,
            title: "You're offline",
            message: 'Go online to receive requests',
            badgeLabel: 'Offline',
          ),
        ),
      );

      expect(find.text('Go online to receive requests'), findsOneWidget);
    });

    testWidgets('carries no money figure', (WidgetTester t) async {
      // DD-07: there is no earnings endpoint, so the prototype's earnings card
      // is not built. Guards against someone "restoring" it with a guess.
      await t.pumpWidget(
        _host(
          const DriverStatusCardView(
            isOnline: true,
            title: "You're online",
            message: 'Receiving requests',
            badgeLabel: 'Online',
          ),
        ),
      );

      expect(find.textContaining('៛'), findsNothing);
    });
  });

  group('LocationStateView', () {
    const Map<String, String> copy = <String, String>{
      'searching': 'Finding your location…',
      'deniedTitle': 'Location permission is off',
      'deniedMessage': 'Taarraa needs your location.',
      'failedTitle': "Couldn't get your location",
      'openSettings': 'Open settings',
    };

    Widget view(LocationLoadStatus status, {VoidCallback? onOpenSettings}) {
      return LocationStateView(
        status: status,
        searchingLabel: copy['searching']!,
        deniedTitle: copy['deniedTitle']!,
        deniedMessage: copy['deniedMessage']!,
        failedTitle: copy['failedTitle']!,
        openSettingsLabel: copy['openSettings']!,
        errorText: 'PlatformException(42)',
        onOpenSettings: onOpenSettings,
      );
    }

    testWidgets('searching shows progress, not an error',
        (WidgetTester t) async {
      await t.pumpWidget(_host(view(LocationLoadStatus.inProgress)));

      expect(find.text('Finding your location…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Open settings'), findsNothing);
    });

    testWidgets('permission denied offers a way out', (WidgetTester t) async {
      int opened = 0;
      await t.pumpWidget(
        _host(
          view(
            LocationLoadStatus.permissionDenied,
            onOpenSettings: () => opened++,
          ),
        ),
      );

      expect(find.text('Location permission is off'), findsOneWidget);
      // The old screen showed this state with no action at all.
      await t.tap(find.text('Open settings'));
      expect(opened, 1);
    });

    testWidgets('failure surfaces the underlying error',
        (WidgetTester t) async {
      await t.pumpWidget(
        _host(view(LocationLoadStatus.failure, onOpenSettings: () {})),
      );

      expect(find.text("Couldn't get your location"), findsOneWidget);
      expect(find.text('PlatformException(42)'), findsOneWidget);
    });

    testWidgets('success renders nothing — the caller draws the map',
        (WidgetTester t) async {
      await t.pumpWidget(_host(view(LocationLoadStatus.success)));

      expect(find.text('Finding your location…'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
