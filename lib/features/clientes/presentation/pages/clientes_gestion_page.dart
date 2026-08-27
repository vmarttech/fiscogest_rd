import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/clientes/presentation/providers/cliente_completo_providers.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_completo.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';

class ClientesGestionPage extends ConsumerStatefulWidget {
  const ClientesGestionPage({super.key});
  static const String routeName = 'clientes-gestion';
  @override
  ConsumerState<ClientesGestionPage> createState() => _ClientesGestionPageState();
}

class _ClientesGestionPageState extends ConsumerState<ClientesGestionPage> {
  final TextEditingController _searchController = TextEditingController();
  String _filtroBusqueda = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientesAsync = ref.watch(clienteCompletoControllerProvider);
    final anchoPantalla = MediaQuery.of(context).size.width;
    final pantallaPequena = anchoPantalla < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          padding: AppSpacing.allL,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              pantallaPequena
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cartera de Clientes',
                          style: AppTypography.h1,
                        ),
                        AppLayout.vXs,
                        Text(
                          'Administración de datos personales, fiscales, direcciones e historial.',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                        AppLayout.vM,
                        AppButton(
                          text: 'Nuevo Cliente',
                          icon: Icons.person_add,
                          onPressed: () => _mostrarModalRegistro(context),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cartera de Clientes',
                              style: AppTypography.h1,
                            ),
                            AppLayout.vXs,
                            Text(
                              'Administración de datos personales, fiscales, direcciones e historial.',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        AppButton(
                          text: 'Nuevo Cliente',
                          icon: Icons.person_add,
                          onPressed: () => _mostrarModalRegistro(context),
                        ),
                      ],
                    ),
              AppLayout.vL,
              AppCard(
                padding: AppSpacing.hM.copyWith(top: AppSpacing.s, bottom: AppSpacing.s),
                child: AppTextField(
                  hint: 'Buscar cliente por nombre, RNC/Cédula, teléfono o correo...',
                  controller: _searchController,
                  onChanged: (value) => setState(() => _filtroBusqueda = value.toLowerCase()),
                  prefixIcon: Icons.search,
                ),
              ),
              AppLayout.vM,
              Expanded(
                child: AppCard(
                  child: clientesAsync.when(
                    data: (clientes) {
                      final filtrados = clientes.where((c) =>
                        c.nombre.toLowerCase().contains(_filtroBusqueda) ||
                        c.rncCedula.toLowerCase().contains(_filtroBusqueda) ||
                        c.telefono.toLowerCase().contains(_filtroBusqueda) ||
                        c.correo.toLowerCase().contains(_filtroBusqueda)
                      ).toList();
                      if (filtrados.isEmpty) {
                        return const Center(
                          child: Text(
                            'No hay clientes registrados o coincidentes.',
                            style: AppTypography.bodyMedium,
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: AppSpacing.allM,
                        itemCount: filtrados.length,
                        separatorBuilder: (context, index) => const Divider(color: AppColors.border, height: 1),
                        itemBuilder: (context, index) {
                          final cliente = filtrados[index];
                          return Padding(
                            padding: AppSpacing.vS,
                            child: pantallaPequena
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: AppColors.grey50,
                                              borderRadius: AppRadius.allM,
                                            ),
                                            child: const Icon(Icons.person_outline, color: AppColors.textPrimary, size: 22),
                                          ),
                                          AppLayout.hM,
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(cliente.nombre, style: AppTypography.h3),
                                                Text('RNC/Cédula: ${cliente.rncCedula} | Tel: ${cliente.telefono}', style: AppTypography.bodySmall),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      AppLayout.vXs,
                                      Text(cliente.correo, style: AppTypography.bodyMedium),
                                      Text(cliente.direccion, style: AppTypography.bodySmall, overflow: TextOverflow.ellipsis),
                                      AppLayout.vS,
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.history, color: AppColors.grey600, size: 20),
                                            tooltip: 'Ver Historial e Info',
                                            onPressed: () => _mostrarDetallesCliente(context, cliente),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                                            tooltip: 'Editar Cliente',
                                            onPressed: () => _mostrarModalRegistro(context, clienteToEdit: cliente),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                            tooltip: 'Eliminar Cliente',
                                            onPressed: () {
                                              showDialog<void>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text('Confirmar Eliminación', style: AppTypography.h3),
                                                  content: Text('¿Está seguro de eliminar al cliente "${cliente.nombre}"?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(ctx),
                                                      child: const Text('Cancelar', style: AppTypography.bodyMedium),
                                                    ),
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: AppColors.white),
                                                      onPressed: () {
                                                        if (cliente.id != null) {
                                                          ref.read(clienteCompletoControllerProvider.notifier).eliminar(cliente.id!);
                                                        }
                                                        Navigator.pop(ctx);
                                                      },
                                                      child: const Text('Eliminar'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.grey50,
                                          borderRadius: AppRadius.allM,
                                        ),
                                        child: const Icon(Icons.person_outline, color: AppColors.textPrimary, size: 22),
                                      ),
                                      AppLayout.hM,
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(cliente.nombre, style: AppTypography.h3),
                                            Text('RNC/Cédula: ${cliente.rncCedula} | Tel: ${cliente.telefono}', style: AppTypography.bodySmall),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(cliente.correo, style: AppTypography.bodyMedium),
                                            Text(cliente.direccion, style: AppTypography.bodySmall, overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.history, color: AppColors.grey600, size: 20),
                                            tooltip: 'Ver Historial e Info',
                                            onPressed: () => _mostrarDetallesCliente(context, cliente),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                                            tooltip: 'Editar Cliente',
                                            onPressed: () => _mostrarModalRegistro(context, clienteToEdit: cliente),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                            tooltip: 'Eliminar Cliente',
                                            onPressed: () {
                                              showDialog<void>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text('Confirmar Eliminación', style: AppTypography.h3),
                                                  content: Text('¿Está seguro de eliminar al cliente "${cliente.nombre}"?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(ctx),
                                                      child: const Text('Cancelar', style: AppTypography.bodyMedium),
                                                    ),
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: AppColors.white),
                                                      onPressed: () {
                                                        if (cliente.id != null) {
                                                          ref.read(clienteCompletoControllerProvider.notifier).eliminar(cliente.id!);
                                                        }
                                                        Navigator.pop(ctx);
                                                      },
                                                      child: const Text('Eliminar'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Center(child: Text('Error: $e', style: AppTypography.bodyMedium)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetallesCliente(BuildContext context, ClienteCompleto cliente) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Historial y Detalles: ${cliente.nombre}', style: AppTypography.h3),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RNC / Cédula: ${cliente.rncCedula}', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              AppLayout.vXs,
              Text('Teléfono: ${cliente.telefono}', style: AppTypography.bodyMedium),
              Text('Correo: ${cliente.correo}', style: AppTypography.bodyMedium),
              Text('Dirección: ${cliente.direccion}', style: AppTypography.bodyMedium),
              AppLayout.vM,
              const Text('Observaciones:', style: AppTypography.h4),
              Text(cliente.observaciones.isEmpty ? 'Ninguna' : cliente.observaciones, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
              AppLayout.vM,
              const Text('Historial de Transacciones / Eventos:', style: AppTypography.h4),
              Container(
                padding: AppSpacing.allM,
                decoration: BoxDecoration(color: AppColors.grey50, borderRadius: AppRadius.allM),
                child: Text(cliente.historial, style: AppTypography.bodySmall),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.textPrimary, foregroundColor: AppColors.white),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarModalRegistro(BuildContext context, {ClienteCompleto? clienteToEdit}) {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: clienteToEdit?.nombre ?? '');
    final direccionController = TextEditingController(text: clienteToEdit?.direccion ?? '');
    final telefonoController = TextEditingController(text: clienteToEdit?.telefono ?? '');
    final correoController = TextEditingController(text: clienteToEdit?.correo ?? '');
    final rncCedulaController = TextEditingController(text: clienteToEdit?.rncCedula ?? '');
    final observacionesController = TextEditingController(text: clienteToEdit?.observaciones ?? '');
    final isEditing = clienteToEdit != null;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar Cliente' : 'Nuevo Cliente', style: AppTypography.h3),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre / Razón Social'),
                    validator: (v) => v == null || v.isEmpty ? 'Ingrese el nombre' : null,
                  ),
                  AppLayout.vM,
                  TextFormField(
                    controller: rncCedulaController,
                    decoration: const InputDecoration(labelText: 'RNC o Cédula'),
                    validator: (v) => v == null || v.isEmpty ? 'Ingrese el RNC o Cédula' : null,
                  ),
                  AppLayout.vM,
                  TextFormField(
                    controller: telefonoController,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                    validator: (v) => v == null || v.isEmpty ? 'Ingrese el teléfono' : null,
                  ),
                  AppLayout.vM,
                  TextFormField(
                    controller: correoController,
                    decoration: const InputDecoration(labelText: 'Correo Electrónico'),
                    validator: (v) => v == null || v.isEmpty ? 'Ingrese el correo' : null,
                  ),
                  AppLayout.vM,
                  TextFormField(
                    controller: direccionController,
                    decoration: const InputDecoration(labelText: 'Dirección'),
                    validator: (v) => v == null || v.isEmpty ? 'Ingrese la dirección' : null,
                  ),
                  AppLayout.vM,
                  TextFormField(
                    controller: observacionesController,
                    decoration: const InputDecoration(labelText: 'Observaciones'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.textPrimary, foregroundColor: AppColors.white),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                try {
                  final cli = ClienteCompleto(
                    id: clienteToEdit?.id,
                    nombre: nombreController.text.trim(),
                    direccion: direccionController.text.trim(),
                    telefono: telefonoController.text.trim(),
                    correo: correoController.text.trim(),
                    rncCedula: rncCedulaController.text.trim(),
                    observaciones: observacionesController.text.trim(),
                    historial: clienteToEdit?.historial ?? 'Cliente registrado en el sistema.',
                  );
                  if (isEditing) {
                    ref.read(clienteCompletoControllerProvider.notifier).actualizar(cli);
                  } else {
                    ref.read(clienteCompletoControllerProvider.notifier).guardar(cli);
                  }
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: Text(isEditing ? 'Actualizar' : 'Guardar'),
          ),
        ],
      ),
    );
  }
}
