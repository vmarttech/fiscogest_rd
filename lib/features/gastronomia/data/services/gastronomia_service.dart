
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/gastronomia/domain/entities/gastronomia_entities.dart';

/// Estados validos de un pedido gastronomico (centralizados, evita typoos).
class EstadoPedidoGastro {
  static const String pendiente = 'pendiente';
  static const String confirmado = 'confirmado';
  static const String enPreparacion = 'en_preparacion';
  static const String enCamino = 'en_camino';
  static const String listo = 'listo';
  static const String entregado = 'entregado';
  static const String cancelado = 'cancelado';
  static const List<String> validos = [pendiente, confirmado, enPreparacion, enCamino, listo, entregado, cancelado];
  static const List<String> activos = [pendiente, confirmado, enPreparacion, enCamino, listo];
}

class GastronomiaService {
  GastronomiaService(this._db);
  final AppDatabase _db;

  Future<Map<int, ProductoGastroMeta>> metaDeProductos(Iterable<int> ids) async {
    if (ids.isEmpty) return {};
    final rows = await (_db.select(_db.productosGastroMetaTable)
          ..where((t) => t.productoId.isIn(ids.toSet())))
        .get();
    return {
      for (final r in rows)
        r.productoId: ProductoGastroMeta(
          productoId: r.productoId, fotoPath: r.fotoPath,
          esGastronomico: r.esGastronomico, destacado: r.destacado,
          disponibleMenu: r.disponibleMenu,
          fotoRemotaKey: r.fotoRemotaKey,
          fotoSincronizado: r.fotoSincronizado,
          fotoActualizadoEn: r.fotoActualizadoEn)
    };
  }

  Future<void> guardarMeta(ProductoGastroMeta m) async {
    await _db.into(_db.productosGastroMetaTable).insertOnConflictUpdate(
      ProductosGastroMetaTableCompanion.insert(
        productoId: m.productoId,
        fotoPath: Value(m.fotoPath),
        esGastronomico: Value(m.esGastronomico),
        destacado: Value(m.destacado),
        disponibleMenu: Value(m.disponibleMenu),
        actualizadoEn: Value(DateTime.now()),
        fotoSincronizado: const Value(false),
        fotoActualizadoEn: Value(DateTime.now()),
      ),
    );
  }

  Future<List<CategoriaMenuMetaData>> categoriasMeta() =>
      (_db.select(_db.categoriasMenuMetaTable)..orderBy([(t) => OrderingTerm.asc(t.ordenMenu)])).get();

  Future<List<ExtraGastronomico>> extrasDeProducto(int productoId) async {
    final q = _db.select(_db.productoExtraTable).join([
      innerJoin(_db.extrasGastronomiaTable,
          _db.extrasGastronomiaTable.id.equalsExp(_db.productoExtraTable.extraId)),
    ])
      ..where(_db.productoExtraTable.productoId.equals(productoId) &
          _db.productoExtraTable.activo.equals(true) &
          _db.extrasGastronomiaTable.activo.equals(true));
    final rows = await q.get();
    return rows.map((r) {
      final e = r.readTable(_db.extrasGastronomiaTable);
      return ExtraGastronomico(id: e.id, nombre: e.nombre, precio: e.precio, activo: e.activo);
    }).toList();
  }

  Future<List<ExtraGastronomico>> extrasGlobales({bool soloActivos = true}) async {
    final q = _db.select(_db.extrasGastronomiaTable);
    if (soloActivos) {
      q.where((t) => t.activo.equals(true));
    }
    q.orderBy([(t) => OrderingTerm.asc(t.nombre)]);
    final rows = await q.get();
    return rows
        .map((e) => ExtraGastronomico(
              id: e.id, nombre: e.nombre, precio: e.precio, activo: e.activo))
        .toList();
  }

  Future<int> guardarExtra(ExtraGastronomico e) async {
    if (e.id > 0) {
      await (_db.update(_db.extrasGastronomiaTable)..where((t) => t.id.equals(e.id)))
          .write(ExtrasGastronomiaTableCompanion(
        nombre: Value(e.nombre),
        precio: Value(e.precio),
        activo: Value(e.activo),
      ));
      return e.id;
    }
    return _db.into(_db.extrasGastronomiaTable).insert(
      ExtrasGastronomiaTableCompanion.insert(
        nombre: e.nombre,
        precio: Value(e.precio),
        activo: Value(e.activo),
      ),
    );
  }

