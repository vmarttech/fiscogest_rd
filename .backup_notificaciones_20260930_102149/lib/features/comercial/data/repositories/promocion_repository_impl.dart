import 'package:fiscogest_rd/features/comercial/domain/entities/promocion.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_promocion_repository.dart';
import 'package:fiscogest_rd/features/comercial/data/datasources/promocion_datasource.dart';

class PromocionRepositoryImpl implements IPromocionRepository {
  PromocionRepositoryImpl(this._datasource);
  final PromocionDatasource _datasource;
  @override
  Future<Promocion> crear(Promocion promocion) async {
    await _datasource.registrar(promocion);
    return promocion;
  }

  @override
  Future<Promocion?> obtenerPorId(int id) async {
    final modelo = await _datasource.buscarPorId(id);
    if (modelo == null) return null;
    return _deserializar(modelo);
  }

  @override
  Future<List<Promocion>> listarTodas() async {
    final registros = await _datasource.listarTodos();
    return registros.map((m) => _deserializar(m)).toList();
  }

  @override
  Future<List<Promocion>> listarActivas(DateTime fechaReferencia) async {
    final registros = await _datasource.listarActivas();
    return registros
        .map((m) => _deserializar(m))
        .where((p) => p.estaVigente(fechaReferencia))
        .toList();
  }

  @override
  Future<Promocion> actualizar(Promocion promocion) async {
    await _datasource.modificar(promocion);
    return promocion;
  }

  @override
  Future<void> eliminar(int id) async {
    await _datasource.eliminar(id);
  }

  static Promocion _deserializar(Map<String, dynamic> modelo) {
    return Promocion(
      id: modelo['id'] as int,
      nombre: modelo['nombre'] as String,
      descripcion: modelo['descripcion'] as String,
      tipo: modelo['tipo'] as String,
      valor: modelo['valor'] as double,
      fechaInicio: _parsearFecha(modelo['fechaInicio']),
      fechaFin: _parsearFecha(modelo['fechaFin']),
      activa: modelo['activa'] as bool,
      minimoCantidad: modelo['minimoCantidad'] as int?,
      minimoMonto: modelo['minimoMonto'] as double?,
    );
  }

  static DateTime? _parsearFecha(Object? valor) {
    if (valor == null) return null;
    if (valor is String && valor.isNotEmpty) {
      return DateTime.tryParse(valor);
    }
    return null;
  }
}
