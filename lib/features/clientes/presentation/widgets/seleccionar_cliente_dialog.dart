import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_dialog.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_entity.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_completo.dart';
import 'package:fiscogest_rd/features/clientes/presentation/providers/cliente_completo_providers.dart';

class SeleccionarClienteDialog extends ConsumerWidget {
  const SeleccionarClienteDialog._interno();

  static Future<ClienteEntity?> mostrar(BuildContext contexto) async {
    final seleccionado = await showDialog<ClienteCompleto>(
      context: contexto,
      builder: (_) => const SeleccionarClienteDialog._interno(),
    );
    if (seleccionado == null) {
      return null;
    }
    return ClienteEntity(
      id: seleccionado.id,
      codigo: '',
      nombre: seleccionado.nombre,
      rncCedula: seleccionado.rncCedula,
      telefono: seleccionado.telefono,
      correo: seleccionado.correo,
      direccion: seleccionado.direccion,
      activo: seleccionado.activo,
    );
  }

  @override
  Widget build(BuildContext contexto, WidgetRef referenciador) {
    final controladorBusqueda = TextEditingController();
    String terminoBusqueda = '';

    return StatefulBuilder(
      builder: (context, actualizarEstado) {
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
                  hint: 'Nombre, RNC o Teléfono',
                  controller: controladorBusqueda,
                  onChanged: (valor) {
                    actualizarEstado(() => terminoBusqueda = valor);
                  },
                ),
                AppLayout.vM,
                Flexible(
                  child: FutureBuilder<List<ClienteCompleto>>(
                    future: referenciador
                        .read(clienteCompletoControllerProvider.notifier)
                        .buscarPorNombre(terminoBusqueda),
                    builder: (context, instantanea) {
                      if (instantanea.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (instantanea.hasError) {
                        return Center(
                          child: Padding(
                            padding: AppSpacing.allM,
                            child: Text(
                              'Error al cargar clientes: ${instantanea.error}',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      final listado = instantanea.data ?? [];
                      if (listado.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: AppSpacing.allL,
                            child: Text(
                              terminoBusqueda.isEmpty
                                  ? 'No hay clientes registrados'
                                  : 'No se encontraron coincidencias',
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: listado.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, indice) {
                          final cliente = listado[indice];
                          return ListTile(
                            title: Text(
                              cliente.nombre,
                              style: AppTypography.labelMedium,
                            ),
                            subtitle: Text(
                              cliente.rncCedula,
                              style: AppTypography.bodySmall,
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: AppColors.grey600,
                            ),
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
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        );
      },
    );
  }
}