  Future<void> desactivarExtra(int id) =>
      (_db.update(_db.extrasGastronomiaTable)..where((t) => t.id.equals(id))).write(
        const ExtrasGastronomiaTableCompanion(activo: Value(false)),
      );

  /// Vincula un extra global a un producto (reactiva si ya existía).
  Future<void> vincularExtra(int productoId, int extraId) async {
    final existente = await (_db.select(_db.productoExtraTable)
          ..where((t) => t.productoId.equals(productoId) & t.extraId.equals(extraId))
          ..limit(1))
        .getSingleOrNull();
    if (existente != null) {
      if (!existente.activo) {
        await (_db.update(_db.productoExtraTable)..where((t) => t.id.equals(existente.id)))
            .write(const ProductoExtraTableCompanion(activo: Value(true)));
      }
      return;
    }
    await _db.into(_db.productoExtraTable).insert(
      ProductoExtraTableCompanion.insert(
        productoId: productoId,
        extraId: extraId,
        activo: const Value(true),
      ),
    );
  }

  Future<void> desvincularExtra(int productoId, int extraId) async {
    await (_db.update(_db.productoExtraTable)
          ..where((t) => t.productoId.equals(productoId) & t.extraId.equals(extraId)))
        .write(const ProductoExtraTableCompanion(activo: Value(false)));
  }

