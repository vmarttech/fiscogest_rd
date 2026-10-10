import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
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
              maxWidth: desktop ? 920 : (mobile ? 520 : 720),
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
                            onRespaldar: () => _crearRespaldo(context, ref),
                            onProductos: () async {
                              final csv = await controller.exportarDatosEntidad(
                                'productos',
                              );
                              if (!context.mounted) return;
                              await _mostrarResultadoExportacion(
                                context,
                                'Productos.csv',
                                csv,
                              );
                            },
                            onClientes: () async {
                              final csv = await controller.exportarDatosEntidad(
                                'clientes',
                              );
                              if (!context.mounted) return;
                              await _mostrarResultadoExportacion(
                                context,
                                'Clientes.csv',
                                csv,
                              );
                            },
                            onProveedores: () async {
                              final csv = await controller.exportarDatosEntidad(
                                'proveedores',
                              );
                              if (!context.mounted) return;
                              await _mostrarResultadoExportacion(
                                context,
                                'Proveedores.csv',
                                csv,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
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
                      onRespaldar: () => _crearRespaldo(context, ref),
                      onProductos: () async {
                        final csv = await controller.exportarDatosEntidad(
                          'productos',
                        );
                        if (!context.mounted) return;
                        await _mostrarResultadoExportacion(
                          context,
                          'Productos.csv',
                          csv,
                        );
                      },
                      onClientes: () async {
                        final csv = await controller.exportarDatosEntidad(
                          'clientes',
                        );
                        if (!context.mounted) return;
                        await _mostrarResultadoExportacion(
                          context,
                          'Clientes.csv',
                          csv,
                        );
                      },
                      onProveedores: () async {
                        final csv = await controller.exportarDatosEntidad(
                          'proveedores',
                        );
                        if (!context.mounted) return;
                        await _mostrarResultadoExportacion(
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

  Future<void> _crearRespaldo(BuildContext context, WidgetRef ref) async {
    final marcaTiempo = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final ruta = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar respaldo completo de FiscoGest',
      fileName: 'FiscoGest_RD_respaldo_$marcaTiempo.sqlite',
      type: FileType.custom,
      allowedExtensions: const ['sqlite'],
    );
    if (ruta == null) return;

    try {
      final db = ref.read(databaseProvider);
      await db.customStatement('VACUUM INTO ?', [ruta]);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Respaldo guardado en $ruta'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo crear el respaldo: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _elegirYImportar(BuildContext context, WidgetRef ref) async {
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

  Future<void> _mostrarResultadoExportacion(
    BuildContext context,
    String tituloArchivo,
    String contenido,
  ) async {
    if (contenido.trim().isEmpty ||
        contenido.trim().split('\n').length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No hay datos para exportar (lista vacía o no cargada)',
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final bytes = utf8.encode(contenido);

    // Guardar archivo
    final ruta = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar $tituloArchivo',
      fileName: tituloArchivo,
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      bytes: bytes,
    );
    if (ruta != null && ruta.isNotEmpty) {
      final dest = File(ruta.endsWith('.csv') ? ruta : '$ruta.csv');
      await dest.writeAsBytes(bytes, flush: true);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV guardado: ${dest.path}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Compartir si canceló o no hay saveFile
    final tmpDir = await getTemporaryDirectory();
    final tmp = File(p.join(tmpDir.path, tituloArchivo));
    await tmp.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [XFile(tmp.path, mimeType: 'text/csv', name: tituloArchivo)],
      subject: tituloArchivo,
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
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.primaryLight.withValues(alpha: 0.88),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h4.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
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
    required this.onRespaldar,
    required this.onProductos,
    required this.onClientes,
    required this.onProveedores,
  });

  final VoidCallback onRespaldar;
  final VoidCallback onProductos;
  final VoidCallback onClientes;
  final VoidCallback onProveedores;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera con acento
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.primary.withValues(alpha: 0.02),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.cloud_download_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exportar',
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Respaldo y catálogos CSV',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Crea un respaldo completo o exporta catálogos CSV para Excel.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onRespaldar,
                  icon: const Icon(Icons.backup_outlined, size: 18),
                  label: const Text('Respaldo completo'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: onProductos,
                  icon: const Icon(Icons.inventory_2_outlined, size: 18),
                  label: const Text('Productos'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onClientes,
                  icon: const Icon(Icons.people_outline, size: 18),
                  label: const Text('Clientes'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onProveedores,
                  icon: const Icon(Icons.business_outlined, size: 18),
                  label: const Text('Proveedores'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

class _ImportCard extends StatelessWidget {
  const _ImportCard({required this.estadoAsync, required this.onSimular});

  final AsyncValue<String> estadoAsync;
  final VoidCallback onSimular;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              gradient: LinearGradient(
                colors: [
                  AppColors.info.withValues(alpha: 0.10),
                  AppColors.info.withValues(alpha: 0.02),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.cloud_upload_outlined,
                    color: AppColors.info,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Importar productos',
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'CSV con validación',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Validación de código, precio y stock. '
                  'Selecciona un archivo .csv del equipo.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                // Zona drop visual
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.25),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.upload_file_rounded,
                        size: 36,
                        color: AppColors.info.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Archivo CSV de productos',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: onSimular,
                        icon: const Icon(Icons.folder_open, size: 18),
                        label: const Text('Elegir archivo CSV'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.info,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                estadoAsync.when(
                  data: (msg) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            msg,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  loading: () => const LinearProgressIndicator(
                    color: AppColors.primary,
                    minHeight: 3,
                  ),
                  error: (e, _) => Text(
                    'Error: $e',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
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
                  const Icon(
                    Icons.check_circle_outline,
                    size: 40,
                    color: AppColors.grey300,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sin errores en el último proceso.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
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
                    child: const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    'Fila ${err.fila} · ${err.entidad}',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    err.mensajeError,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
