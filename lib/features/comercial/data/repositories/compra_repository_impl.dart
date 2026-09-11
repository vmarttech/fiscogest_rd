import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/detalle_compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_compra_repository.dart';

int _extraerId(dynamic valor) {
  final texto = valor.toString().replaceAll(RegExp(r'[^0-9]'), '');
  return int.tryParse(texto) ?? 0;
}

class CompraRepositoryImpl implements ICompraRepository {
  CompraRepositoryImpl(this.db);
  final AppDatabase db;

  ComprasTableCompanion _compraToCompanion(Compra compra) {
    return ComprasTableCompanion(
      id: Value(compra.id),
      proveedorId: Value(compra.proveedorId),
      nombreProveedor: Value(compra.nombreProveedor),
      fechaEmision: Value(compra.fechaEmision),
      fechaConfirmacion: Value(compra.fechaConfirmacion),
      numeroComprobante: Value(compra.numeroComprobante),
      subtotalSinImpuestos: Value(compra.subtotalSinImpuestos),
      montoDescuentoGlobal: Value(compra.montoDescuentoGlobal),
      tasaImpuesto: Value(compra.tasaImpuesto),
      montoImpuesto: Value(compra.montoImpuesto),
      totalCompra: Value(compra.totalCompra),
      observaciones: Value(compra.observaciones),
      estado: Value(compra.estado),
      creadoEn: Value(compra.creadoEn),
      actualizadoEn: Value(compra.actualizadoEn),
    );
  }

  Compra _filaToCompra(ComprasTableData fila) {
    return Compra(
      id: _extraerId(fila.id),
      proveedorId: _extraerId(fila.proveedorId),
      nombreProveedor: fila.nombreProveedor,
      fechaEmision: fila.fechaEmision,
      fechaConfirmacion: fila.fechaConfirmacion,
      numeroComprobante: fila.numeroComprobante,
      subtotalSinImpuestos: fila.subtotalSinImpuestos,
      montoDescuentoGlobal: fila.montoDescuentoGlobal,
      tasaImpuesto: fila.tasaImpuesto,
      montoImpuesto: fila.montoImpuesto,
      totalCompra: fila.totalCompra,
      observaciones: fila.observaciones,
      estado: fila.estado,
      creadoEn: fila.creadoEn,
      actualizadoEn: fila.actualizadoEn,
    );
  }

  DetalleCompraTableCompanion _detalleToCompanion(DetalleCompra detalle) {
    return DetalleCompraTableCompanion(
      id: Value(detalle.id),
      compraId: Value(detalle.compraId),
      productoId: Value(detalle.productoId),
      nombreProducto: Value(detalle.nombreProducto),
      cantidad: Value(detalle.cantidad),
      costoUnitario: Value(detalle.costoUnitario),
      descuentoPorcentaje: Value(detalle.descuentoPorcentaje),
      montoDescuentoLinea: Value(detalle.montoDescuentoLinea),
      subtotalLinea: Value(detalle.subtotalLinea),
    );
  }

  DetalleCompra _filaToDetalle(DetalleCompraTableData fila) {
    return DetalleCompra(
      id: _extraerId(fila.id),
      compraId: _extraerId(fila.compraId),
      productoId: _extraerId(fila.productoId),
      nombreProducto: fila.nombreProducto,
      cantidad: fila.cantidad,
      costoUnitario: fila.costoUnitario,
      descuentoPorcentaje: fila.descuentoPorcentaje,
      montoDescuentoLinea: fila.montoDescuentoLinea,
      subtotalLinea: fila.subtotalLinea,
    );
  }

  @override
  Future<Compra?> obtenerCompraPorId(int compraId) async {
    final fila = await (db.select(
      db.comprasTable,
    )..where((t) => t.id.equals(compraId))).getSingleOrNull();
    return fila == null ? null : _filaToCompra(fila);
  }

  @override
  Future<List<Compra>> listarCompras() async {
    final filas = await (db.select(
      db.comprasTable,
    )..orderBy([(t) => OrderingTerm.desc(t.fechaEmision)])).get();
    return filas.map((ComprasTableData f) => _filaToCompra(f)).toList();
  }

  @override
  Future<List<DetalleCompra>> listarDetallesDeCompra(int compraId) async {
    final filas = await (db.select(
      db.detalleCompraTable,
    )..where((t) => t.compraId.equals(compraId))).get();
    return filas.map((DetalleCompraTableData f) => _filaToDetalle(f)).toList();
  }

  @override
  Future<Compra> confirmarCompra(int compraId) async {
    final compra = await obtenerCompraPorId(compraId);
    if (compra == null) {
      throw StateError('Compra no encontrada: $compraId');
    }
    final compraConfirmada = compra.copyWith(
      estado: EstadoCompra.confirmada,
      fechaConfirmacion: DateTime.now(),
      actualizadoEn: DateTime.now(),
    );
    await (db.update(db.comprasTable)..where((t) => t.id.equals(compraId)))
        .write(_compraToCompanion(compraConfirmada));
    return compraConfirmada;
  }

  @override
  Future<Compra> registrarCompra({
    required Compra compra,
    required List<DetalleCompra> detalles,
  }) async {
    await db.transaction(() async {
      await db.into(db.comprasTable).insert(_compraToCompanion(compra));
      await db.batch((batch) {
        for (final detalle in detalles) {
          batch.insert(db.detalleCompraTable, _detalleToCompanion(detalle));
        }
      });
    });
    return compra;
  }
}
