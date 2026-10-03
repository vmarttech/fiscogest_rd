import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';

class AppActionBar extends StatelessWidget {
  const AppActionBar({
    super.key,
    required this.actions,
    this.alignment = WrapAlignment.end,
    this.spacing = 12,
    this.runSpacing = 8,
  });

  final List<Widget> actions;
  final WrapAlignment alignment;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    if (AppBreakpoints.isMobile(context)) {
      return Row(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            Expanded(child: actions[i]),
          ],
        ],
      );
    }

    return Wrap(
      alignment: alignment,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: spacing,
      runSpacing: runSpacing,
      children: actions,
    );
  }
}
