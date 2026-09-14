import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/core/theme/app_theme.dart';
import 'package:tara_driver_application/presentation/widgets/count_down_widget.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';
import 'package:tara_driver_application/presentation/widgets/ds/t_motion.dart';
import 'package:tara_driver_application/presentation/widgets/shake_widget.dart';
import 'package:tara_driver_application/routes/transitions.dart';

import '../../../helpers/localized_host.dart';

/// UX-redesign P1 — the motion spec (`02 §15`) and reduced motion.
Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.light(khmer: false),
      home: Scaffold(body: Center(child: child)),
    );

void _reduceMotion(WidgetTester t) {
  t.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

double _opacity(WidgetTester t) => t
    .widget<FadeTransition>(
      find.descendant(
        of: find.byType(TPulseDot),
        matching: find.byType(FadeTransition),
      ),
    )
    .opacity
    .value;

void main() {
  test('transitions stay within 300 ms (done-when)', () {
    for (final Duration d in <Duration>[
      Motion.screen,
      Motion.sheet,
      Motion.dialog,
      Motion.stageChange,
      Motion.timelineStep,
      Motion.banner,
      Motion.press,
      Motion.colorChange,
    ]) {
      expect(d.inMilliseconds, lessThanOrEqualTo(300));
    }
  });

  group('request countdown (defect fixed in P1)', () {
    testWidgets('keeps real time under reduced motion', (WidgetTester t) async {
      _reduceMotion(t);
      await t.pumpWidget(
        localizedHost(
          const SmoothCircularCountdown(countDuration: 10, isPop: false),
        ),
      );
      // The ticker starts on the frame after mount.
      await t.pump();
      await t.pump(const Duration(milliseconds: 2500));
      // With AnimationBehavior.normal the controller runs at 5% of its
      // duration here — 10 s becomes 0.5 s — and would already read 0: the
      // request would have expired.
      expect(find.text('7'), findsOneWidget);
      await t.pump(const Duration(seconds: 8));
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('counts normally with animations on', (WidgetTester t) async {
      await t.pumpWidget(
        localizedHost(
          const SmoothCircularCountdown(countDuration: 10, isPop: false),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 2500));
      expect(find.text('7'), findsOneWidget);
    });
  });

  group('TPulseDot', () {
    testWidgets('pulses when active', (WidgetTester t) async {
      await t.pumpWidget(_host(const TPulseDot(color: Colors.green)));
      await t.pump(const Duration(milliseconds: 300));
      expect(_opacity(t), lessThan(1));
    });

    testWidgets('is still when inactive', (WidgetTester t) async {
      await t.pumpWidget(
        _host(const TPulseDot(color: Colors.green, active: false)),
      );
      await t.pump(const Duration(milliseconds: 300));
      expect(_opacity(t), 1);
    });

    testWidgets('is still under reduced motion', (WidgetTester t) async {
      _reduceMotion(t);
      await t.pumpWidget(_host(const TPulseDot(color: Colors.green)));
      await t.pump(const Duration(milliseconds: 300));
      expect(_opacity(t), 1);
    });
  });

  group('TCrossFade', () {
    Widget stage(String key, VoidCallback onTap) => _host(
          TCrossFade(
            stateKey: key,
            child: TextButton(onPressed: onTap, child: Text(key)),
          ),
        );

    testWidgets('the outgoing stage cannot be tapped during the fade',
        (WidgetTester t) async {
      int oldTaps = 0;
      await t.pumpWidget(stage('A', () => oldTaps++));
      await t.pumpWidget(stage('B', () {}));
      await t.pump(const Duration(milliseconds: 50));

      expect(find.text('A'), findsOneWidget); // still fading out
      await t.tap(find.text('A'), warnIfMissed: false);
      expect(oldTaps, 0);

      await t.pump(Motion.stageChange);
      expect(find.text('A'), findsNothing);
    });

    testWidgets('same key does not animate a value change',
        (WidgetTester t) async {
      Widget meter(String fare) =>
          _host(TCrossFade(stateKey: 3, child: Text(fare)));
      await t.pumpWidget(meter('≈ ៛7,600'));
      await t.pumpWidget(meter('≈ ៛8,000'));
      // No cross-fade: the old figure is gone on the very next frame.
      expect(find.text('≈ ៛7,600'), findsNothing);
      expect(find.text('≈ ៛8,000'), findsOneWidget);
    });
  });

  testWidgets('ShakeWidget does not shake under reduced motion',
      (WidgetTester t) async {
    _reduceMotion(t);
    final GlobalKey<ShakeWidgetState> key = GlobalKey<ShakeWidgetState>();
    await t.pumpWidget(
      _host(ShakeWidget(key: key, shakeOffset: 10, child: const Text('x'))),
    );
    key.currentState!.shake();
    expect(key.currentState!.animationController.isAnimating, isFalse);
  });

  group('TScaleIn', () {
    testWidgets('scales in from .9', (WidgetTester t) async {
      await t.pumpWidget(_host(const TScaleIn(child: Text('d'))));
      final Transform first = t.widget<Transform>(
        find.ancestor(of: find.text('d'), matching: find.byType(Transform)),
      );
      expect(first.transform.storage[0], closeTo(0.9, 0.01));
      await t.pumpAndSettle();
      final Transform last = t.widget<Transform>(
        find.ancestor(of: find.text('d'), matching: find.byType(Transform)),
      );
      expect(last.transform.storage[0], 1);
    });

    testWidgets('does not scale under reduced motion', (WidgetTester t) async {
      _reduceMotion(t);
      await t.pumpWidget(_host(const TScaleIn(child: Text('d'))));
      expect(
        find.ancestor(of: find.text('d'), matching: find.byType(Transform)),
        findsNothing,
      );
    });
  });

  test('fade + rise on Android; iOS keeps the platform slide and swipe-back',
      () {
    expect(
        appRouteTransition(TargetPlatform.android), isA<FadeRiseTransition>());
    expect(appRouteTransition(TargetPlatform.iOS), isNull);
  });
}
