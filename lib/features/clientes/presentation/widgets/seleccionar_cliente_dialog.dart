import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_dialog.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_entity.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_completo.dart';
import 'package:fiscogest_rd/features/clientes/presentation/providers/cliente_completo_providers.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';

class SeleccionarClienteDialog extends ConsumerWidget {
  const SeleccionarClienteDialog._interno();

  static Future<ClienteEntity?> mostrar(BuildContext contexto) async {
    final seleccionado = await showDialog<ClienteCompleto>(
      context: contexto,
      builder: (_) => const SeleccionarClienteDialog._interno(),
    );
    if (seleccionado == null) return null;
    return ClienteEntity(
      id: seleccionado.id,
      codigo: seleccionado.rncCedula.isNotEmpty
          ? seleccionado.rncCedula
          : 'CLI-${seleccionado.id}',
      nombre: seleccionado.nombre,
      rncCedula: seleccionado.rncCedula,
      telefono: seleccionado.telefono,
      correo: seleccionado.correo,
      direccion: seleccionado.direccion,
      activo: seleccionado.activo,
    );
  }

  /// Diálogo compacto: mismos datos obligatorios que Cartera + mismo controller.
  static Future<ClienteCompleto?> _dialogoNuevoCliente(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final nombre = TextEditingController();
    final rnc = TextEditingController();
    final telefono = TextEditingController();
    final correo = TextEditingController();
    final direccion = TextEditingController();
    final formKey = GlobalKey<FormState>();

    try {
      final ok = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Nuevo cliente'),
            content: SizedBox(
              width: 420,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nombre,
                        decoration: const InputDecoration(
                          labelText: 'Nombre / Razón Social *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Requerido'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: rnc,
                        decoration: const InputDecoration(
                          labelText: 'RNC o Cédula *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Requerido'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: telefono,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono / Celular *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Requerido'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: correo,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Requerido'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: direccion,
                        decoration: const InputDecoration(
                          labelText: 'Dirección',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  Navigator.pop(ctx, true);
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      );

      if (ok != true) return null;

      final cli = ClienteCompleto(
        nombre: nombre.text.trim(),
        rncCedula: rnc.text.trim(),
        telefono: telefono.text.trim(),
        correo: correo.text.trim(),
        direccion: direccion.text.trim(),
        activo: true,
      );

      // Misma capa que Cartera de Clientes
      await ref.read(clienteCompletoControllerProvider.notifier).guardar(cli);

      // Recargar y localizar el recién creado (por RNC o nombre)
      final lista = await ref
          .read(clienteCompletoControllerProvider.notifier)
          .buscarPorNombre(cli.nombre);
      ClienteCompleto? encontrado;
      for (final c in lista) {
        if (c.rncCedula == cli.rncCedula || c.nombre == cli.nombre) {
          encontrado = c;
          break;
        }
      }
      return encontrado ?? (lista.isNotEmpty ? lista.first : null);
    } catch (e) {
      if (context.mounted) {
        FiscoGestNotifications.show(
          SnackBar(
            content: Text('Error al guardar cliente: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return null;
    } finally {
      nombre.dispose();
      rnc.dispose();
      telefono.dispose();
      correo.dispose();
      direccion.dispose();
    }
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.person_add_outlined, size: 18),
                    label: const Text('Nuevo cliente'),
                    onPressed: () async {
                      final creado = await _dialogoNuevoCliente(
                        context,
                        referenciador,
                      );
                      if (creado != null && context.mounted) {
                        Navigator.of(context).pop(creado);
                      } else if (context.mounted) {
                        // Refrescar lista tras alta o cancelación
                        actualizarEstado(() {});
                      }
                    },
                  ),
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
                          child: Text(
                            'Error: ${instantanea.error}',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        );
                      }
                      final listado = instantanea.data ?? [];
                      if (listado.isEmpty) {
                        return Center(
                          child: Text(
                            terminoBusqueda.isEmpty
                                ? 'No hay clientes registrados'
                                : 'No se encontraron coincidencias',
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textSecondary,
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
                            onTap: () => Navigator.of(context).pop(cliente),
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }
}
