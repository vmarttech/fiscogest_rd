import 'package:fiscogest_rd/features/comercial/domain/entities/promocion.dart';

class PromocionDatasource {
  final List<Map<String, dynamic>> _almacen = [];

  Future<List<Map<String, dynamic>>> listarTodos() async {
    return List.unmodifiable(_almacen);
  }

  Future<List<Map<String, dynamic>>> listarActivas() async {
    return _almacen.where((registro) => registro['activa'] == true).toList();
  }

  Future<Map<String, dynamic>?> buscarPorId(String id) async {
    final coinciden = _almacen.where((r) => r['id'] == id);
    return coinciden.isNotEmpty ? coinciden.first : null;
  }

  Future<void> registrar(Promocion entidad) async {
    _almacen.add({
      'id': entidad.id,
      'nombre': entidad.nombre,
      'descripcion': entidad.descripcion,
      'tipo': entidad.tipo,
      'valor': entidad.valor,
      'fechaInicio': entidad.fechaInicio?.toIso8601String(),
      'fechaFin': entidad.fechaFin?.toIso8601String(),
      'activa': entidad.activa,
    });
  }

  Future<void> modificar(Promocion entidad) async {
    final indice = _almacen.indexWhere((r) => r['id'] == entidad.id);
    if (indice >= 0) {
      _almacen[indice] = {
        'id': entidad.id,
        'nombre': entidad.nombre,
        'descripcion': entidad.descripcion,
        'tipo': entidad.tipo,
        'valor': entidad.valor,
        'fechaInicio': entidad.fechaInicio?.toIso8601String(),
        'fechaFin': entidad.fechaFin?.toIso8601String(),
        'activa': entidad.activa,
      };
    }
  }

  Future<void> eliminar(String id) async {
    _almacen.removeWhere((r) => r['id'] == id);
  }
}
