import 'package:flutter/material.dart';

/// UX-redesign F1 — the design tokens the redesigned UI is built from.
///
/// Source of truth: `docs/ux-redesign/02-design-system.md`. Every colour pair
/// used by a component was measured against WCAG 2.1 before it was written
/// here; the ratios are in `02 §1.2` and pinned by
/// `test/core/theme/tokens_contrast_test.dart`.
///
/// The app is **light** (`DD-01`). Dark is not built, but components read
/// semantic names only, so adding it later is a values change rather than a
/// redesign.
///
/// These are the app's only colour and type tables: the legacy `AppColors`
/// and `ThemeConstands` were deleted once the last screen migrated (roadmap
/// S5).

/// Kantumruy Pro, registered in `pubspec.yaml:121-130` as a variable font
/// (`wght` axis) plus two static per-face families.
///
/// Weights are expressed as [FontVariation]s so the variable face actually
/// interpolates; [TextStyle.fontWeight] is set alongside for fallback and for
/// any synthetic-bold path.
const String kFontFamily = 'KantumruyPro';

/// The design system's weights. Kantumruy Pro's `wght` axis tops out at 700,
/// which is why the prototype's 800 maps to 700 (`02 §2`).
class FontWeights {
  const FontWeights._();

  static const regular = FontWeight.w400;
  static const semiBold = FontWeight.w600;
  static const bold = FontWeight.w700;
}

/// Spacing scale (`02 §3`). 4 px grid — only these values exist.
class Insets {
  const Insets._();

  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;

  /// Horizontal padding for a full screen (`.screen`).
  static const double screen = s20;

  /// Horizontal padding for tab content inside the shell (`.scroll`).
  static const double tabContent = s16;

  /// Minimum gap between two adjacent tap targets.
  static const double betweenTargets = s8;

  /// Minimum gap between Accept and Cancel on a ride request (`DD-11`).
  static const double betweenAcceptAndCancel = s16;
}

/// Corner radii (`02 §4`).
class Radii {
  const Radii._();

  static const double sm = 8;
  static const double md = 12;

  /// Buttons, fields, OTP boxes, list tiles, trip card, passenger row.
  static const double control = 14;

  static const double lg = 16;
  static const double xl = 20;

  /// Sheets — top corners only.
  static const double sheet = 22;

  static const double full = 999;

  static const BorderRadius controlRadius =
      BorderRadius.all(Radius.circular(control));
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius dialogRadius =
      BorderRadius.all(Radius.circular(xl));
  static const BorderRadius sheetRadius = BorderRadius.only(
    topLeft: Radius.circular(sheet),
    topRight: Radius.circular(sheet),
  );
}

/// Minimum sizes (`02 §7`, `ui-layout-system.md §4`).
class Sizes {
  const Sizes._();

  /// Nothing tappable ships below this.
  static const double touchTarget = 48;

  /// Primary CTA — deliberately larger than the platform default, because it
  /// is pressed one-handed, in a vehicle, often in motion.
  static const double primaryButton = 56;

  static const double input = 56;
  static const double listRow = 64;
}

/// Elevation (`02 §5`).
///
/// On light, borders do the separating and shadow only lifts what genuinely
/// floats — shadow-heavy UI over a map turns to mud. Shadow colour is the
/// neutral `#3A3A3C` at low alpha, never pure black.
class Elevations {
  const Elevations._();

  static const Color _shadow = Color(0xFF3A3A3C);

  /// Cards sitting on [TaarraaColors.bgPage]: border only.
  static const List<BoxShadow> flat = <BoxShadow>[];

  /// Cards and pills floating over the map, the countdown, the toast.
  static const List<BoxShadow> float = <BoxShadow>[
    BoxShadow(color: Color(0x1F3A3A3C), blurRadius: 8, offset: Offset(0, 2)),
  ];

  /// Bottom sheets — the shadow rises from the sheet's top edge.
  static const List<BoxShadow> sheet = <BoxShadow>[
    BoxShadow(color: Color(0x1A3A3A3C), blurRadius: 16, offset: Offset(0, -2)),
  ];

  /// Dialogs, over the scrim.
  static const List<BoxShadow> modal = <BoxShadow>[
    BoxShadow(color: Color(0x293A3A3C), blurRadius: 32, offset: Offset(0, 8)),
  ];

  /// The selected segment or tab.
  static const List<BoxShadow> selected = <BoxShadow>[
    BoxShadow(color: Color(0x143A3A3C), blurRadius: 2, offset: Offset(0, 1)),
  ];

