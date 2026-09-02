import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.elevation,
  });
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double? elevation;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? AppSpacing.allM,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: AppRadius.allM,
        boxShadow: elevation != null
            ? [
                BoxShadow(
                  color: AppColors.grey200.withValues(alpha: 0.5),
                  blurRadius: elevation!,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: child,
    );

    return onTap != null
        ? InkWell(onTap: onTap, borderRadius: AppRadius.allM, child: content)
        : content;
  }
}
