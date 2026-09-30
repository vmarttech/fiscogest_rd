import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/import_export/data/services/import_export_service.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_entity.dart';
import 'package:fiscogest_rd/features/clientes/presentation/providers/cliente_providers.dart';
import 'package:fiscogest_rd/features/proveedores/domain/entities/proveedor.dart';
import 'package:fiscogest_rd/features/proveedores/presentation/providers/proveedor_providers.dart';

final importExportServiceProvider = Provider<ImportExportService>((ref) {
  return ImportExportService();
});

class ImportExportNotifier extends StateNotifier<AsyncValue<String>> {
  ImportExportNotifier(this._ref, this._service)
    : super(const AsyncValue.data('Módulo listo para procesar datos.'));

  final Ref _ref;
  final ImportExportService _service;

  List<ImportExportLog> get errores => _service.registroErrores;

  Future<void> importarProductosDesdeCsv(String csvData) async {
    state = const AsyncValue.loading();
    try {
      final ctrl = _ref.read(productoControllerProvider.notifier);
      final total = await _service.importarProductosDesdeCSV(
        csvData,
        onProductoValido: (p) => ctrl.guardar(p),
      );
      await ctrl.cargarProductos();
      state = AsyncValue.data(
        total > 0
            ? 'Importación OK. Productos guardados: $total.'
            : 'Sin filas válidas. Revisa el registro de errores.',
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> importarProductosSimulado(String csvData) =>
      importarProductosDesdeCsv(csvData);

  Future<String> exportarDatosEntidad(String tipo) async {
    switch (tipo) {
      case 'productos':
        final list =
            _ref.read(productoControllerProvider).valueOrNull ?? <Producto>[];
        return _service.exportarProductos([
          for (final p in list)
            {
              'id': p.id,
              'codigo': p.codigo,
              'nombre': p.nombre,
              'precio': p.precioVenta,
              'stock': p.stock ?? 0,
              'itbis': 18.0,
            },
        ]);
      case 'clientes':
        final list =
            _ref.read(clientesControllerProvider).valueOrNull ??
            <ClienteEntity>[];
        return _service.exportarClientes([
          for (final c in list)
            {
              'id': c.id,
              'nombre': c.nombre,
              'rncCedula': c.rncCedula,
              'telefono': c.telefono,
              'correo': c.correo,
              'direccion': c.direccion,
            },
        ]);
      default:
        final list =
            _ref.read(proveedorControllerProvider).valueOrNull ?? <Proveedor>[];
        return _service.exportarProveedores([
          for (final p in list)
            {
              'id': p.id,
              'nombre': p.nombreEmpresa,
              'rnc': p.rnc ?? '',
              'contacto': p.nombreContacto ?? '',
              'telefono': p.telefono ?? '',
              'correo': p.email ?? '',
              'direccion': p.direccion ?? '',
            },
        ]);
    }
  }
}

final importExportControllerProvider =
    StateNotifierProvider<ImportExportNotifier, AsyncValue<String>>((ref) {
      return ImportExportNotifier(ref, ref.watch(importExportServiceProvider));
    });
