import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';

typedef VentaConCliente = ({VentasTableData venta, String? nombreCliente});

class VentasDao {
  VentasDao(this._db);
  final AppDatabase _db;

  Future<int> insertarVenta(final VentasTableCompanion venta) async {
    return await _db.into(_db.ventasTable).insert(venta);
  }

  Future<List<VentaConCliente>> listarVentas({
    final DateTime? desde,
    final DateTime? hasta,
    final int? clienteId,
    final int? usuarioId,
  }) async {
    final query = _db.select(_db.ventasTable)
      ..orderBy([(final t) => OrderingTerm.desc(t.fechaRegistro)]);
    if (desde != null) {
      query.where((final t) => t.fechaRegistro.isBiggerOrEqualValue(desde));
    }
    if (hasta != null) {
      query.where((final t) => t.fechaRegistro.isSmallerOrEqualValue(hasta));
    }
    if (clienteId != null) {
      query.where((final t) => t.clienteId.equals(clienteId));
    }
    if (usuarioId != null) {
      query.where((final t) => t.usuarioId.equals(usuarioId));
    }
    final filas = await query.get();
    return filas
        .map((final v) => (venta: v, nombreCliente: v.nombreCliente))
        .toList();
  }

  Future<List<VentaConCliente>> listarCotizaciones({
    final DateTime? desde,
    final DateTime? hasta,
    final int? clienteId,
    final int? usuarioId,
  }) async {
    // Incluye cotizado/aprobado/facturado/enCredito para Facturación (NCF)
    // y listados que reutilizan este método. Caja sigue usando listarPendientesCobro.
    final query = _db.select(_db.ventasTable)
      ..where(
        (final t) =>
            t.estadoDocumento.equals('cotizado') |
            t.estadoDocumento.equals('aprobado') |
            t.estadoDocumento.equals('facturado') |
            t.estadoDocumento.equals('enCredito'),
      )
      ..orderBy([(final t) => OrderingTerm.desc(t.fechaRegistro)]);
    if (desde != null) {
      query.where((final t) => t.fechaRegistro.isBiggerOrEqualValue(desde));
    }
    if (hasta != null) {
      query.where((final t) => t.fechaRegistro.isSmallerOrEqualValue(hasta));
    }
    if (clienteId != null) {
      query.where((final t) => t.clienteId.equals(clienteId));
    }
    if (usuarioId != null) {
      query.where((final t) => t.usuarioId.equals(usuarioId));
    }
    final filas = await query.get();
    return filas
        .map((final v) => (venta: v, nombreCliente: v.nombreCliente))
        .toList();
  }

  /// Cotizaciones listas para cobrar en Caja:
  /// - Contado: estado cotizado
  /// - Crédito: estado aprobado
  Future<List<VentaConCliente>> listarPendientesCobro({
    final DateTime? desde,
    final DateTime? hasta,
  }) async {
    final query = _db.select(_db.ventasTable)
      ..where(
        (final t) =>
            t.estadoDocumento.equals('cotizado') |
            t.estadoDocumento.equals('aprobado'),
      )
      ..orderBy([(final t) => OrderingTerm.desc(t.fechaRegistro)]);
    if (desde != null) {
      query.where((final t) => t.fechaRegistro.isBiggerOrEqualValue(desde));
    }
    if (hasta != null) {
      query.where((final t) => t.fechaRegistro.isSmallerOrEqualValue(hasta));
    }
    final filas = await query.get();
    return filas
        .map((final v) => (venta: v, nombreCliente: v.nombreCliente))
        .toList();
  }

  Future<VentasTableData?> buscarPorNumeroCotizacion(
    final String numero,
  ) async {
    final limpio = numero.trim().toUpperCase();
    if (limpio.isEmpty) return null;
    return await (_db.select(_db.ventasTable)
          ..where((final t) => t.numeroCotizacion.equals(limpio)))
        .getSingleOrNull();
  }

