import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

import 'logic.dart';
import 'package:easy_localization/easy_localization.dart';

/// Tab body inside `DrawerScreen`; binding attached to [AppRoutes.home]
/// (`14` §3.5).
///
/// UX-redesign S3 (`03 S14`): one [TermRow] per term. The content source is
/// unchanged — the five terms in `TermConditionState`, not the prototype's
/// text.
class TermConditionPage extends StatelessWidget {
  const TermConditionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final terms = Get.find<TermConditionLogic>().state.termKeys;

    return ColoredBox(
      color: context.colors.bgPage,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          Insets.tabContent,
          Insets.s16,
          Insets.tabContent,
          Insets.s24,
        ),
        itemCount: terms.length,
        separatorBuilder: (_, __) => const SizedBox(height: Insets.s8),
        itemBuilder: (BuildContext context, int index) =>
            TermRow(number: index + 1, text: terms[index].tr()),
      ),
    );
  }
}

/// A numbered term on a surface card (`.term` HTML:248-249).
class TermRow extends StatelessWidget {
  const TermRow({super.key, required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return TCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.brandTint,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: context.texts.label.copyWith(
                fontSize: 13,
                color: c.brandText,
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),
          const SizedBox(width: Insets.s12),
          Expanded(
            child: Text(
              text,
              style: context.texts.body.copyWith(
                fontSize: 14,
                height: 1.6,
                color: c.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
