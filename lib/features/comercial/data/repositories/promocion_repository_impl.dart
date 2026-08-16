import 'package:fiscogest_rd/features/comercial/domain/entities/promocion.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/promocion_repository.dart';
import 'package:fiscogest_rd/features/comercial/data/datasources/promocion_datasource.dart';

class PromocionRepositoryImpl implements PromocionRepository {

  PromocionRepositoryImpl(this._datasource);
  final PromocionDatasource _datasource;

  @override
  Future<List<Promocion>> obtenerTodas() async {
    final registros = await _datasource.listarTodos();
    return registros.map((Map<String, dynamic> modelo) {
      return Promocion(
        id: modelo['id'] as String,
        nombre: modelo['nombre'] as String,
        descripcion: modelo['descripcion'] as String,
        tipo: modelo['tipo'] as String,
        valor: modelo['valor'] as double,
        fechaInicio: _parsearFecha(modelo['fechaInicio']),
        fechaFin: _parsearFecha(modelo['fechaFin']),
        activa: modelo['activa'] as bool,
      );
    }).toList();
  }

  @override
  Future<Promocion?> obtenerPorId(String id) async {
    final modelo = await _datasource.buscarPorId(id);
    if (modelo == null) return null;
    return Promocion(
      id: modelo['id'] as String,
      nombre: modelo['nombre'] as String,
      descripcion: modelo['descripcion'] as String,
      tipo: modelo['tipo'] as String,
      valor: modelo['valor'] as double,
      fechaInicio: _parsearFecha(modelo['fechaInicio']),
      fechaFin: _parsearFecha(modelo['fechaFin']),
      activa: modelo['activa'] as bool,
    );
  }

  @override
  Future<void> crear(Promocion promocion) async {
    await _datasource.registrar(promocion);
  }

  @override
  Future<void> actualizar(Promocion promocion) async {
    await _datasource.modificar(promocion);
  }

  @override
  Future<void> eliminar(String id) async {
    await _datasource.eliminar(id);
  }

  @override
  Future<List<Promocion>> obtenerActivas() async {
    final registros = await _datasource.listarActivas();
    return registros.map((Map<String, dynamic> modelo) {
      return Promocion(
        id: modelo['id'] as String,
        nombre: modelo['nombre'] as String,
        descripcion: modelo['descripcion'] as String,
        tipo: modelo['tipo'] as String,
        valor: modelo['valor'] as double,
        fechaInicio: _parsearFecha(modelo['fechaInicio']),
        fechaFin: _parsearFecha(modelo['fechaFin']),
        activa: modelo['activa'] as bool,
      );
    }).toList();
  }

  static DateTime? _parsearFecha(Object? valor) {
    if (valor == null) return null;
    if (valor is String && valor.isNotEmpty) {
      return DateTime.tryParse(valor);
    }
    return null;
  }
}
