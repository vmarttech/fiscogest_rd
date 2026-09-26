import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.elevation,
    this.borderColor,
    this.accent = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double? elevation;
  final Color? borderColor;
  /// Borde con toque teal (hero / KPI).
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: padding ?? AppSpacing.allM,
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ??
              (accent
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : AppColors.border),
          width: accent ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey900.withValues(alpha: 0.06),
            blurRadius: elevation ?? 16,
            offset: const Offset(0, 6),
          ),
          if (accent)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      ),
    );
  }
}
