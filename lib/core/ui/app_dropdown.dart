import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    this.value,
    this.initialValue,
    this.label,
    this.hint,
    required this.items,
    this.onChanged,
    this.isExpanded = true,
    this.enabled = true,
  });

  /// Preferido: se refleja vía Key + initialValue (Flutter ≥ 3.33).
  final T? value;
  final T? initialValue;
  final String? label;
  final String? hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool isExpanded;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final raw = value ?? initialValue;
    T? safe = raw;
    if (safe != null && items.every((i) => i.value != safe)) {
      safe = null;
    }
    final itemsKey = items.map((i) => '${i.value}').join('|');
    return DropdownButtonFormField<T>(
      key: ValueKey('dd_${safe}_$itemsKey'),
      initialValue: safe,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        labelText: label,
        labelStyle: AppTypography.labelMedium,
        hintText: hint,
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.grey400),
        border: const OutlineInputBorder(),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.grey300),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        disabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.grey300),
        ),
      ),
      isExpanded: isExpanded,
      icon: const Icon(Icons.arrow_drop_down, color: AppColors.grey600, size: 20),
      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      items: items,
      onChanged: enabled ? onChanged : null,
      dropdownColor: AppColors.white,
      borderRadius: BorderRadius.circular(8),
    );
  }
}
