import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/routes/app_routes.dart';

/// How long the driver has to decide on a ride request.
///
/// UX-redesign C3 replaced `build` and nothing else. The timer, the expiry
/// behaviour and the navigation are untouched (`DD-16`):
///
/// - the duration still comes from the request payload;
/// - when the controller reaches the end it still calls
///   `Get.offAllNamed('/home')`, silently;
/// - no tick sound — the prototype's is new behaviour, not a restyle.
///
/// P1 fixed one defect here: the timer ran 20× fast under the OS reduced-motion
/// setting (see `initState`).
///
/// Known and unchanged: the countdown starts when this widget mounts rather
/// than when the server issued the request, and it keeps running while an
/// Accept is in flight (B3).
class SmoothCircularCountdown extends StatefulWidget {
  final int countDuration;
  final bool isPop;

  const SmoothCircularCountdown(
      {super.key, required this.countDuration, required this.isPop});

  @override
  // ignore: library_private_types_in_public_api
  _SmoothCircularCountdownState createState() =>
      _SmoothCircularCountdownState();
}

class _SmoothCircularCountdownState extends State<SmoothCircularCountdown>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // P1: this controller *is* the request timer — its dismissal sends the
      // driver home. With the default `AnimationBehavior.normal`, Flutter
      // runs it at 5% of its duration when the OS asks for reduced motion
      // (`animation_controller.dart`, `disableAnimations` → 0.05), so a 30 s
      // request expired in 1.5 s on those devices. `preserve` keeps real time.
      animationBehavior: AnimationBehavior.preserve,
      duration: Duration(
        seconds: widget.countDuration,
      ), // Countdown duration
    );
    _controller.addListener(() {
      if (_controller.isDismissed && widget.isPop) {
        Get.offAllNamed(
            AppRoutes.home); // Pop the screen when countdown finishes
      }
    });
    _controller.reverse(from: 1.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Whole seconds remaining.
  int get _secondsLeft => (_controller.duration! * _controller.value).inSeconds;

  /// The last ten seconds turn amber. Visual only — nothing about the timer
  /// changes.
  bool get _isUrgent => _secondsLeft <= 10;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          final Color accent = _isUrgent ? c.warningGraphic : c.brandIdentity;

          return Container(
            padding: const EdgeInsets.fromLTRB(8, 8, Insets.s16, 8),
            decoration: BoxDecoration(
              color: c.bgFloating,
              borderRadius: BorderRadius.circular(Radii.full),
              border: Border.all(color: c.borderDivider),
              boxShadow: Elevations.float,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    value: _controller.value,
                    strokeWidth: 4,
                    strokeCap: StrokeCap.round,
                    backgroundColor: c.bgSunken,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
                const SizedBox(width: Insets.s12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '$_secondsLeft',
                      style: context.texts.numericLg.copyWith(
                        color: _isUrgent ? c.warning : c.textPrimary,
                      ),
                    ),
                    Text(
                      'TO_DECIDE'.tr(),
                      style: context.texts.caption.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
