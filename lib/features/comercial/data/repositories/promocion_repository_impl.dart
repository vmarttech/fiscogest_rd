import 'package:fiscogest_rd/features/comercial/data/datasources/promocion_datasource.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/promocion.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_promocion_repository.dart';

class PromocionRepositoryImpl implements IPromocionRepository {
  PromocionRepositoryImpl(this._datasource);

  final PromocionDatasource _datasource;

  @override
  Future<Promocion> crear(Promocion promocion) async {
    final id = await _datasource.registrar(promocion);
    return Promocion(
      id: id,
      nombre: promocion.nombre,
      descripcion: promocion.descripcion,
      tipo: promocion.tipo,
      valor: promocion.valor,
      fechaInicio: promocion.fechaInicio,
      fechaFin: promocion.fechaFin,
      activa: promocion.activa,
      minimoCantidad: promocion.minimoCantidad,
      minimoMonto: promocion.minimoMonto,
    );
  }

  @override
  Future<Promocion?> obtenerPorId(int id) async {
    final modelo = await _datasource.buscarPorId(id);
    return modelo == null ? null : _deserializar(modelo);
  }

  @override
  Future<List<Promocion>> listarTodas() async {
    final registros = await _datasource.listarTodos();
    return registros.map(_deserializar).toList();
  }

  @override
  Future<List<Promocion>> listarActivas(DateTime fechaReferencia) async {
    final registros = await _datasource.listarActivas();
    return registros
        .map(_deserializar)
        .where((promocion) => promocion.estaVigente(fechaReferencia))
        .toList();
  }

  @override
  Future<Promocion> actualizar(Promocion promocion) async {
    final actualizado = await _datasource.modificar(promocion);
    if (!actualizado) {
      throw StateError('No existe la promoción ${promocion.id}.');
    }
    return promocion;
  }

  @override
  Future<void> eliminar(int id) => _datasource.eliminar(id);

  static Promocion _deserializar(Map<String, dynamic> modelo) {
    return Promocion(
      id: modelo['id'] as int,
      nombre: modelo['nombre'] as String,
      descripcion: modelo['descripcion'] as String,
      tipo: modelo['tipo'] as String,
      valor: (modelo['valor'] as num).toDouble(),
      fechaInicio: _parsearFecha(modelo['fechaInicio']),
      fechaFin: _parsearFecha(modelo['fechaFin']),
      activa: (modelo['activa'] as num) != 0,
      minimoCantidad: modelo['minimoCantidad'] as int?,
      minimoMonto: (modelo['minimoMonto'] as num?)?.toDouble(),
    );
  }

  static DateTime? _parsearFecha(Object? valor) {
    if (valor is DateTime) return valor;
    if (valor is String && valor.isNotEmpty) {
      return DateTime.tryParse(valor);
    }
    return null;
  }
}
