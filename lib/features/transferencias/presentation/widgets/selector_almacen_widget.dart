import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/features/almacenes/presentation/providers/almacen_providers.dart';
import 'package:fiscogest_rd/features/almacenes/domain/entities/almacen.dart';

class SelectorAlmacenWidget extends ConsumerWidget {
  const SelectorAlmacenWidget({
    super.key,
    required this.label,
    this.initialValue,
    required this.onChanged,
    this.excludeId,
  });

  final String label;
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final String? excludeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(almacenesControllerProvider);
    return async.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text(
        'Error almacenes: $e',
        style: AppTypography.bodyMedium.copyWith(color: AppColors.errorDark),
      ),
      data: (lista) {
        final items = lista
            .where((a) => a.activo && '${a.id}' != excludeId)
            .toList();
        final ids = items.map((a) => '${a.id}').toSet();
        final value = ids.contains(initialValue) ? initialValue : null;
        return InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: AppTypography.labelMedium.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              hint: Text(
                'Seleccione',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.grey600,
                ),
              ),
              value: value,
              items: [
                for (final a in items)
                  DropdownMenuItem(
                    value: '${a.id}',
                    child: Text(
                      '${a.codigo} — ${a.nombre} (${a.tipo.label})',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        );
      },
    );
  }
}
