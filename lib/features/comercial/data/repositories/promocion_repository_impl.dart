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
      productoIds: promocion.productoIds,
      categoriaIds: promocion.categoriaIds,
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
    return Future.wait(registros.map(_deserializar));
  }

  @override
  Future<List<Promocion>> listarActivas(DateTime fechaReferencia) async {
    final registros = await _datasource.listarActivas();
    final promociones = await Future.wait(registros.map(_deserializar));
    return promociones.where((p) => p.estaVigente(fechaReferencia)).toList();
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

  Future<Promocion> _deserializar(Map<String, dynamic> modelo) async {
    final id = (modelo['id'] as num).toInt();
    final productoIds = await _datasource.listarProductoIds(id);
    final categoriaIds = await _datasource.listarCategoriaIds(id);

    return Promocion(
      id: id,
      nombre: modelo['nombre'] as String,
      descripcion: modelo['descripcion'] as String,
      tipo: modelo['tipo'] as String,
      valor: (modelo['valor'] as num).toDouble(),
      fechaInicio: _parsearFecha(modelo['fechaInicio']),
      fechaFin: _parsearFecha(modelo['fechaFin']),
      activa: (modelo['activa'] as num) != 0,
      minimoCantidad: (modelo['minimoCantidad'] as num?)?.toInt(),
      minimoMonto: (modelo['minimoMonto'] as num?)?.toDouble(),
      productoIds: productoIds,
      categoriaIds: categoriaIds,
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
