import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_sizes.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';

class AppTextField extends StatelessWidget {

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.onChanged,
    this.onSubmitted,
    this.height = AppSizes.inputHeightMd,
  });
  final String? label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        enabled: enabled,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        style: AppTypography.bodyMedium,
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
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: AppSizes.iconMd, color: AppColors.grey600) : null,
          suffixIcon: suffixIcon != null
              ? InkWell(
                  onTap: onSuffixTap,
                  borderRadius: AppRadius.allM,
                  child: Icon(suffixIcon, size: AppSizes.iconMd, color: AppColors.grey600),
                )
              : null,
          filled: true,
          fillColor: enabled ? AppColors.white : AppColors.grey100,
        ),
      ),
    );
  }
}
