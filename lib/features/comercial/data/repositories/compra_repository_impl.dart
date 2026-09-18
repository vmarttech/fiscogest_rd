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

String _str(dynamic v, [String def = '']) {
  if (v == null) return def;
  return v.toString();
}

EstadoCompra _estadoSeguro(dynamic v) {
  if (v == null) return EstadoCompra.borrador;
  if (v is EstadoCompra) return v;
  final nombre = v.toString().toLowerCase().trim();
  for (final e in EstadoCompra.values) {
    if (e.name.toLowerCase() == nombre) return e;
  }
  return EstadoCompra.borrador;
}

ComprasTableCompanion _compraToCompanion(Compra compra) {
  final ahora = DateTime.now();
  return ComprasTableCompanion(
    id: Value(compra.id),
    proveedorId: Value(compra.proveedorId),
    nombreProveedor: Value(compra.nombreProveedor),
    fechaEmision: Value(compra.fechaEmision),
    fechaVencimiento: Value(compra.fechaVencimiento ?? ahora),
    fechaRecepcion: Value(compra.fechaRecepcion),
    fechaConfirmacion: Value(compra.fechaConfirmacion ?? ahora),
    numeroComprobante: Value(compra.numeroComprobante),
    tipoComprobante: Value(compra.tipoComprobante),
    condicionPago: Value(compra.condicionPago),
    ncf: Value(compra.ncf),
    formaPago: Value(compra.formaPago),
    diasCredito: Value(compra.diasCredito),
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
    id: fila.id,
    proveedorId: fila.proveedorId,
    nombreProveedor: _str(fila.nombreProveedor, 'Sin nombre'),
    fechaEmision: fila.fechaEmision,
    fechaVencimiento: fila.fechaVencimiento,
    fechaRecepcion: fila.fechaRecepcion,
    fechaConfirmacion: fila.fechaConfirmacion,
    numeroComprobante: _str(fila.numeroComprobante),
    tipoComprobante: _str(fila.tipoComprobante, '01'),
    condicionPago: _str(fila.condicionPago, 'contado'),
    ncf: _str(fila.ncf),
    formaPago: _str(fila.formaPago, 'contado'),
    diasCredito: fila.diasCredito,
    subtotalSinImpuestos: fila.subtotalSinImpuestos,
    montoDescuentoGlobal: fila.montoDescuentoGlobal,
    tasaImpuesto: fila.tasaImpuesto,
    montoImpuesto: fila.montoImpuesto,
    totalCompra: fila.totalCompra,
    estado: _estadoSeguro(fila.estado),
    observaciones: fila.observaciones,
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
    baseImponibleLinea: Value(detalle.baseImponibleLinea),
    itbisLinea: Value(detalle.itbisLinea),
    totalLinea: Value(detalle.totalLinea),
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
    baseImponibleLinea: _seguro(datos['baseImponibleLinea']),
    itbisLinea: _seguro(datos['itbisLinea']),
    totalLinea: _seguro(datos['totalLinea']),
  );
}

class CompraRepositoryImpl implements ICompraRepository {
  CompraRepositoryImpl(this.db);
  final AppDatabase db;

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
    )..orderBy([
        (t) => OrderingTerm.desc(t.fechaEmision),
      ])).get();
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
  Future<Compra> registrarCompra({
    required Compra compra,
    required List<DetalleCompra> detalles,
  }) async {
    await db.transaction(() async {
      await db.into(db.comprasTable).insert(
            _compraToCompanion(compra),
          );
      await db.batch((batch) {
        for (final detalle in detalles) {
          batch.insert(
            db.detalleCompraTable,
            _detalleToCompanion(detalle),
          );
        }
      });
    });
    return compra;
  }

  @override
  Future<Compra> confirmarCompra(int compraId) async {
    return await db.transaction(() async {
      final compra = await obtenerCompraPorId(compraId);
      if (compra == null) {
        throw StateError('Compra no encontrada: $compraId');
      }
      if (compra.estado != EstadoCompra.borrador) {
        throw StateError(
          'Solo se puede confirmar compras en estado Borrador',
        );
      }
      final compraConfirmada = compra.copyWith(
        estado: EstadoCompra.confirmada,
        fechaConfirmacion: DateTime.now(),
        actualizadoEn: DateTime.now(),
      );
      await (db.update(db.comprasTable)
            ..where((t) => t.id.equals(compraId)))
          .write(
        _compraToCompanion(compraConfirmada),
      );
      return compraConfirmada;
    });
  }

  @override
  Future<Compra> anularCompra(int compraId) async {
    return await db.transaction(() async {
      final compra = await obtenerCompraPorId(compraId);
      if (compra == null) {
        throw StateError('Compra no encontrada: $compraId');
      }
      if (compra.estado == EstadoCompra.anulada) {
        throw StateError('La compra ya se encuentra anulada');
      }
      if (compra.estado == EstadoCompra.borrador) {
        throw StateError(
          'No se anulan borradores — elimine directamente',
        );
      }

      // Solo se permite anular compras que ya impactaron el sistema
      // (confirmada o recibida). El caller (use case) debe haber llamado
      // previamente a ConfirmarCompraServices.revertirActualizaciones.
      final compraAnulada = compra.copyWith(
        estado: EstadoCompra.anulada,
        actualizadoEn: DateTime.now(),
      );
      await (db.update(db.comprasTable)
            ..where((t) => t.id.equals(compraId)))
          .write(
        _compraToCompanion(compraAnulada),
      );
      return compraAnulada;
    });
  }
}
