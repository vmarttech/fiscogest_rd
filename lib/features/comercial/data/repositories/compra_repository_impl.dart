import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/detalle_compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_compra_repository.dart';

int _extraerId(dynamic valor) {
  if (valor == null) return 0;
  final texto = valor.toString().replaceAll(RegExp(r'[^0-9]'), '');
  return int.tryParse(texto) ?? 0;
}

double _seguro(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return (num.tryParse(v.toString()) ?? 0).toDouble();
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
      fleteUnitario: Value(detalle.fleteUnitario),
      seguroUnitario: Value(detalle.seguroUnitario),
      arancelesUnitario: Value(detalle.arancelesUnitario),
      gastosUnitario: Value(detalle.gastosUnitario),
      costoAdquisicion: Value(detalle.costoAdquisicion),
      descuentoPorcentaje: Value(detalle.descuentoPorcentaje),
      montoDescuentoLinea: Value(detalle.montoDescuentoLinea),
      subtotalLinea: Value(detalle.subtotalLinea),
    );
  }

  DetalleCompra _filaToDetalle(DetalleCompraTableData fila) {
    final datos = fila.toJson();
    return DetalleCompra(
      id: _extraerId(datos['id']),
      compraId: _extraerId(datos['compraId']),
      productoId: _extraerId(datos['productoId']),
      nombreProducto: (datos['nombreProducto'] as String?) ?? '',
      cantidad: _seguro(datos['cantidad']),
      costoUnitario: _seguro(datos['costoUnitario']),
      fleteUnitario: _seguro(datos['fleteUnitario']),
      seguroUnitario: _seguro(datos['seguroUnitario']),
      arancelesUnitario: _seguro(datos['arancelesUnitario']),
      gastosUnitario: _seguro(datos['gastosUnitario']),
      costoAdquisicion: _seguro(datos['costoAdquisicion']),
      descuentoPorcentaje: _seguro(datos['descuentoPorcentaje']),
      montoDescuentoLinea: _seguro(datos['montoDescuentoLinea']),
      subtotalLinea: _seguro(datos['subtotalLinea']),
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
    return await db.transaction(() async {
      final compra = await obtenerCompraPorId(compraId);
      if (compra == null) {
        throw StateError('Compra no encontrada: $compraId');
      }
      if (compra.estado != EstadoCompra.borrador) {
        throw StateError('Compra no está en estado Borrador');
      }
      final compraConfirmada = compra.copyWith(
        estado: EstadoCompra.confirmada,
        fechaConfirmacion: DateTime.now(),
        actualizadoEn: DateTime.now(),
      );
      await (db.update(db.comprasTable)..where((t) => t.id.equals(compraId)))
          .write(_compraToCompanion(compraConfirmada));
      return compraConfirmada;
    });
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
