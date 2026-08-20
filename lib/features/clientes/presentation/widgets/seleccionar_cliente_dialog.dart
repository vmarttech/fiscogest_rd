import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_dialog.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_entity.dart';
import 'package:fiscogest_rd/features/clientes/presentation/providers/cliente_providers.dart';

class SeleccionarClienteDialog extends ConsumerWidget {
  const SeleccionarClienteDialog({super.key});

  static Future<ClienteEntity?> mostrar(BuildContext context) async {
    return showDialog<ClienteEntity>(
      context: context,
      builder: (_) => const SeleccionarClienteDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientesAsync = ref.watch(clientesControllerProvider);
    final buscadorController = TextEditingController();
    String terminoBusqueda = '';

    List<ClienteEntity> filtrar(List<ClienteEntity> todos, String termino) {
      if (termino.isEmpty) return todos;
      final t = termino.toLowerCase();
      return todos.where((c) =>
        c.nombre.toLowerCase().contains(t) ||
        c.rncCedula.toLowerCase().contains(t) ||
        c.codigo.toLowerCase().contains(t)
      ).toList();
    }

    return StatefulBuilder(
      builder: (context, setState) {
        return AppDialog(
          title: 'Seleccionar Cliente',
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Buscar cliente',
                  hint: 'Nombre, RNC o Código',
                  controller: buscadorController,
                  onChanged: (valor) {
                    setState(() => terminoBusqueda = valor);
                  },
                ),
                const SizedBox(height: AppSpacing.m),
                Flexible(
                  child: clientesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                      child: Padding(
                        padding: AppSpacing.allM,
                        child: Text(
                          '❌ Error al cargar clientes: $error',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    data: (todos) {
                      final lista = filtrar(todos, terminoBusqueda);
                      if (lista.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: AppSpacing.allL,
                            child: Text(
                              terminoBusqueda.isEmpty
                                  ? 'No hay clientes registrados'
                                  : 'No se encontraron coincidencias',
                              style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: lista.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final cliente = lista[i];
                          return ListTile(
                            title: Text(cliente.nombre, style: AppTypography.labelMedium),
                            subtitle: Text('${cliente.codigo} · ${cliente.rncCedula}', style: AppTypography.bodySmall),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () => Navigator.pop(context, cliente),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }
}