  /// Exposed for tests and for anyone tuning the alphas above.
  static const Color shadowColor = _shadow;
}

/// The semantic colour set (`02 §1.1`).
///
/// Names say what a colour *means*, never what it looks like, so a component
/// never has to know a hex value.
@immutable
class TaarraaColors {
  const TaarraaColors({
    required this.bgPage,
    required this.bgSurface,
    required this.bgRaised,
    required this.bgSunken,
    required this.bgFloating,
    required this.scrim,
    required this.blockingOverlay,
    required this.borderDivider,
    required this.borderControl,
    required this.borderFocus,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.textOnAction,
    required this.brandIdentity,
    required this.brandText,
    required this.brandTint,
    required this.actionPrimary,
    required this.actionHighlight,
    required this.actionPressed,
    required this.success,
    required this.successGraphic,
    required this.successTint,
    required this.warning,
    required this.warningGraphic,
    required this.warningTint,
    required this.danger,
    required this.info,
    required this.stageRequestTint,
    required this.stageRequestText,
    required this.stagePickupTint,
    required this.stagePickupText,
    required this.stageOnTripTint,
    required this.stageOnTripText,
    required this.toastBackground,
    required this.toastText,
    required this.avatarFallbackBackground,
    required this.avatarFallbackText,
  });

  // ---- surfaces -----------------------------------------------------------

  /// Scaffold behind cards and lists.
  final Color bgPage;

  /// Cards, sheets, dialogs, inputs, app bar.
  final Color bgSurface;

  /// Segmented and tab tracks, chip rests.
  final Color bgRaised;

  /// Disabled fills.
  final Color bgSunken;

  /// Cards floating over the map. **Opaque** — translucency was a dark-mode
  /// device and is illegible over light map imagery.
  final Color bgFloating;

  /// Behind sheets, dialogs and the drawer.
  final Color scrim;

  /// Full blocking overlays, e.g. the approval gate.
  final Color blockingOverlay;

  // ---- borders ------------------------------------------------------------

  /// Dividers and card hairlines. Decorative: 1.29 on white, so it must never
  /// be the only thing marking a control.
  final Color borderDivider;

  /// Inputs, chips, icon buttons, ghost buttons. 3.13 on white — clears the
  /// 3:1 non-text floor. Controls sit on [bgSurface], not on [bgPage].
  final Color borderControl;

  /// Focused input.
  final Color borderFocus;

  // ---- text ---------------------------------------------------------------

  /// 11.35 on white. All money figures.
  final Color textPrimary;

  /// Sub-lines, metadata, placeholders. 4.64 on white.
  final Color textSecondary;

  /// Labels of inert controls, on [bgSunken] (3.59). Never used for
  /// information the driver needs.
  final Color textDisabled;

  /// Labels on [actionPrimary] (5.10) and [success] (5.46).
  final Color textOnAction;

  // ---- brand and action ---------------------------------------------------

  /// **Graphics only** (3.44 on white): logo, route line, markers, countdown
  /// arc, active indicator fills. Never text, and never a fill under white
  /// text — that is what [actionPrimary] is for (`DD-02`).
  final Color brandIdentity;

  /// Brand-coloured text and links (5.10).
  final Color brandText;

  /// Selected row or chip background; carries [brandText] at 4.63.
  final Color brandTint;

  /// Primary button fill. White label measures 5.10.
  final Color actionPrimary;

  /// Optional top stop of the primary button's gradient (white label 4.59).
  final Color actionHighlight;

  /// Pressed primary fill (white label 6.91).
  final Color actionPressed;

  // ---- semantic -----------------------------------------------------------

  /// Success text, icons and fills (5.46 both directions).
  final Color success;

  /// Dots, marker accents, meter bars. Fails as text (2.05) — never a label.
  final Color successGraphic;

  /// Online pill, on-trip strip, completed timeline step.
  final Color successTint;

  /// Warning text (4.95).
  final Color warning;

  /// Countdown arc at ≤10 s, warning icons. Fails as text.
  final Color warningGraphic;

  /// Offline banner, pending approval.
  final Color warningTint;

  /// Error text, destructive outline and label (4.98). Destructive buttons are
  /// outlined, never filled (`02 §1.4`).
  final Color danger;

  /// Informational text and icons (4.60).
  final Color info;

  // ---- trip stages (`03 S07`) --------------------------------------------

