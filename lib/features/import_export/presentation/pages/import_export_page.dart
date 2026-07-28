import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/import_export/presentation/providers/import_export_providers.dart';

class ImportExportPage extends ConsumerWidget {
  const ImportExportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primaryColor = Color(0xFF0F172A);
    const surfaceColor = Colors.white;
    const backgroundColor = Color(0xFFF4F6F9);
    const borderColor = Color(0xFFE2E8F0);
    const textColor = Color(0xFF1E293B);
    const subtitleColor = Color(0xFF64748B);

    final estadoAsync = ref.watch(importExportControllerProvider);
    final controller = ref.read(importExportControllerProvider.notifier);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Centro de Importación y Exportación',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 4),
              const Text(
                'Gestión masiva de inventarios, carteras de clientes, proveedores y auditoría de errores.',
                style: TextStyle(fontSize: 13, color: subtitleColor),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _CardAccion(
                      titulo: 'Exportar Información',
                      descripcion: 'Extraiga catálogos completos en formato CSV estándar.',
                      icono: Icons.cloud_download_outlined,
                      botones: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                          onPressed: () async {
                            final csv = await controller.exportarDatosEntidad('productos');
                            if (!context.mounted) return;
                            _mostrarResultadoExportacion(context, 'Productos.csv', csv);
                          },
                          icon: const Icon(Icons.inventory_2_outlined, size: 16),
                          label: const Text('Exportar Productos'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                          onPressed: () async {
                            final csv = await controller.exportarDatosEntidad('clientes');
                            if (!context.mounted) return;
                            _mostrarResultadoExportacion(context, 'Clientes.csv', csv);
                          },
                          icon: const Icon(Icons.people_outline, size: 16),
                          label: const Text('Exportar Clientes'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                          onPressed: () async {
                            final csv = await controller.exportarDatosEntidad('proveedores');
                            if (!context.mounted) return;
                            _mostrarResultadoExportacion(context, 'Proveedores.csv', csv);
                          },
                          icon: const Icon(Icons.business_outlined, size: 16),
                          label: const Text('Exportar Proveedores'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _CardAccion(
                      titulo: 'Importar Productos (Excel / CSV)',
                      descripcion: 'Cargue lotes masivos con validación tributaria y de stock.',
                      icono: Icons.cloud_upload_outlined,
                      botones: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0369A1), foregroundColor: Colors.white),
                          onPressed: () {
                            const csvEjemplo = 'Codigo,Nombre,Precio,Stock,ITBIS\nPRD-100,Teclado Mecánico RGB,1800.0,15,18.0\n,Producto Sin Codigo,-50.0,-5,18.0';
                            controller.importarProductosSimulado(csvEjemplo);
                          },
                          icon: const Icon(Icons.upload_file, size: 16),
                          label: const Text('Cargar Archivo de Prueba (Simulación)'),
                        ),
                        const SizedBox(height: 12),
                        estadoAsync.when(
                          data: (msg) => Text(msg, style: const TextStyle(color: Color(0xFF16A34A), fontSize: 13, fontWeight: FontWeight.w600)),
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Registro de Errores e Incidencias en Importación',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: controller.errores.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay errores registrados en el último proceso de importación.',
                            style: TextStyle(color: subtitleColor, fontSize: 13),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: controller.errores.length,
                          separatorBuilder: (context, index) => const Divider(color: borderColor, height: 1),
                          itemBuilder: (context, index) {
                            final err = controller.errores[index];
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFFEE2E2),
                                child: Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                              ),
                              title: Text('Fila ${err.fila} - Entidad: ${err.entidad}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text(err.mensajeError, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12)),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarResultadoExportacion(BuildContext context, String tituloArchivo, String contenido) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exportación Exitosa: $tituloArchivo', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SizedBox(
          width: 500,
          height: 250,
          child: SingleChildScrollView(
            child: SelectableText(
              contenido,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class _CardAccion extends StatelessWidget {

  const _CardAccion({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.botones,
  });
  final String titulo;
  final String descripcion;
  final IconData icono;
  final List<Widget> botones;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: const Color(0xFF0F172A), size: 24),
              const SizedBox(width: 12),
              Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 8),
          Text(descripcion, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(height: 20),
          ...botones,
        ],
      ),
    );
  }
}
