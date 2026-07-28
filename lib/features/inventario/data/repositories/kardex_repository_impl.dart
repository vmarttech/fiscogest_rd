import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/kardex.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/ikardex_repository.dart';
import 'package:fiscogest_rd/features/inventario/data/datasources/drift_kardex_datasource.dart';

class KardexRepositoryImpl implements IKardexRepository {
  KardexRepositoryImpl(this._datasource);
  final DriftKardexDatasource _datasource;

  @override
  Future<void> registrarMovimiento(Kardex kardex) async {
    final companion = KardexTableCompanion(
      id: kardex.id != null ? Value(kardex.id!) : const Value.absent(),
      idProducto: Value(kardex.productoId),
      tipoMovimiento: Value(kardex.tipoMovimiento.name),
      cantidad: Value(kardex.cantidad),
      saldoAnterior: Value(kardex.saldoAnterior),
      saldoNuevo: Value(kardex.saldoNuevo),
      costoUnitario: Value(kardex.costoUnitario),
      totalMovimiento: Value(kardex.totalMovimiento),
      documentoReferencia: Value(kardex.documentoReferencia),
      motivo: Value(kardex.observacion ?? ''),
      usuarioId: Value(kardex.usuarioId),
      fechaMovimiento: Value(kardex.fechaMovimiento ?? DateTime.now()),
    );
    await _datasource.insertar(companion);
  }

  @override
  Future<List<Kardex>> obtenerHistorialPorProducto(String productoId) async {
    final idProd = int.tryParse(productoId);
    if (idProd == null) return [];
    final datos = await _datasource.obtenerHistorialPorProducto(idProd);
    return datos.map((d) => Kardex(
      id: d.id,
      productoId: d.idProducto,
      tipoMovimiento: TipoMovimiento.values.byName(d.tipoMovimiento),
      cantidad: d.cantidad,
      saldoAnterior: d.saldoAnterior,
      saldoNuevo: d.saldoNuevo,
      costoUnitario: d.costoUnitario,
      totalMovimiento: d.totalMovimiento,
      fechaMovimiento: d.fechaMovimiento,
      documentoReferencia: d.documentoReferencia,
      observacion: d.motivo,
      usuarioId: d.usuarioId,
    )).toList();
  }

  @override
  Future<List<Kardex>> obtenerTodoElHistorial({DateTime? desde, DateTime? hasta}) async {
    final datos = await _datasource.obtenerTodoElHistorial(desde: desde, hasta: hasta);
    return datos.map((d) => Kardex(
      id: d.id,
      productoId: d.idProducto,
      tipoMovimiento: TipoMovimiento.values.byName(d.tipoMovimiento),
      cantidad: d.cantidad,
      saldoAnterior: d.saldoAnterior,
      saldoNuevo: d.saldoNuevo,
      costoUnitario: d.costoUnitario,
      totalMovimiento: d.totalMovimiento,
      fechaMovimiento: d.fechaMovimiento,
      documentoReferencia: d.documentoReferencia,
      observacion: d.motivo,
      usuarioId: d.usuarioId,
    )).toList();
  }

  @override
  Future<double> obtenerSaldoActual(String productoId) async {
    final idProd = int.tryParse(productoId);
    if (idProd == null) return 0.0;
    final ultimo = await _datasource.obtenerUltimo(idProd);
    return ultimo?.saldoNuevo ?? 0.0;
  }
}
