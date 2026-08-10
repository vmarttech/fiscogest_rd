import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_sizes.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';

class AppDropdown<T> extends StatelessWidget {

  const AppDropdown({
    super.key,
    this.label,
    required this.initialValue,
    required this.items,
    required this.onChanged,
    this.hint,
    this.errorText,
    this.enabled = true,
    this.height = AppSizes.inputHeightMd,
  });
  final String? label;
  final T? initialValue;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final String? errorText;
  final bool enabled;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DropdownButtonFormField<T>(
        initialValue: initialValue,
        items: items,
        onChanged: enabled ? onChanged : null,
        style: AppTypography.bodyMedium,
        icon: const Icon(Icons.expand_more, color: AppColors.grey600),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
          contentPadding: AppSpacing.allM,
          labelStyle: AppTypography.labelMedium,
          hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.grey400),
          errorStyle: AppTypography.error,
          border: OutlineInputBorder(borderRadius: AppRadius.allM),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.allM,
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.allM,
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppRadius.allM,
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppRadius.allM,
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          filled: true,
          fillColor: enabled ? AppColors.white : AppColors.grey100,
        ),
      ),
    );
  }
}
