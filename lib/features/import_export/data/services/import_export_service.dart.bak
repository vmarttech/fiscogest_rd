
class ImportExportLog {

  const ImportExportLog({
    required this.fila,
    required this.entidad,
    required this.mensajeError,
  });
  final int fila;
  final String entidad;
  final String mensajeError;
}

class ImportExportService {
  final List<ImportExportLog> _registroErrores = [];

  List<ImportExportLog> get registroErrores => List.unmodifiable(_registroErrores);

  void limpiarErrores() {
    _registroErrores.clear();
  }

  // Simulación de exportación de productos a formato CSV / Excel compatible
  Future<String> exportarProductos(List<Map<String, dynamic>> productos) async {
    final buffer = StringBuffer();
    buffer.writeln('ID,Codigo,Nombre,Precio,Stock,ITBIS');
    for (var p in productos) {
      buffer.writeln('${p['id']},${p['codigo']},"${p['nombre']}",${p['precio']},${p['stock']},${p['itbis']}');
    }
    return buffer.toString();
  }

  // Simulación de exportación de clientes
  Future<String> exportarClientes(List<Map<String, dynamic>> clientes) async {
    final buffer = StringBuffer();
    buffer.writeln('ID,Nombre,RNC_Cedula,Telefono,Correo,Direccion');
    for (var c in clientes) {
      buffer.writeln('${c['id']},"${c['nombre']}","${c['rncCedula']}","${c['telefono']}","${c['correo']}","${c['direccion']}"');
    }
    return buffer.toString();
  }

  // Simulación de exportación de proveedores
  Future<String> exportarProveedores(List<Map<String, dynamic>> proveedores) async {
    final buffer = StringBuffer();
    buffer.writeln('ID,Nombre,RNC,Contacto,Telefono,Correo,Direccion');
    for (var p in proveedores) {
      buffer.writeln('${p['id']},"${p['nombre']}","${p['rnc']}","${p['contacto']}","${p['telefono']}","${p['correo']}","${p['direccion']}"');
    }
    return buffer.toString();
  }

  // Importación masiva de productos con validaciones y captura de errores por fila
  Future<int> importarProductosDesdeCSV(String contenidoCsv) async {
    limpiarErrores();
    final lineas = contenidoCsv.split('\n');
    int importadosExitosamente = 0;

    for (int i = 1; i < lineas.length; i++) {
      final linea = lineas[i].trim();
      if (linea.isEmpty) continue;

      final columnas = linea.split(',');
      if (columnas.length < 5) {
        _registroErrores.add(ImportExportLog(
          fila: i + 1,
          entidad: 'Producto',
          mensajeError: 'Estructura de columnas incompleta o formato inválido.',
        ));
        continue;
      }

      final codigo = columnas[0].trim();
      final nombre = columnas[1].trim();
      final precio = double.tryParse(columnas[2].trim());
      final stock = int.tryParse(columnas[3].trim());

      // Validaciones estrictas de negocio
      if (codigo.isEmpty) {
        _registroErrores.add(ImportExportLog(fila: i + 1, entidad: 'Producto', mensajeError: 'El código del producto es obligatorio.'));
        continue;
      }
      if (nombre.isEmpty) {
        _registroErrores.add(ImportExportLog(fila: i + 1, entidad: 'Producto', mensajeError: 'El nombre del producto es obligatorio.'));
        continue;
      }
      if (precio == null || precio < 0) {
        _registroErrores.add(ImportExportLog(fila: i + 1, entidad: 'Producto', mensajeError: 'Precio inválido o negativo.'));
        continue;
      }
      if (stock == null || stock < 0) {
        _registroErrores.add(ImportExportLog(fila: i + 1, entidad: 'Producto', mensajeError: 'Stock inválido o negativo.'));
        continue;
      }

      importadosExitosamente++;
    }

    return importadosExitosamente;
  }
}
