import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';

/// UX-redesign F1 — pins the contrast floors the light palette was built to.
///
/// Every pair here is quoted with its measured ratio in
/// `docs/ux-redesign/02-design-system.md §1.2`. The point is not to re-derive
/// the design: it is that a future "small tweak" to a token cannot quietly
/// drop a driver-facing pair below WCAG AA.
///
/// WCAG 2.1: 4.5:1 for normal text, 3:1 for large text and for non-text such
/// as control borders and meaningful icons.
double contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double lighter = la > lb ? la : lb;
  final double darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  const TaarraaColors c = TaarraaColors.light;

  void expectText(String what, Color fg, Color bg) {
    expect(
      contrast(fg, bg),
      greaterThanOrEqualTo(4.5),
      reason: '$what must clear the AA text floor',
    );
  }

  void expectNonText(String what, Color fg, Color bg) {
    expect(
      contrast(fg, bg),
      greaterThanOrEqualTo(3.0),
      reason: '$what must clear the AA non-text floor',
    );
  }

  group('text on surfaces', () {
    test('primary and secondary text', () {
      expectText('text.primary on surface', c.textPrimary, c.bgSurface);
      expectText('text.primary on page', c.textPrimary, c.bgPage);
      expectText('text.secondary on surface', c.textSecondary, c.bgSurface);
      // P3: secondary text mostly sits on the page and on raised cards, not
      // on white — the pairs the old #6B7588 failed (4.15, 3.91).
      expectText('text.secondary on page', c.textSecondary, c.bgPage);
      expectText('text.secondary on raised', c.textSecondary, c.bgRaised);
      expectText('text.secondary on sunken', c.textSecondary, c.bgSunken);
    });
  });

  group('actions', () {
    test('labels on every filled action', () {
      expectText('white on action.primary', c.textOnAction, c.actionPrimary);
      expectText(
          'white on action.highlight', c.textOnAction, c.actionHighlight);
      expectText('white on action.pressed', c.textOnAction, c.actionPressed);
      expectText('white on success fill', c.textOnAction, c.success);
    });

    test('brand text uses brandText, never brandIdentity', () {
      expectText('brand.text on surface', c.brandText, c.bgSurface);
      expectText('brand.text on brand.tint', c.brandText, c.brandTint);

      // The whole point of DD-02: the identity orange is a graphic, and white
      // on it is 3.44 — fine for a shape, not for a label.
      expect(contrast(c.textOnAction, c.brandIdentity), lessThan(4.5));
      expectNonText('brand.identity on surface', c.brandIdentity, c.bgSurface);
    });
  });

  group('semantic text', () {
    test('status colours that carry words', () {
      expectText('success on surface', c.success, c.bgSurface);
      expectText('warning on surface', c.warning, c.bgSurface);
      expectText('danger on surface', c.danger, c.bgSurface);
      expectText('info on surface', c.info, c.bgSurface);
      expectText('warning on warning.tint', c.warning, c.warningTint);
    });

    test('graphic-only colours are not promoted to text', () {
      // Guards the mistake the old theme made: #10CF7C as a switch label.
      expect(contrast(c.successGraphic, c.bgSurface), lessThan(4.5));
      expect(contrast(c.warningGraphic, c.bgSurface), lessThan(4.5));
    });
  });

  group('trip stages', () {
    test('each stage pill reads on its own tint', () {
      expectText('request', c.stageRequestText, c.stageRequestTint);
      expectText('pickup', c.stagePickupText, c.stagePickupTint);
      expectText('on trip', c.stageOnTripText, c.stageOnTripTint);
    });
  });

  group('P3 — status text on the fills it actually sits on', () {
    test('warning copy (estimate note, banners, urgent countdown)', () {
      expectText('warning on onTrip tint', c.warning, c.stageOnTripTint);
      expectText('warning on page', c.warning, c.bgPage);
      expectText('warning on raised', c.warning, c.bgRaised);
      expectText('warning on warning tint', c.warning, c.warningTint);
    });
  });

  group('non-text', () {
    test('control borders and the toast', () {
      expectNonText('border.control on surface', c.borderControl, c.bgSurface);
      expectText('toast text', c.toastText, c.toastBackground);
      expectText(
        'avatar initials',
        c.avatarFallbackText,
        c.avatarFallbackBackground,
      );
    });
  });
}
