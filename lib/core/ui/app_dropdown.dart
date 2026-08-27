import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    this.initialValue,
    this.hint,
    required this.items,
    this.onChanged,
    this.isExpanded = true,
  });

  final T? initialValue;
  final String? hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.inputBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonFormField<T>(
        initialValue: initialValue,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.bodySmall.copyWith(
            color: AppColors.grey400,
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        isExpanded: isExpanded,
        icon: const Icon(Icons.arrow_drop_down, color: AppColors.grey600, size: 20),
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        items: items,
        onChanged: onChanged,
        dropdownColor: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 4,
      ),
    );
  }
}
