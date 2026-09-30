import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';

class AppSection extends StatelessWidget {
  const AppSection({
    super.key,
    this.title,
    required this.children,
    this.padding,
    this.showDivider = true,
  });
  final String? title;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? AppSpacing.vM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: AppTypography.h4),
            AppLayout.vS,
            if (showDivider)
              const Divider(height: 1, thickness: 1, color: AppColors.grey200),
            AppLayout.vM,
          ],
          ...children,
        ],
      ),
    );
  }
}
