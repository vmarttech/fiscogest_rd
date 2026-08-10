import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/core/ui/app_sizes.dart';

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.initialValue, // ✅ Parámetro agregado para que tus páginas no fallen
    required this.items,
    required this.onChanged,
    this.height = AppSizes.inputHeightMd,
  });

  final String? label;
  final String? hint;
  final String? errorText;
  final T? initialValue; // Reemplaza el antiguo 'value'
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DropdownButtonFormField<T>(
        // ✅ Usamos el parámetro actualizado que recomienda Flutter
        initialValue: initialValue,
        items: items,
        onChanged: onChanged,
        isExpanded: true,
        menuMaxHeight: 350,
        style: AppTypography.bodyMedium,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: 12,
          ),
          border: OutlineInputBorder(borderRadius: AppRadius.allM),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.allM,
            borderSide: const BorderSide(color: AppColors.grey300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.allM,
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppRadius.allM,
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppRadius.allM,
            borderSide: const BorderSide(color: AppColors.error),
          ),
          filled: true,
          fillColor: AppColors.white,
        ),
      ),
    );
  }
}
