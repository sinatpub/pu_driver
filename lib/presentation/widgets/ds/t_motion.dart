import 'package:flutter/material.dart';

/// UX-redesign P1 — the motion spec (`02 §15`, `05` "Motion") in one place.
///
/// Rules every animation in the app follows:
/// - transitions finish within 300 ms; only the map camera and genuine
///   progress indicators (the request countdown, an auto-dismiss bar, a
///   spinner, a pulse) run longer;
/// - when the OS asks for reduced motion ([reduceMotion]): no pulse, no slide,
///   no scale, no shake — opacity changes only;
/// - money values never animate.
class Motion {
  const Motion._();

  /// Route enter: fade + 10 px rise.
  static const Duration screen = Duration(milliseconds: 250);
  static const double screenRise = 10;

  /// Modal sheet in.
  static const Duration sheet = Duration(milliseconds: 300);
  static const Curve sheetCurve = Cubic(0.2, 0.9, 0.3, 1);

  /// Dialog in: scale .9 → 1.
  static const Duration dialog = Duration(milliseconds: 250);
  static const double dialogScaleFrom = 0.9;

  /// Trip stage content cross-fade.
  static const Duration stageChange = Duration(milliseconds: 150);

  /// Timeline step fill.
  static const Duration timelineStep = Duration(milliseconds: 200);

  /// Banner slide down.
  static const Duration banner = Duration(milliseconds: 200);

  /// Button press scale .97.
  static const Duration press = Duration(milliseconds: 100);

  /// Colour cross-fades on selectable controls (chips, segments, the pill).
  static const Duration colorChange = Duration(milliseconds: 150);

  /// Live pulses (opacity 1 ↔ .4).
  static const Duration pulseOnline = Duration(milliseconds: 1400);
  static const Duration pulseStage = Duration(milliseconds: 1200);

  /// Error shake.
  static const Duration shake = Duration(milliseconds: 400);
}

/// True when the platform asks for reduced motion.
bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// A dot that pulses its opacity while [active] — the online pill and the
/// trip stage pill (`02 §13`). Static under reduced motion.
class TPulseDot extends StatefulWidget {
  const TPulseDot({
    super.key,
    required this.color,
    this.size = 9,
    this.period = Motion.pulseStage,
    this.active = true,
  });

  final Color color;
  final double size;
  final Duration period;
  final bool active;

  @override
  State<TPulseDot> createState() => _TPulseDotState();
}

class _TPulseDotState extends State<TPulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period ~/ 2,
  );

  void _sync(bool animate) {
    if (animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!animate && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync(widget.active && !reduceMotion(context));
  }

  @override
  void didUpdateWidget(TPulseDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period) {
      _controller.duration = widget.period ~/ 2;
    }
    _sync(widget.active && !reduceMotion(context));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.4).animate(_controller),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

/// Scales its child in from .9 once, on first build — the dialog entrance.
/// Rebuilds keep the end state. No scale under reduced motion (the route's
/// own fade still plays).
class TScaleIn extends StatelessWidget {
  const TScaleIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: Motion.dialogScaleFrom, end: 1),
      duration: Motion.dialog,
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double scale, Widget? child) =>
          Transform.scale(scale: scale, child: child),
      child: child,
    );
  }
}

/// Cross-fades [child] when [stateKey] changes (`Motion.stageChange`).
///
/// The outgoing child is wrapped in [IgnorePointer]: during the fade the old
/// stage's content must not take a tap. Instant under reduced motion.
class TCrossFade extends StatelessWidget {
  const TCrossFade({super.key, required this.stateKey, required this.child});

  final Object stateKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: reduceMotion(context) ? Duration.zero : Motion.stageChange,
      layoutBuilder: (Widget? current, List<Widget> previous) => Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          for (final Widget p in previous) IgnorePointer(child: p),
          if (current != null) current,
        ],
      ),
      child: KeyedSubtree(key: ValueKey<Object>(stateKey), child: child),
    );
  }
}
