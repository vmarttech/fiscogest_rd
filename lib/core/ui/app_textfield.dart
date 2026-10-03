import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
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
    this.height,
    this.inputFormatters,
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
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? Colors.white.withValues(alpha: 0.95) : AppColors.textPrimary;
    final labelColor =
        isDark ? Colors.white.withValues(alpha: 0.72) : AppColors.textSecondary;
    final hintColor =
        isDark ? Colors.white.withValues(alpha: 0.35) : AppColors.grey400;
    final iconColor =
        isDark ? Colors.white.withValues(alpha: 0.65) : AppColors.grey600;
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.18) : AppColors.grey300;
    final focusColor = isDark ? const Color(0xFF2DD4BF) : AppColors.primary;

    return SizedBox(
      height: height,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        enabled: enabled,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        inputFormatters: inputFormatters,
        style: AppTypography.bodyMedium.copyWith(color: textColor),
        cursorColor: focusColor,
        decoration: InputDecoration(
          isDense: true,
          filled: isDark,
          fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          label: label != null
              ? Text(
                  label!,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: AppTypography.labelMedium.copyWith(color: labelColor),
                )
              : null,
          hintText: hint,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: hintColor,
            overflow: TextOverflow.ellipsis,
          ),
          errorText: errorText,
          errorStyle: AppTypography.bodySmall.copyWith(color: AppColors.error),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, size: 20, color: iconColor)
              : null,
          suffixIcon: suffixIcon != null
              ? IconButton(
                  icon: Icon(suffixIcon, size: 20, color: iconColor),
                  onPressed: onSuffixTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: focusColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
        ),
      ),
    );
  }
}
