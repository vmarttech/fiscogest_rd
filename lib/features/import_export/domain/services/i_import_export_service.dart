import '../../data/services/import_export_service.dart';

abstract class IImportExportService {
  Future<String> exportarProductos(List<Map<String, dynamic>> productos);
  Future<String> exportarClientes(List<Map<String, dynamic>> clientes);
  Future<String> exportarProveedores(List<Map<String, dynamic>> proveedores);
  Future<int> importarProductosDesdeCSV(String contenidoCsv);
  List<ImportExportLog> get registroErrores;
  void limpiarErrores();
}
