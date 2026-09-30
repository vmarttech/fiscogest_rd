import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';

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

  List<ImportExportLog> get registroErrores =>
      List.unmodifiable(_registroErrores);

  void limpiarErrores() => _registroErrores.clear();

  Future<String> exportarProductos(List<Map<String, dynamic>> productos) async {
    final buffer = StringBuffer();
    buffer.writeln('Codigo,Nombre,Precio,Stock,ITBIS');
    for (final p in productos) {
      final nombre = '${p['nombre']}'.replaceAll('"', '""');
      buffer.writeln(
        '${p['codigo']},"$nombre",${p['precio']},${p['stock']},${p['itbis']}',
      );
    }
    return buffer.toString();
  }

  Future<String> exportarClientes(List<Map<String, dynamic>> clientes) async {
    final buffer = StringBuffer();
    buffer.writeln('ID,Nombre,RNC_Cedula,Telefono,Correo,Direccion');
    for (final c in clientes) {
      buffer.writeln(
        '${c['id']},"${c['nombre']}","${c['rncCedula']}","${c['telefono']}","${c['correo']}","${c['direccion']}"',
      );
    }
    return buffer.toString();
  }

  Future<String> exportarProveedores(
    List<Map<String, dynamic>> proveedores,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln('ID,Nombre,RNC,Contacto,Telefono,Correo,Direccion');
    for (final p in proveedores) {
      buffer.writeln(
        '${p['id']},"${p['nombre']}","${p['rnc']}","${p['contacto']}","${p['telefono']}","${p['correo']}","${p['direccion']}"',
      );
    }
    return buffer.toString();
  }

  /// CSV: Codigo,Nombre,Precio,Stock,ITBIS (cabecera en fila 1)
  /// [onProductoValido] persiste cada fila OK (p. ej. controller.guardar).
  Future<int> importarProductosDesdeCSV(
    String contenidoCsv, {
    Future<void> Function(Producto producto)? onProductoValido,
    int categoriaIdDefault = 1,
    int marcaIdDefault = 1,
    int unidadMedidaIdDefault = 1,
  }) async {
    limpiarErrores();
    final lineas = contenidoCsv.replaceAll('\r\n', '\n').split('\n');
    var importados = 0;

    for (var i = 1; i < lineas.length; i++) {
      final linea = lineas[i].trim();
      if (linea.isEmpty) continue;

      final columnas = _splitCsvLine(linea);
      if (columnas.length < 4) {
        _registroErrores.add(
          ImportExportLog(
            fila: i + 1,
            entidad: 'Producto',
            mensajeError:
                'Estructura incompleta (min. Codigo,Nombre,Precio,Stock).',
          ),
        );
        continue;
      }

      final codigo = columnas[0].trim();
      final nombre = columnas[1].trim().replaceAll('"', '');
      final precio = double.tryParse(columnas[2].trim());
      final stock = double.tryParse(columnas[3].trim());

      if (codigo.isEmpty) {
        _registroErrores.add(
          ImportExportLog(
            fila: i + 1,
            entidad: 'Producto',
            mensajeError: 'El código es obligatorio.',
          ),
        );
        continue;
      }
      if (nombre.isEmpty) {
        _registroErrores.add(
          ImportExportLog(
            fila: i + 1,
            entidad: 'Producto',
            mensajeError: 'El nombre es obligatorio.',
          ),
        );
        continue;
      }
      if (precio == null || precio < 0) {
        _registroErrores.add(
          ImportExportLog(
            fila: i + 1,
            entidad: 'Producto',
            mensajeError: 'Precio inválido o negativo.',
          ),
        );
        continue;
      }
      if (stock == null || stock < 0) {
        _registroErrores.add(
          ImportExportLog(
            fila: i + 1,
            entidad: 'Producto',
            mensajeError: 'Stock inválido o negativo.',
          ),
        );
        continue;
      }

      final producto = Producto(
        codigo: codigo,
        nombre: nombre,
        precioCompra: precio,
        precioVenta: precio,
        stock: stock,
        categoriaId: categoriaIdDefault,
        marcaId: marcaIdDefault,
        unidadMedidaId: unidadMedidaIdDefault,
        activo: true,
      );

      try {
        if (onProductoValido != null) {
          await onProductoValido(producto);
        }
        importados++;
      } catch (e) {
        _registroErrores.add(
          ImportExportLog(
            fila: i + 1,
            entidad: 'Producto',
            mensajeError: 'No se pudo guardar: $e',
          ),
        );
      }
    }
    return importados;
  }

  List<String> _splitCsvLine(String line) {
    // Soporta campos entre comillas simples
    final out = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
        continue;
      }
      if (ch == ',' && !inQuotes) {
        out.add(buf.toString());
        buf.clear();
        continue;
      }
      buf.write(ch);
    }
    out.add(buf.toString());
    return out;
  }
}
