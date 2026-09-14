import 'package:flutter/material.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';

/// The app's single `ThemeData`, built from [TaarraaTokens].
///
/// UX-redesign F1. The app is light (`DD-01`). Every screen now reads the
/// tokens directly; the legacy `AppColors`/`ThemeConstands` tables were deleted
/// in S5.
///
/// Deliberately modest: the colour scheme, the text theme and a handful of
/// surface-level component themes, for the Material widgets screens still use
/// unstyled (spinners, `RefreshIndicator`, `AppBar` defaults).
class AppTheme {
  const AppTheme._();

  /// [khmer] picks the taller Khmer line heights (`02 §2`). It comes from the
  /// active locale in `root_main.dart`, so switching language rebuilds the
  /// theme with the right metrics.
  static ThemeData light({required bool khmer}) {
    const TaarraaColors c = TaarraaColors.light;
    final TaarraaTextStyles t =
        khmer ? TaarraaTextStyles.khmer : TaarraaTextStyles.latin;

    final ColorScheme scheme = ColorScheme.light(
      // `primary` is what Material fills buttons and indicators with, so it is
      // the *action* colour, not the identity orange: white-on-#FF4500
      // measures 3.44:1 and fails AA (`DD-02`).
      primary: c.actionPrimary,
      onPrimary: c.textOnAction,
      secondary: c.brandIdentity,
      onSecondary: c.textOnAction,
      surface: c.bgSurface,
      onSurface: c.textPrimary,
      error: c.danger,
      onError: c.textOnAction,
      outline: c.borderControl,
      outlineVariant: c.borderDivider,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: kFontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bgPage,
      canvasColor: c.bgSurface,
      dividerColor: c.borderDivider,
      shadowColor: Elevations.shadowColor,

      // No screen reads these directly any more (checked in S5); they stay
      // for Material widgets that fall back to them. `primaryColor` is the
      // identity orange — anything that puts white text on a fill must use
      // `colorScheme.primary`.
      primaryColor: c.brandIdentity,
      primaryColorDark: c.actionPressed,
      primaryColorLight: c.brandTint,
      hintColor: c.textSecondary,

      extensions: <ThemeExtension<dynamic>>[
        TaarraaTokens(colors: c, text: t),
      ],

      textTheme: TextTheme(
        displaySmall: t.display,
        headlineMedium: t.headline,
        headlineSmall: t.numericLg,
        titleLarge: t.title,
        titleMedium: t.subtitle,
        titleSmall: t.bodyStrong,
        bodyLarge: t.body,
        bodyMedium: t.bodySecondary,
        bodySmall: t.caption,
        labelLarge: t.label,
        labelSmall: t.micro,
      ).apply(
        bodyColor: c.textPrimary,
        displayColor: c.textPrimary,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: c.bgSurface,
        foregroundColor: c.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: t.subtitle.copyWith(color: c.textPrimary),
        iconTheme: IconThemeData(color: c.textPrimary),
      ),

      dividerTheme: DividerThemeData(
        color: c.borderDivider,
        thickness: 1,
        space: 1,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: c.bgSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: Radii.dialogRadius),
        titleTextStyle: t.title.copyWith(color: c.textPrimary),
        contentTextStyle: t.bodySecondary.copyWith(color: c.textSecondary),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.bgSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalBarrierColor: c.scrim,
        shape: const RoundedRectangleBorder(borderRadius: Radii.sheetRadius),
      ),

      drawerTheme: DrawerThemeData(
        backgroundColor: c.bgSurface,
        surfaceTintColor: Colors.transparent,
        scrimColor: c.scrim,
        elevation: 0,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.actionPrimary,
        circularTrackColor: c.bgSunken,
      ),

      splashColor: c.brandTint,
      highlightColor: c.brandTint,
    );
  }
}
