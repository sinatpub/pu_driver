import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

/// One document photo on the registration form (`04 § B` PhotoSlotGrid,
/// `.photo-slot` HTML:132-133). Replaces `CardUploadAttachment` with the same
/// three inputs: the attached file, a pick callback and a clear callback.
///
/// Empty: dashed border, the document glyph and its name.
/// Attached: solid `success` border, the photo, a check badge, and a 48 px
/// remove button. The attached state is simply `image != null` — the file the
/// controller already holds.
class PhotoSlot extends StatelessWidget {
  const PhotoSlot({
    super.key,
    required this.title,
    required this.icon,
    required this.image,
    required this.onPick,
    required this.onClear,
    this.enabled = true,
  });

  final String title;

  /// An existing `assets/icon/svg/*` document glyph.
  final String icon;

  final File? image;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final bool enabled;

  static const double height = 132;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final bool attached = image != null;

    final Widget body = attached
        ? Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.file(image!, fit: BoxFit.cover),
              Positioned(
                left: Insets.s8,
                top: Insets.s8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: c.success,
                    shape: BoxShape.circle,
                  ),
                  child: TIcon(
                    DsIcons.check,
                    size: TIconSize.sm,
                    color: c.textOnAction,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: TIconButton(
                  icon: DsIcons.close,
                  semanticLabel:
                      '${MaterialLocalizations.of(context).deleteButtonTooltip}: $title',
                  onPressed: enabled ? onClear : null,
                ),
              ),
            ],
          )
        : Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.s8,
              vertical: Insets.s12,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SvgPicture.asset(
                  icon,
                  width: 40,
                  colorFilter:
                      ColorFilter.mode(c.textSecondary, BlendMode.srcIn),
                ),
                const SizedBox(height: Insets.s8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.label.copyWith(color: c.textPrimary),
                ),
              ],
            ),
          );

    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: attached ? c.successTint : c.bgSurface,
        borderRadius: Radii.controlRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onPick : null,
          child: CustomPaint(
            foregroundPainter: _SlotBorderPainter(
              color: attached ? c.success : c.borderControl,
              dashed: !attached,
            ),
            child: SizedBox(height: height, child: body),
          ),
        ),
      ),
    );
  }
}

/// 1.5 px rounded border, dashed while the slot is empty.
class _SlotBorderPainter extends CustomPainter {
  const _SlotBorderPainter({required this.color, required this.dashed});

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 1.5;
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final RRect rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(stroke / 2),
      const Radius.circular(Radii.control),
    );
    final Path path = Path()..addRRect(rrect);
    if (!dashed) {
      canvas.drawPath(path, paint);
      return;
    }
    const double dash = 6;
    const double gap = 4;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dash),
          paint,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_SlotBorderPainter old) =>
      old.color != color || old.dashed != dashed;
}