  Future<List<VentaConCliente>> buscarPorNombreCliente(
    final String texto,
  ) async {
    final limpio = texto.trim();
    if (limpio.isEmpty) return [];
    final query = _db.select(_db.ventasTable)
      ..where(
        (final t) =>
            t.nombreCliente.like('%$limpio%') &
            (t.estadoDocumento.equals('cotizado') |
                t.estadoDocumento.equals('aprobado')),
      )
      ..orderBy([(final t) => OrderingTerm.desc(t.fechaRegistro)])
      ..limit(30);
    final filas = await query.get();
    return filas
        .map((final v) => (venta: v, nombreCliente: v.nombreCliente))
        .toList();
  }

  Future<VentasTableData?> obtenerVentaPorId(final int ventaId) async {
    return await (_db.select(_db.ventasTable)
          ..where((final t) => t.id.equals(ventaId)))
        .getSingleOrNull();
  }

  Future<bool> actualizarVenta(
    final int ventaId,
    final VentasTableCompanion venta,
  ) async {
    final filas = await (_db.update(_db.ventasTable)
          ..where((final t) => t.id.equals(ventaId)))
        .write(venta);
    return filas > 0;
  }

  Future<int> obtenerUltimoCorrelativoCotizacion({bool? soloCredito}) async {
    // Series independientes: C-… (contado) y CR-… (crédito).
    // OJO: like('C-%') también matchea 'CR-%' → hay que excluir CR en contado.
    final query = _db.select(_db.ventasTable)
      ..where((final t) => t.numeroCotizacion.isNotNull());

    if (soloCredito == true) {
      query.where((final t) => t.numeroCotizacion.like('CR-%'));
    } else if (soloCredito == false) {
      query.where((final t) => t.numeroCotizacion.like('C-%'));
    }

    final filas = await query.get();
    var maxN = 0;
    for (final fila in filas) {
      final raw = fila.numeroCotizacion;
      if (raw.isEmpty) continue;

      if (soloCredito == true) {
        if (!raw.startsWith('CR-')) continue;
      } else if (soloCredito == false) {
        // Contado: C- pero nunca CR-
        if (!raw.startsWith('C-') || raw.startsWith('CR-')) continue;
      }

      final prefijoLen = raw.startsWith('CR-') ? 3 : 2; // 'CR-' | 'C-'
      final digitos = raw.length > prefijoLen
          ? raw.substring(prefijoLen).replaceAll(RegExp(r'[^0-9]'), '')
          : '';
      final n = int.tryParse(digitos) ?? 0;
      if (n > maxN) maxN = n;
    }
    return maxN;
  }

  Future<int> obtenerUltimoCorrelativoFactura() async {
    final query = _db.select(_db.ventasTable)
      ..where((final t) => t.numeroFactura.isNotNull());
    query.orderBy([(final t) => OrderingTerm.desc(t.numeroFactura)]);
    query.limit(1);
    final filas = await query.get();
    if (filas.isEmpty) return 0;
    final ultimo = filas.first.numeroFactura ?? '';
    final soloNumero = ultimo.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(soloNumero) ?? 0;
  }

  Future<int> insertarDetalle({
    required int ventaId,
    required int productoId,
    required double cantidad,
    required double precioUnitario,
    required double subtotal,
    double descuentoLinea = 0.0,
    double impuesto = 0.0,
  }) async {
    return await _db.into(_db.ventasDetalleTable).insert(
      VentasDetalleTableCompanion.insert(
        ventaId: ventaId,
        productoId: productoId,
        cantidad: cantidad,
        precioUnitario: precioUnitario,
        subtotal: subtotal,
        descuentoLinea: Value(descuentoLinea),
        impuesto: impuesto,
      ),
    );
  }

  Future<List<VentaDetalleData>> listarDetalles(int ventaId) async {
    return await (_db.select(_db.ventasDetalleTable)
          ..where((t) => t.ventaId.equals(ventaId)))
        .get();
  }

  Future<int> eliminarDetallesDeVenta(int ventaId) async {
    return await (_db.delete(_db.ventasDetalleTable)
          ..where((t) => t.ventaId.equals(ventaId)))
        .go();
  }
}
