import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';

/// UX-redesign F2 — the design-system icon set.
///
/// 24×24, stroke 2, round caps and joins (`docs/ux-redesign/02-design-system.md
/// §6`), extracted from the prototype's inline sprite. Only the icons the
/// redesign actually uses were extracted: the prototype also ships rating,
/// referral, sound and logout glyphs, and those features are not adopted
/// (`DD-05`, `DD-22`, `DD-31`), so bundling them would be dead assets.
///
/// Rendered through the existing `flutter_svg` dependency — no new package.
class DsIcons {
  const DsIcons._();

  static const String _base = 'assets/icon/ds';

  // Navigation and chrome.
  static const String menu = '$_base/menu.svg';
  static const String back = '$_base/back.svg';
  static const String chevron = '$_base/chevron.svg';
  static const String close = '$_base/close.svg';
  static const String refresh = '$_base/refresh.svg';

  // Drawer destinations.
  static const String home = '$_base/home.svg';
  static const String calendar = '$_base/calendar.svg';
  static const String wallet = '$_base/wallet.svg';
  static const String doc = '$_base/doc.svg';
  static const String mail = '$_base/mail.svg';
  static const String globe = '$_base/globe.svg';
  static const String bell = '$_base/bell.svg';

  // Trip.
  static const String car = '$_base/car.svg';
  static const String phone = '$_base/phone.svg';
  static const String clock = '$_base/clock.svg';
  static const String route = '$_base/route.svg';
  static const String check = '$_base/check.svg';

  // Status.
  static const String warn = '$_base/warn.svg';
  static const String info = '$_base/info.svg';

  // Forms.
  static const String camera = '$_base/camera.svg';
}

/// Icon sizes (`02 §6`). The *tap target* is always [Sizes.touchTarget]; these
/// are the glyph sizes.
enum TIconSize {
  sm(16),
  md(22),
  lg(28);

  const TIconSize(this.value);

  final double value;
}

/// A design-system icon.
///
/// The SVGs are authored with `stroke="currentColor"`, so the tint is applied
/// here rather than baked into the asset — one file serves every colour.
class TIcon extends StatelessWidget {
  const TIcon(
    this.asset, {
    super.key,
    this.size = TIconSize.md,
    this.color,
  });

  final String asset;
  final TIconSize size;

  /// Defaults to [TaarraaColors.textSecondary], the neutral icon colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final double side = size.value;
    return SvgPicture.asset(
      asset,
      width: side,
      height: side,
      colorFilter: ColorFilter.mode(
        color ?? context.colors.textSecondary,
        BlendMode.srcIn,
      ),
    );
  }
}
