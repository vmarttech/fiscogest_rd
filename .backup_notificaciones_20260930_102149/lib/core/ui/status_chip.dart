import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';

enum StatusChipType { success, warning, error, info, neutral, primary }

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.type = StatusChipType.neutral,
    this.color,
    this.dense = false,
  });

  final String label;
  final StatusChipType type;
  final Color? color;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = color ?? _colorForType(type);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: effectiveColor,
          fontWeight: FontWeight.w600,
          fontSize: dense ? 11 : 12,
        ),
      ),
    );
  }

  Color _colorForType(StatusChipType type) {
    return switch (type) {
      StatusChipType.success => AppColors.success,
      StatusChipType.warning => AppColors.warning,
      StatusChipType.error => AppColors.error,
      StatusChipType.info => AppColors.info,
      StatusChipType.primary => AppColors.primary,
      StatusChipType.neutral => AppColors.grey500,
    };
  }
}
