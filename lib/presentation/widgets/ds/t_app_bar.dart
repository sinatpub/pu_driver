import 'package:flutter/material.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds_icons.dart';
import 'package:tara_driver_application/presentation/widgets/ds/t_button.dart';

/// App bar for a pushed screen: back, a title, a hairline below (`02 §10`).
///
/// The drawer shell keeps its own bar (menu · title · bell · pill); this one
/// is for the routes pushed on top of it — history detail, announcements and
/// the announcement detail.
///
/// [onBack] is the caller's: the announcement detail routes home instead of
/// popping when it was opened cold from a push notification, and that choice
/// belongs to the screen, not to this widget. Null pops the route.
class TAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TAppBar({super.key, required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  static const double _height = 64;

  @override
  Size get preferredSize => const Size.fromHeight(_height + 1);

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    return AppBar(
      toolbarHeight: _height,
      backgroundColor: c.bgSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: Insets.s8,
      leadingWidth: Sizes.touchTarget + Insets.s16,
      leading: Padding(
        padding: const EdgeInsets.only(left: Insets.s8),
        child: TIconButton(
          icon: DsIcons.back,
          filled: false,
          semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.texts.subtitle.copyWith(color: c.textPrimary),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: c.borderDivider),
      ),
    );
  }
}
