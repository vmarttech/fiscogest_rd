import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/features/clientes/presentation/providers/cliente_completo_providers.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_completo.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';

class ClientesGestionPage extends ConsumerStatefulWidget {
  const ClientesGestionPage({super.key});
  static const String routeName = 'clientes-gestion';

  @override
  ConsumerState<ClientesGestionPage> createState() =>
      _ClientesGestionPageState();
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
    final isMobile = AppBreakpoints.isMobile(context);
    final clientesAsync = ref.watch(clienteCompletoControllerProvider);

    return AppScaffold(
      title: 'Cartera de Clientes',
      subtitle: 'Administración de datos personales, fiscales, direcciones e historial',
      actions: const [],
      body: SafeArea(
        bottom: true,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 16 : 24,
            isMobile ? 16 : 20,
            isMobile ? 16 : 24,
            16,
          ),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Administración de datos personales, fiscales, direcciones e historial.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            AppLayout.vM,
                            AppButton(
                              text: 'Nuevo Cliente',
                              icon: Icons.person_add,
                              onPressed: () => _irANuevoCliente(context),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Administración de datos personales, fiscales, direcciones e historial.',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            AppButton(
                              text: 'Nuevo Cliente',
                              icon: Icons.person_add,
                              onPressed: () => _irANuevoCliente(context),
                            ),
                          ],
                        ),
                  AppLayout.vM,
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
                          final filtrados = clientes.where((c) {
                            return c.nombre.toLowerCase().contains(_filtroBusqueda) ||
                                c.rncCedula.toLowerCase().contains(_filtroBusqueda) ||
                                c.telefono.toLowerCase().contains(_filtroBusqueda) ||
                                c.correo.toLowerCase().contains(_filtroBusqueda);
                          }).toList();

                          if (filtrados.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: AppSpacing.allL,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.people_outline, size: 48, color: AppColors.grey300),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No hay clientes registrados o coincidentes.',
                                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: AppSpacing.allM,
                            itemCount: filtrados.length,
                            separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
                            itemBuilder: (_, index) {
                              final cliente = filtrados[index];
                              return Padding(
                                padding: AppSpacing.vS,
                                child: isMobile
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
                                                    Text(
                                                      'RNC/Cédula: ${cliente.rncCedula} | Tel: ${cliente.telefono}',
                                                      style: AppTypography.bodySmall,
                                                    ),
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
                                                onPressed: () => _irAEditarCliente(context, cliente),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                                tooltip: 'Eliminar Cliente',
                                                onPressed: () => _confirmarEliminar(context, cliente),
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
                                                Text(
                                                  'RNC/Cédula: ${cliente.rncCedula} | Tel: ${cliente.telefono}',
                                                  style: AppTypography.bodySmall,
                                                ),
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
                                                onPressed: () => _irAEditarCliente(context, cliente),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                                tooltip: 'Eliminar Cliente',
                                                onPressed: () => _confirmarEliminar(context, cliente),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        error: (e, _) => Center(
                          child: Text('Error: $e', style: AppTypography.bodyMedium.copyWith(color: AppColors.error)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Navegación en lugar de diálogo
  void _irANuevoCliente(BuildContext context) {
    context.pushNamed('nuevo-cliente');
  }

  void _irAEditarCliente(BuildContext context, ClienteCompleto cliente) {
    context.pushNamed('editar-cliente', extra: cliente);
  }

  void _mostrarDetallesCliente(BuildContext context, ClienteCompleto cliente) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
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
              Text(
                cliente.observaciones.isEmpty ? 'Ninguna' : cliente.observaciones,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
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
          AppButton(text: 'Cerrar', onPressed: () => Navigator.pop(ctx)),
        ],
      ),
    );
  }

  void _confirmarEliminar(BuildContext context, ClienteCompleto cliente) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación', style: AppTypography.h3),
        content: Text('¿Está seguro de eliminar al cliente "${cliente.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: AppTypography.bodyMedium)),
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
  }
}
