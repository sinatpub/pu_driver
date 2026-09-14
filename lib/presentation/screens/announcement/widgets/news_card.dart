import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

/// One announcement in the list (`03 S12`, `.news` HTML:241-246).
///
/// Unread (`status == 0`, the same rule the old list used for its tint) gets
/// the brand border **and** a dot, so it never relies on colour alone.
class NewsCard extends StatelessWidget {
  const NewsCard({
    super.key,
    required this.title,
    required this.body,
    required this.date,
    required this.unread,
    required this.onTap,
  });

  final String title;
  final String body;
  final String date;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return TCard(
      variant: unread ? TCardVariant.tinted : TCardVariant.flat,
      tintFill: c.bgSurface,
      tintBorder: c.brandIdentity,
      onTap: onTap,
      child: Stack(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                // Clears the unread dot.
                padding: const EdgeInsets.only(right: 18),
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodyStrong.copyWith(
                    fontSize: 15,
                    color: c.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: Insets.s4),
              Text(
                body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.texts.bodySecondary.copyWith(
                  fontSize: 13,
                  height: 1.55,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: Insets.s8),
              Text(
                date,
                style: context.texts.caption.copyWith(color: c.textSecondary),
              ),
            ],
          ),
          if (unread)
            Positioned(
              top: 0,
              right: 0,
              child: Semantics(
                label: 'UNREAD'.tr(),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: c.brandIdentity,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Loading placeholder shaped like [NewsCard].
class NewsCardSkeleton extends StatelessWidget {
  const NewsCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const TCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TSkeleton.line(width: 200),
          SizedBox(height: Insets.s8),
          TSkeleton(height: 12),
          SizedBox(height: Insets.s4),
          TSkeleton(width: 160, height: 12),
          SizedBox(height: Insets.s12),
          TSkeleton(width: 90, height: 10),
        ],
      ),
    );
  }
}
