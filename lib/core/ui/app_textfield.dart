import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/core/ui/app_sizes.dart';

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
    // Altura por defecto: estándar Material 3
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
  final double height;

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
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, size: 20, color: AppColors.grey600)
              : null,
          suffixIcon: suffixIcon != null
              ? IconButton(
                  icon: Icon(suffixIcon, size: 20, color: AppColors.grey600),
                  onPressed: onSuffixTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                )
              : null,
          // Padding vertical ajustado para altura de 56px
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
