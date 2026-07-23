import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/import_export_service.dart';

final importExportServiceProvider = Provider<ImportExportService>((ref) {
  return ImportExportService();
});

class ImportExportNotifier extends StateNotifier<AsyncValue<String>> {
  final ImportExportService _service;

  ImportExportNotifier(this._service) : super(const AsyncValue.data('Módulo listo para procesar datos.'));

  List<ImportExportLog> get errores => _service.registroErrores;

  Future<void> importarProductosSimulado(String csvData) async {
    state = const AsyncValue.loading();
    try {
      final total = await _service.importarProductosDesdeCSV(csvData);
      state = AsyncValue.data('Importación completada con éxito. Registros procesados: $total.');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String> exportarDatosEntidad(String tipo) async {
    if (tipo == 'productos') {
      return await _service.exportarProductos([
        {'id': 1, 'codigo': 'PRD-001', 'nombre': 'Café Premium 1lb', 'precio': 450.00, 'stock': 25, 'itbis': 18.0},
        {'id': 2, 'codigo': 'PRD-002', 'nombre': 'Azúcar Refinada 5lbs', 'precio': 180.00, 'stock': 50, 'itbis': 18.0},
      ]);
    } else if (tipo == 'clientes') {
      return await _service.exportarClientes([
        {'id': 1, 'nombre': 'Inversiones CM, SRL', 'rncCedula': '130-99887-1', 'telefono': '809-222-3344', 'correo': 'ventas@inversionescm.do', 'direccion': 'Piantini, Sto. Dgo.'},
      ]);
    } else {
      return await _service.exportarProveedores([
        {'id': 1, 'nombre': 'Distribuidora Global, S.A.', 'rnc': '101-23456-7', 'contacto': 'Juan Pérez', 'telefono': '809-555-1234', 'correo': 'contacto@distribuidoraglobal.do', 'direccion': 'Av. Kennedy'},
      ]);
    }
  }
}

final importExportControllerProvider = StateNotifierProvider<ImportExportNotifier, AsyncValue<String>>((ref) {
  final service = ref.watch(importExportServiceProvider);
  return ImportExportNotifier(service);
});