  final Color stageRequestTint;

  /// 6.01 on [stageRequestTint].
  final Color stageRequestText;

  final Color stagePickupTint;

  /// 6.35 on [stagePickupTint].
  final Color stagePickupText;

  final Color stageOnTripTint;

  /// 4.92 on [stageOnTripTint].
  final Color stageOnTripText;

  // ---- odds and ends ------------------------------------------------------

  /// A dark pill on a light UI (11.35).
  final Color toastBackground;
  final Color toastText;

  /// Initials when a driver or passenger has no photo — the P3 secondary
  /// text value, 5.01 on the #EBEBF0 fill.
  final Color avatarFallbackBackground;
  final Color avatarFallbackText;

  /// The light palette. Values and their measured ratios: `02 §1.1`.
  static const TaarraaColors light = TaarraaColors(
    bgPage: Color(0xFFF2F2F5),
    bgSurface: Color(0xFFFFFFFF),
    bgRaised: Color(0xFFEBEBF0),
    bgSunken: Color(0xFFE2E2E5),
    bgFloating: Color(0xFFFFFFFF),
    scrim: Color(0x7A3A3A3C),
    blockingOverlay: Color(0xF7FFFFFF),
    borderDivider: Color(0xFFE2E2E5),
    borderControl: Color(0xFF8F90A6),
    borderFocus: Color(0xFFCC3700),
    textPrimary: Color(0xFF3A3A3C),
    // P3: was #6B7588 — 4.64 on white only, 4.15 on bg.page and 3.91 on
    // bg.raised, where most secondary text sits. #5C6474 clears 4.5 on every
    // neutral fill (surface 5.95, page 5.32, raised 5.01, sunken 4.60).
    textSecondary: Color(0xFF5C6474),
    textDisabled: Color(0xFF6B7588),
    textOnAction: Color(0xFFFFFFFF),
    brandIdentity: Color(0xFFFF4500),
    brandText: Color(0xFFCC3700),
    brandTint: Color(0xFFFFF1EC),
    actionPrimary: Color(0xFFCC3700),
    actionHighlight: Color(0xFFD93B00),
    actionPressed: Color(0xFFA82D00),
    success: Color(0xFF1C784D),
    successGraphic: Color(0xFF10CF7C),
    successTint: Color(0xFFE6F7EF),
    // P3: was #8D6B07 — 4.46 on stage.onTrip.tint (the meter's estimate note)
    // and 4.43 on bg.page. #86650A clears 4.5 on every fill amber text sits on.
    warning: Color(0xFF86650A),
    warningGraphic: Color(0xFFFFB020),
    warningTint: Color(0xFFFFF6E5),
    danger: Color(0xFFD32F2F),
    info: Color(0xFF1976D2),
    stageRequestTint: Color(0xFFFFF1E8),
    stageRequestText: Color(0xFFA33A00),
    stagePickupTint: Color(0xFFE8F1FD),
    stagePickupText: Color(0xFF1A579E),
    stageOnTripTint: Color(0xFFE6F7EF),
    stageOnTripText: Color(0xFF1C784D),
    toastBackground: Color(0xFF3A3A3C),
    toastText: Color(0xFFFFFFFF),
    avatarFallbackBackground: Color(0xFFEBEBF0),
    avatarFallbackText: Color(0xFF5C6474),
  );
}

/// The type scale (`02 §2`).
///
/// Khmer stacks diacritics above and below the baseline, so every style has a
/// taller Khmer line height; [TaarraaTextStyles.khmer] is selected from the
/// active locale when the theme is built. Sizes never change between the two.
@immutable
class TaarraaTextStyles {
  const TaarraaTextStyles({
    required this.display,
    required this.headline,
    required this.numericLg,
    required this.title,
    required this.subtitle,
    required this.bodyStrong,
    required this.body,
    required this.bodySecondary,
    required this.label,
    required this.caption,
    required this.micro,
  });

  /// The amount to collect.
  final TextStyle display;

  /// Screen titles, blocking-state titles.
  final TextStyle headline;

  /// Countdown seconds — tabular, so the pill doesn't jitter as digits change.
  final TextStyle numericLg;

  /// Dialog titles, the focused address in the trip sheet.
  final TextStyle title;

  /// App-bar and section titles.
  final TextStyle subtitle;

  /// Button labels, names, addresses.
  final TextStyle bodyStrong;

  /// Body copy, input text.
  final TextStyle body;

  /// Dialog and news body.
  final TextStyle bodySecondary;

