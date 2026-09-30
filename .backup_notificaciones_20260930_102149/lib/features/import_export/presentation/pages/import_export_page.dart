import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/import_export/presentation/providers/import_export_providers.dart';
import 'package:fiscogest_rd/features/import_export/data/services/import_export_service.dart';

class ImportExportPage extends ConsumerWidget {
  const ImportExportPage({super.key});

  static const String routeName = 'importar-exportar';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);
    final estadoAsync = ref.watch(importExportControllerProvider);
    final controller = ref.read(importExportControllerProvider.notifier);

    return AppScaffold(
      title: 'IMPORTAR / EXPORTAR',
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              mobile ? 16 : 8,
              mobile ? 16 : 20,
              mobile ? 16 : 8,
              32,
            ),
            child: AppLayout.centerConstrained(
              maxWidth: desktop ? 1320 : (mobile ? 520 : 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _HubHero(
                    title: 'Centro de datos',
                    subtitle:
                        'Exporta catálogos a CSV e importa lotes de productos '
                        'con validación y registro de errores.',
                    icon: Icons.import_export_rounded,
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader(
                    title: 'Operaciones',
                    subtitle: 'Exportar e importar',
                  ),
                  const SizedBox(height: 8),
                  if (desktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ExportCard(
                            onProductos: () async {
                              final csv = await controller
                                  .exportarDatosEntidad('productos');
                              if (!context.mounted) return;
                              _mostrarResultadoExportacion(
                                context,
                                'Productos.csv',
                                csv,
                              );
                            },
                            onClientes: () async {
                              final csv = await controller
                                  .exportarDatosEntidad('clientes');
                              if (!context.mounted) return;
                              _mostrarResultadoExportacion(
                                context,
                                'Clientes.csv',
                                csv,
                              );
                            },
                            onProveedores: () async {
                              final csv = await controller
                                  .exportarDatosEntidad('proveedores');
                              if (!context.mounted) return;
                              _mostrarResultadoExportacion(
                                context,
                                'Proveedores.csv',
                                csv,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ImportCard(
                            estadoAsync: estadoAsync,
                            onSimular: () => _elegirYImportar(context, ref),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _ExportCard(
                      onProductos: () async {
                        final csv =
                            await controller.exportarDatosEntidad('productos');
                        if (!context.mounted) return;
                        _mostrarResultadoExportacion(
                          context,
                          'Productos.csv',
                          csv,
                        );
                      },
                      onClientes: () async {
                        final csv =
                            await controller.exportarDatosEntidad('clientes');
                        if (!context.mounted) return;
                        _mostrarResultadoExportacion(
                          context,
                          'Clientes.csv',
                          csv,
                        );
                      },
                      onProveedores: () async {
                        final csv = await controller
                            .exportarDatosEntidad('proveedores');
                        if (!context.mounted) return;
                        _mostrarResultadoExportacion(
                          context,
                          'Proveedores.csv',
                          csv,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _ImportCard(
                      estadoAsync: estadoAsync,
                      onSimular: () => _elegirYImportar(context, ref),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const SectionHeader(
                    title: 'Registro de errores',
                    subtitle: 'Última importación',
                  ),
                  const SizedBox(height: 8),
                  _ErroresPanel(errores: controller.errores),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _elegirYImportar(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = ref.read(importExportControllerProvider.notifier);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.single;
    final String csv;
    if (f.bytes != null) {
      csv = utf8.decode(f.bytes!);
    } else if (f.path != null) {
      csv = await File(f.path!).readAsString();
    } else {
      return;
    }
    await controller.importarProductosDesdeCsv(csv);
  }

  void _mostrarResultadoExportacion(
    BuildContext context,
    String tituloArchivo,
    String contenido,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allL),
        title: Text(
          'Exportación: $tituloArchivo',
          style: AppTypography.h4.copyWith(fontWeight: FontWeight.w700),
        ),
        content: SizedBox(
          width: 520,
          height: 280,
          child: SingleChildScrollView(
            child: SelectableText(
              contenido,
              style: AppTypography.bodySmall.copyWith(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class _HubHero extends StatelessWidget {
  const _HubHero({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.primaryLight.withValues(alpha: 0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h4.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportCard extends StatelessWidget {
  const _ExportCard({
    required this.onProductos,
    required this.onClientes,
    required this.onProveedores,
  });

  final VoidCallback onProductos;
  final VoidCallback onClientes;
  final VoidCallback onProveedores;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_download_outlined,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Exportar',
                style: AppTypography.labelLarge
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Catálogos en CSV (compatible con Excel).',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onProductos,
            icon: const Icon(Icons.inventory_2_outlined, size: 18),
            label: const Text('Productos'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onClientes,
            icon: const Icon(Icons.people_outline, size: 18),
            label: const Text('Clientes'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onProveedores,
            icon: const Icon(Icons.business_outlined, size: 18),
            label: const Text('Proveedores'),
          ),
        ],
      ),
    );
  }
}

class _ImportCard extends StatelessWidget {
  const _ImportCard({
    required this.estadoAsync,
    required this.onSimular,
  });

  final AsyncValue<String> estadoAsync;
  final VoidCallback onSimular;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_upload_outlined,
                  color: AppColors.info, size: 22),
              const SizedBox(width: 10),
              Text(
                'Importar productos',
                style: AppTypography.labelLarge
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'CSV con validación de código, precio y stock. '
            'Selecciona un archivo .csv del equipo.',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onSimular,
            icon: const Icon(Icons.upload_file, size: 18),
            label: const Text('Elegir archivo CSV'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          estadoAsync.when(
            data: (msg) => Text(
              msg,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
            loading: () => const LinearProgressIndicator(
              color: AppColors.primary,
              minHeight: 3,
            ),
            error: (e, _) => Text(
              'Error: $e',
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErroresPanel extends StatelessWidget {
  const _ErroresPanel({required this.errores});

  final List<ImportExportLog> errores;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: errores.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 40, color: AppColors.grey300),
                  const SizedBox(height: 10),
                  Text(
                    'Sin errores en el último proceso.',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: errores.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, index) {
                final err = errores[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.error.withValues(alpha: 0.12),
                    child: const Icon(Icons.error_outline,
                        color: AppColors.error, size: 18),
                  ),
                  title: Text(
                    'Fila ${err.fila} · ${err.entidad}',
                    style: AppTypography.labelMedium
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    err.mensajeError,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.error),
                  ),
                );
              },
            ),
    );
  }
}
