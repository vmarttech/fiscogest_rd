import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/data/datasources/drift_kardex_datasource.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/kardex.dart';
import 'package:fiscogest_rd/features/inventario/domain/enums/tipo_movimiento.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/ikardex_repository.dart';

class KardexRepositoryImpl implements IKardexRepository {
  KardexRepositoryImpl(this._ds);

  final DriftKardexDatasource _ds;

  @override
  Future<void> registrarMovimiento(Kardex movimiento) async {
    await _ds.insertar(KardexTableCompanion(
      productoId: Value(movimiento.productoId),
      tipoMovimiento: Value(movimiento.tipoMovimiento.name),
      cantidad: Value(movimiento.cantidad),
      saldoAnterior: Value(movimiento.saldoAnterior),
      saldoNuevo: Value(movimiento.saldoNuevo),
      costoUnitario: Value(movimiento.costoUnitario),
      totalMovimiento: Value(movimiento.totalMovimiento),
      fechaMovimiento: Value(movimiento.fechaMovimiento?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch),
      documentoReferencia: Value(movimiento.documentoReferencia),
      observacion: Value(movimiento.observacion),
      usuarioId: Value(movimiento.usuarioId),
    ));
  }

  TipoMovimiento _parseTipo(String valor) {
    return TipoMovimiento.values.firstWhere(
      (e) => e.name == valor,
      orElse: () => TipoMovimiento.entrada,
    );
  }

  Kardex _mapToDomain(KardexData fila) {
    return Kardex(
      id: fila.id,
      productoId: fila.productoId,
      tipoMovimiento: _parseTipo(fila.tipoMovimiento),
      cantidad: fila.cantidad,
      saldoAnterior: fila.saldoAnterior,
      saldoNuevo: fila.saldoNuevo,
      costoUnitario: fila.costoUnitario,
      totalMovimiento: fila.totalMovimiento,
      fechaMovimiento: DateTime.fromMillisecondsSinceEpoch(fila.fechaMovimiento),
      documentoReferencia: fila.documentoReferencia ?? '',
      observacion: fila.observacion ?? '',
      usuarioId: fila.usuarioId ?? 0,
    );
  }

  @override
  Future<List<Kardex>> obtenerHistorialPorProducto(String productoId) async {
    final id = int.tryParse(productoId) ?? 0;
    final datos = await _ds.obtenerHistorialPorProducto(id);
    return datos.map(_mapToDomain).toList();
  }

  @override
  Future<List<Kardex>> obtenerTodoElHistorial({DateTime? desde, DateTime? hasta}) async {
    final datos = await _ds.obtenerTodoElHistorial(desde: desde, hasta: hasta);
    return datos.map(_mapToDomain).toList();
  }

  @override
  Future<double> obtenerSaldoActual(String productoId) async {
    final id = int.tryParse(productoId) ?? 0;
    final ultimo = await _ds.obtenerUltimo(id);
    return ultimo?.saldoNuevo ?? 0.0;
  }
}
