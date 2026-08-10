import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';

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
    this.height,
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
    // ✅ SIN Expanded AQUÍ: solo el SizedBox con altura opcional
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
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20, color: AppColors.grey600) : null,
          suffixIcon: suffixIcon != null
              ? IconButton(
                  icon: Icon(suffixIcon, size: 20, color: AppColors.grey600),
                  onPressed: onSuffixTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                )
              : null,
          contentPadding: AppSpacing.allM,
          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
          enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: AppColors.grey300)),
          focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: AppColors.primary)),
          errorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: AppColors.error)),
          focusedErrorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: AppColors.error)),
          filled: true,
          fillColor: AppColors.white,
        ),
      ),
    );
  }
}
