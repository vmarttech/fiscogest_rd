import 'package:fiscogest_rd/features/import_export/data/services/import_export_service.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';

abstract class IImportExportService {
  Future<String> exportarProductos(List<Map<String, dynamic>> productos);
  Future<String> exportarClientes(List<Map<String, dynamic>> clientes);
  Future<String> exportarProveedores(List<Map<String, dynamic>> proveedores);
  Future<int> importarProductosDesdeCSV(
    String contenidoCsv, {
    Future<void> Function(Producto producto)? onProductoValido,
  });
  List<ImportExportLog> get registroErrores;
  void limpiarErrores();
}