  /// Field labels, chips, tabs.
  final TextStyle label;

  /// Metadata, timestamps.
  final TextStyle caption;

  /// Badges, pills, timeline labels, overlines. **Never uppercased** — Khmer
  /// has no case, so an all-caps Latin style has no Khmer equivalent.
  final TextStyle micro;

  static TextStyle _style(
    double size,
    FontWeight weight,
    double heightFactor, {
    bool tabular = false,
  }) {
    return TextStyle(
      fontFamily: kFontFamily,
      fontSize: size,
      fontWeight: weight,
      height: heightFactor,
      fontVariations: <FontVariation>[
        FontVariation('wght', weight.value.toDouble()),
      ],
      fontFeatures:
          tabular ? const <FontFeature>[FontFeature.tabularFigures()] : null,
    );
  }

  static TaarraaTextStyles _build({
    required double display,
    required double headline,
    required double numeric,
    required double title,
    required double subtitle,
    required double bodyStrong,
    required double body,
    required double bodySecondary,
    required double label,
    required double caption,
    required double micro,
  }) {
    return TaarraaTextStyles(
      display: _style(30, FontWeights.bold, display, tabular: true),
      headline: _style(24, FontWeights.bold, headline),
      numericLg: _style(22, FontWeights.bold, numeric, tabular: true),
      title: _style(18, FontWeights.bold, title),
      subtitle: _style(17, FontWeights.bold, subtitle),
      bodyStrong: _style(16, FontWeights.bold, bodyStrong),
      body: _style(15, FontWeights.regular, body),
      bodySecondary: _style(14, FontWeights.regular, bodySecondary),
      label: _style(13, FontWeights.bold, label),
      caption: _style(12, FontWeights.regular, caption),
      micro: _style(12, FontWeights.bold, micro),
    );
  }

  /// Latin line heights.
  static final TaarraaTextStyles latin = _build(
    display: 1.25,
    headline: 1.3,
    numeric: 1.2,
    title: 1.35,
    subtitle: 1.35,
    bodyStrong: 1.4,
    body: 1.45,
    bodySecondary: 1.55,
    label: 1.35,
    caption: 1.35,
    micro: 1.3,
  );

  /// Khmer line heights — taller, and non-negotiable: Latin values clip the
  /// stacked diacritics.
  static final TaarraaTextStyles khmer = _build(
    display: 1.5,
    headline: 1.55,
    numeric: 1.2,
    title: 1.7,
    subtitle: 1.7,
    bodyStrong: 1.75,
    body: 1.8,
    bodySecondary: 1.8,
    label: 1.7,
    caption: 1.7,
    micro: 1.6,
  );
}

/// The token bundle, reachable from any widget through [BuildContext.tokens].
@immutable
class TaarraaTokens extends ThemeExtension<TaarraaTokens> {
  const TaarraaTokens({required this.colors, required this.text});

  final TaarraaColors colors;
  final TaarraaTextStyles text;

  @override
  TaarraaTokens copyWith({TaarraaColors? colors, TaarraaTextStyles? text}) {
    return TaarraaTokens(
      colors: colors ?? this.colors,
      text: text ?? this.text,
    );
  }

  /// There is one theme, so no cross-theme animation exists to interpolate;
  /// snapping keeps this honest rather than lerping 38 colours that never
  /// change. Revisit if a second theme is ever built.
  @override
  TaarraaTokens lerp(ThemeExtension<TaarraaTokens>? other, double t) {
    if (other is! TaarraaTokens) return this;
    return t < 0.5 ? this : other;
  }
}

/// Shorthand so a widget reads `context.colors.bgSurface` rather than
/// `Theme.of(context).extension<TaarraaTokens>()!.colors.bgSurface`.
extension TaarraaThemeContext on BuildContext {
  TaarraaTokens get tokens =>
      Theme.of(this).extension<TaarraaTokens>() ?? _fallbackTokens;

  TaarraaColors get colors => tokens.colors;

  TaarraaTextStyles get texts => tokens.text;
}

/// Only reached if a widget is built under a `ThemeData` that never registered
/// the extension (a bare `MaterialApp` in a widget test, say).
///
/// Not `const`: [TaarraaTextStyles.latin] is built at runtime, because each
/// style composes a [FontVariation] list.
final TaarraaTokens _fallbackTokens = TaarraaTokens(
  colors: TaarraaColors.light,
  text: TaarraaTextStyles.latin,
);