  Future<List<SectorDelivery>> sectores() async {
    final rows = await (_db.select(_db.sectoresDeliveryTable)
          ..where((t) => t.activo.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.orden)]))
        .get();
    return rows.map((r) => SectorDelivery(id: r.id, nombre: r.nombre,
        tarifaEnvio: r.tarifaEnvio, montoMinimoEnvioGratis: r.montoMinimoEnvioGratis,
        orden: r.orden)).toList();
  }

  Future<List<Repartidor>> repartidores() async {
    final rows = await (_db.select(_db.repartidoresTable)..where((t) => t.activo.equals(true))).get();
    return rows.map((r) => Repartidor(id: r.id, nombre: r.nombre, telefono: r.telefono)).toList();
  }

  /// Líneas de un pedido delivery (para reutilizarlas en la venta de cobro).
  Future<List<PedidoGastronomiaLineaData>> lineasDePedido(int pedidoId) =>
      (_db.select(_db.pedidoGastronomiaLineaTable)
            ..where((t) => t.pedidoId.equals(pedidoId)))
          .get();

  /// H2: vincula el pedido cobrado a la venta y al movimiento de caja.
  /// Idempotente: no permite vincular dos veces el mismo pedido.
  Future<void> vincularPagoPedido({
    required int pedidoId,
    required int ventaId,
    required double monto,
    String formaPago = 'efectivo',
  }) async {
    if (ventaId <= 0) throw ArgumentError('ventaId inválido');
    if (monto <= 0) throw ArgumentError('El monto cobrado debe ser mayor a cero');
    final previo = await (_db.select(_db.pedidosGastronomiaTable)
          ..where((t) => t.id.equals(pedidoId))
          ..limit(1))
        .getSingleOrNull();
    if (previo == null) throw ArgumentError('Pedido #$pedidoId no existe');
    if (previo.ventaId != null) {
      throw Exception('El pedido #$pedidoId ya está vinculado a la venta #${previo.ventaId}');
    }
    await registrarCajaIngreso(ventaId, monto, formaPago: formaPago);
    await (_db.update(_db.pedidosGastronomiaTable)..where((t) => t.id.equals(pedidoId)))
        .write(PedidosGastronomiaTableCompanion(
      ventaId: Value(ventaId),
      formaPago: Value(formaPago),
      estado: const Value('entregado'),
      estadoEntrega: const Value('entregado'),
    ));
  }

  /// H3: efectivo por repartidor sobre los pedidos entregados.
  Future<List<ResumenRepartidor>> resumenRepartidores() async {
    final reps = await repartidores();
    final pedidos = await (_db.select(_db.pedidosGastronomiaTable)).get();
    final porRep = <int, List<PedidoGastronomiaData>>{};
    for (final p in pedidos) {
      final rid = p.repartidorId;
      if (rid == null) continue;
      porRep.putIfAbsent(rid, () => []).add(p);
    }
    final out = <ResumenRepartidor>[];
    for (final r in reps) {
      final lista = porRep[r.id] ?? [];
      double cobrado = 0, pendiente = 0, entregado = 0;
      int nEntregados = 0, nCobrados = 0;
      for (final p in lista) {
        final esEntregado = p.estadoEntrega == 'entregado' || p.estado == 'entregado';
        if (!esEntregado) continue;
        entregado += p.total;
        nEntregados++;
        if (p.ventaId != null) {
          cobrado += p.total;
          nCobrados++;
        } else {
          pendiente += p.total;
        }
      }
      out.add(ResumenRepartidor(
        id: r.id,
        nombre: r.nombre,
        telefono: r.telefono,
        pedidosEntregados: nEntregados,
        pedidosCobrados: nCobrados,
        montoEntregado: entregado,
        montoCobrado: cobrado,
        montoPendiente: pendiente,
      ));
    }
    return out;
  }

  /// Marca la venta creada por el POS como facturada (cobro inmediato).
  Future<void> marcarVentaFacturada(int ventaId) async {
    await (_db.update(_db.ventasTable)..where((t) => t.id.equals(ventaId)))
        .write(const VentasTableCompanion(estadoDocumento: Value('facturado')));
  }


  /// Alta o actualización de sector. Si [id] es null → insert.
  Future<int> guardarSector(SectorDelivery s) async {
    if (s.id > 0) {
      await (_db.update(_db.sectoresDeliveryTable)..where((t) => t.id.equals(s.id))).write(
        SectoresDeliveryTableCompanion(
          nombre: Value(s.nombre),
          tarifaEnvio: Value(s.tarifaEnvio),
          montoMinimoEnvioGratis: Value(s.montoMinimoEnvioGratis),
          orden: Value(s.orden),
          activo: Value(s.activo),
        ),
      );
      return s.id;
    }
    return _db.into(_db.sectoresDeliveryTable).insert(
      SectoresDeliveryTableCompanion.insert(
        nombre: s.nombre,
        tarifaEnvio: Value(s.tarifaEnvio),
        montoMinimoEnvioGratis: Value(s.montoMinimoEnvioGratis),
        orden: Value(s.orden),
        activo: Value(s.activo),
      ),
    );
  }

  Future<void> desactivarSector(int id) =>
      (_db.update(_db.sectoresDeliveryTable)..where((t) => t.id.equals(id))).write(
        const SectoresDeliveryTableCompanion(activo: Value(false)),
      );

  /// Alta o actualización de repartidor. Si [id] es null/0 → insert.
  Future<int> guardarRepartidor(Repartidor r) async {
    if (r.id > 0) {
      await (_db.update(_db.repartidoresTable)..where((t) => t.id.equals(r.id))).write(
        RepartidoresTableCompanion(
          nombre: Value(r.nombre),
          telefono: Value(r.telefono),
          activo: Value(r.activo),
        ),
      );
      return r.id;
    }
    return _db.into(_db.repartidoresTable).insert(
      RepartidoresTableCompanion.insert(
        nombre: r.nombre,
        telefono: Value(r.telefono),
        activo: Value(r.activo),
      ),
    );
  }

  Future<void> desactivarRepartidor(int id) =>
      (_db.update(_db.repartidoresTable)..where((t) => t.id.equals(id))).write(
        const RepartidoresTableCompanion(activo: Value(false)),
      );

  Future<void> asignarRepartidor(int pedidoId, int repartidorId) =>
      (_db.update(_db.pedidosGastronomiaTable)..where((t) => t.id.equals(pedidoId))).write(
        PedidosGastronomiaTableCompanion(
          repartidorId: Value(repartidorId),
          estado: const Value('en_camino'),
          estadoEntrega: const Value('en_camino'),
        ),
      );

  Future<List<PedidoGastronomiaData>> pedidosPendientes() =>
      (_db.select(_db.pedidosGastronomiaTable)
            ..where((t) => t.estado.isIn(EstadoPedidoGastro.activos))
            ..orderBy([(t) => OrderingTerm.desc(t.fecha)]))
          .get();

  /// Historial de pedidos con filtros opcionales (limite 300).
  Future<List<PedidoGastronomiaData>> pedidosHistorial({
    String? estado,
    int? repartidorId,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final q = _db.select(_db.pedidosGastronomiaTable);
    if (estado != null && estado.isNotEmpty) q.where((t) => t.estado.equals(estado));
    if (repartidorId != null) q.where((t) => t.repartidorId.equals(repartidorId));
    if (desde != null) q.where((t) => t.fecha.isBiggerOrEqualValue(desde));
    if (hasta != null) q.where((t) => t.fecha.isSmallerOrEqualValue(hasta));
    q.orderBy([(t) => OrderingTerm.desc(t.fecha)]);
    q.limit(300);
    return q.get();
  }

  Future<List<Map<String, dynamic>>> topPlatos({int limite = 10}) async {
    final lineas = await _db.select(_db.pedidoGastronomiaLineaTable).get();
    final agg = <int, Map<String, dynamic>>{};
    for (final l in lineas) {
      final a = agg.putIfAbsent(l.productoId, () => {'productoId': l.productoId, 'nombre': l.nombreSnapshot, 'cantidad': 0.0, 'monto': 0.0});
      a['cantidad'] = (a['cantidad'] as double) + l.cantidad;
      a['monto'] = (a['monto'] as double) + l.subtotal;
    }
    final list = agg.values.toList()..sort((a, b) => (b['cantidad'] as double).compareTo(a['cantidad'] as double));
    return list.take(limite).toList();
  }

  Future<List<Map<String, dynamic>>> ventasPorHora() async {
    final pedidos = await _db.select(_db.pedidosGastronomiaTable).get();
    final agg = <int, Map<String, dynamic>>{};
    for (final p in pedidos) {
      final h = p.fecha.hour;
      final a = agg.putIfAbsent(h, () => {'hora': h, 'cantidad': 0, 'monto': 0.0});
      a['cantidad'] = (a['cantidad'] as int) + 1;
      a['monto'] = (a['monto'] as double) + p.total;
    }
    return agg.values.toList()..sort((a, b) => (a['hora'] as int).compareTo(b['hora'] as int));
  }


  Future<int> crearPedido(PedidoGastronomia p, List<LineaCarritoGastro> lineas) async {    final uuidPedido = const Uuid().v4();
    final pedidoId = await _db.into(_db.pedidosGastronomiaTable).insert(
      PedidosGastronomiaTableCompanion.insert(
        uuid: Value(uuidPedido),
        tipo: Value(p.tipo), estado: Value(p.estado),
        clienteId: Value(p.clienteId), nombreCliente: Value(p.nombreCliente),
        telefono: Value(p.telefono), sectorId: Value(p.sectorId),
        direccionReferencia: Value(p.direccionReferencia), costoEnvio: Value(p.costoEnvio),
        subtotal: Value(p.subtotal), itbis: Value(p.itbis), descuento: Value(p.descuento), propina: Value(p.propina),
        total: Value(p.total), formaPago: Value(p.formaPago), ventaId: Value(p.ventaId),
        repartidorId: Value(p.repartidorId), notas: Value(p.notas),
        usuarioId: Value(p.usuarioId), sincronizado: const Value(false)),
    );
    for (final l in lineas) {
      final lineaId = await _db.into(_db.pedidoGastronomiaLineaTable).insert(
        PedidoGastronomiaLineaTableCompanion.insert(
          pedidoId: pedidoId, productoId: l.productoId,
          nombreSnapshot: Value(l.nombre), cantidad: Value(l.cantidad),
          precioUnitario: Value(l.precioUnitario + l.precioExtras),
          subtotal: Value(l.subtotal), notas: Value(l.notas)),
      );
      for (final e in l.extras) {
        await _db.into(_db.pedidoLineaExtraTable).insert(
          PedidoLineaExtraTableCompanion.insert(
            lineaId: lineaId, extraId: Value(e.id),
            nombreSnapshot: Value(e.nombre), precioSnapshot: Value(e.precio)),
        );
      }
    }
    return pedidoId;
  }

  Future<void> actualizarEstadoPedido(int id, String estado) {
    final e = EstadoPedidoGastro.validos.contains(estado)
        ? estado
        : EstadoPedidoGastro.pendiente;
    return (_db.update(_db.pedidosGastronomiaTable)..where((t) => t.id.equals(id)))
        .write(PedidosGastronomiaTableCompanion(
          estado: Value(e),
          estadoEntrega: Value(e),
        ));
  }

  /// Cancela un pedido activo. Idempotente.
  Future<void> cancelarPedido(int id) =>
      actualizarEstadoPedido(id, EstadoPedidoGastro.cancelado);

  /// Ledger global (traza). El cuadre del turno NO usa estos campos:
  /// se calcula como fondo + ingresos efectivo − egresos efectivo de la sesión.
  Future<double> _saldoLedgerGlobal() async {
    final ultimo = await (_db.select(_db.cajaMovimientosTable)
          ..orderBy([(t) => OrderingTerm.desc(t.fecha)])
          ..limit(1))
        .getSingleOrNull();
    return ultimo?.saldoNuevo ?? 0.0;
  }

  /// Movimiento de caja ingreso referenciado a la venta (misma lógica que CajaRepository).
  Future<void> registrarCajaIngreso(int ventaId, double monto, {String formaPago = 'efectivo'}) async {
    if (ventaId <= 0) {
      throw ArgumentError.value(ventaId, 'ventaId', 'Debe ser un ID de venta válido (> 0)');
    }
    if (monto <= 0) {
      throw ArgumentError.value(monto, 'monto', 'Debe ser mayor a cero');
    }
    final fp = _parseFormaPago(formaPago);

    int? sesionId;
    try {
      final sesion = await (_db.select(_db.cajaSesionesTable)
            ..where((t) => t.estado.equals('abierta'))
            ..limit(1))
          .getSingleOrNull();
      sesionId = sesion?.id;
    } catch (_) {}

    // Idempotencia: no duplicar el mismo ingreso de esta venta en la sesión abierta.
    if (sesionId != null) {
      final existente = await (_db.select(_db.cajaMovimientosTable)
            ..where((t) => t.sesionId.equals(sesionId!))
            ..where((t) => t.referenciaId.equals(ventaId))
            ..where((t) => t.referenciaTipo.equals(ReferenciaTipo.venta.name))
            ..limit(1))
          .getSingleOrNull();
      if (existente != null &&
          existente.tipo == MovimientoCaja.ingreso &&
          (existente.monto - monto).abs() < 0.01) {
        return; // ya registrado
      }
    }

    final saldoAnterior = await _saldoLedgerGlobal();
    final saldoNuevo = saldoAnterior + monto;

    await _db.into(_db.cajaMovimientosTable).insert(
      CajaMovimientosTableCompanion(
        sesionId: Value(sesionId),
        tipo: const Value(MovimientoCaja.ingreso),
        referenciaTipo: const Value(ReferenciaTipo.venta),
        referenciaId: Value(ventaId),
        monto: Value(monto),
        formaPago: Value(fp),
        saldoAnterior: Value(saldoAnterior),
        saldoNuevo: Value(saldoNuevo),
        fecha: Value(DateTime.now()),
      ),
    );
  }

  /// Caja + pedido en una sola transacción (la venta comercial ya fue persistida antes).
  Future<int> registrarCajaYPedido({
    required int ventaId,
    required double monto,
    required PedidoGastronomia pedido,
    required List<LineaCarritoGastro> lineas,
    String formaPago = 'efectivo',
  }) {
    return _db.transaction(() async {
      await registrarCajaIngreso(ventaId, monto, formaPago: formaPago);
      return crearPedido(pedido, lineas);
    });
  }

  /// Fotos que aun tienen archivo local (temp) pendientes de subir a Storage.
  Future<List<ProductoGastroMetaData>> fotosPendientesSubida() async {
    final rows = await _db.select(_db.productosGastroMetaTable).get();
    return rows.where((r) => r.fotoPath.isNotEmpty).toList();
  }

  /// Al subir la foto a Storage: limpia el path local temporal y fija la clave remota.
  Future<void> marcarFotoSubida(int productoId, String fotoRemotaKey) async {
    await (_db.update(_db.productosGastroMetaTable)
          ..where((t) => t.productoId.equals(productoId)))
        .write(ProductosGastroMetaTableCompanion(
      fotoPath: const Value(''),
      fotoRemotaKey: Value(fotoRemotaKey),
      fotoSincronizado: const Value(true),
      fotoActualizadoEn: Value(DateTime.now()),
    ));
  }

  FormaPago _parseFormaPago(String raw) {
    final v = raw.trim().toLowerCase();
    for (final f in FormaPago.values) {
      if (f.name == v) return f;
    }
    if (v.contains('tarjeta')) return FormaPago.tarjeta;
    if (v.contains('transfer')) return FormaPago.transferencia;
    if (v.contains('credito') || v.contains('crédito')) return FormaPago.credito;
    if (v.contains('cheque')) return FormaPago.cheque;
    return FormaPago.efectivo;
  }
}
