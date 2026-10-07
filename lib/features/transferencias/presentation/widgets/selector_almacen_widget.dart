import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      error: (e, _) => Text('Error almacenes: $e'),
      data: (lista) {
        final items = lista.where((a) => a.activo && '${a.id}' != excludeId).toList();
        final ids = items.map((a) => '${a.id}').toSet();
        final value = ids.contains(initialValue) ? initialValue : null;
        return InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: const Text('Seleccione'),
              value: value,
              items: [
                for (final a in items)
                  DropdownMenuItem(
                    value: '${a.id}',
                    child: Text('${a.codigo} — ${a.nombre} (${a.tipo.label})'),
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
