import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_dao.dart';
import 'package:fiscogest_rd/features/inventario/data/dao/productos_dao.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/apartado.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/devolucion.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/pago.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/descuento.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/oferta.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';

class VentasRepositoryImpl implements IVentasRepository {
  VentasRepositoryImpl(
    this._ventasDao, [
    CuentasCobrarDao? _,
    ProductosDao? productosDao,
  ]) : _productosDao = productosDao;

  final VentasDao _ventasDao;
  final ProductosDao? _productosDao;

  Future<List<DetalleVenta>> _mapearDetalles(
    List<VentaDetalleData> filas,
  ) async {
    final out = <DetalleVenta>[];
    for (final d in filas) {
      String? nombre;
      final dao = _productosDao;
      if (dao != null && d.productoId > 0) {
        try {
          final p = await dao.obtenerPorId(d.productoId);
          final n = p?.nombre.trim();
          if (n != null && n.isNotEmpty) nombre = n;
        } catch (_) {}
      }
      out.add(
        DetalleVenta(
          id: d.id,
          productoId: d.productoId,
          cantidad: d.cantidad.round().clamp(1, 999999),
          precioUnitario: d.precioUnitario,
          subtotal: d.subtotal,
          nombreProducto: nombre,
          montoDescuento: d.descuentoLinea,
          tasaImpuesto: d.impuesto,
          subtotalLinea: d.subtotal,
        ),
      );
    }
    return out;
  }

  Future<void> _guardarDetalles(
    int ventaId,
    List<DetalleVenta> detalles,
  ) async {
    await _ventasDao.eliminarDetallesDeVenta(ventaId);
    for (final d in detalles) {
      if (d.productoId <= 0) {
        throw Exception('Detalle inválido: productoId vacío');
      }
      if (d.cantidad <= 0) {
        throw Exception('Detalle inválido: cantidad debe ser > 0');
      }
      await _ventasDao.insertarDetalle(
        ventaId: ventaId,
        productoId: d.productoId,
        cantidad: d.cantidad.toDouble(),
        precioUnitario: d.precioUnitario,
        subtotal: d.subtotal,
        descuentoLinea: d.montoDescuento,
        impuesto: d.tasaImpuesto,
      );
    }
  }

  EstadoDocumento _parsearEstado(String valor) => switch (valor) {
    'borrador' => EstadoDocumento.borrador,
    'cotizado' => EstadoDocumento.cotizado,
    'enCredito' => EstadoDocumento.enCredito,
    'aprobado' => EstadoDocumento.aprobado,
    'anulado' => EstadoDocumento.anulado,
    'facturado' => EstadoDocumento.facturado,
    _ => EstadoDocumento.borrador,
  };

  Venta _mapearDesdeVentaConCliente(
    VentaConCliente registro, {
    bool esCotizacion = false,
  }) {
    final datos = registro.venta;
    return Venta(
      id: datos.id,
      numeroCotizacion: datos.numeroCotizacion,
      numeroFactura: datos.numeroFactura,
      clienteId: datos.clienteId,
      nombreCliente: registro.nombreCliente ?? '',
      fecha: datos.fecha,
      detalles: const [],
      montoSubtotal: datos.montoSubtotal,
      descuentoGlobal: datos.descuentoGlobal,
      itbis: datos.itbis,
      montoTotal: datos.montoTotal,
      formaPago: datos.formaPago,
      costoEnvio: datos.costoEnvio,
      abonoInicial: datos.abonoInicial,
      numeroCuotas: datos.numeroCuotas,
      plazoDias: datos.plazoDias,
      tasaInteres: datos.tasaInteres,
      montoInteres: datos.montoInteres,
      vencimiento: datos.vencimiento,
      estadoDocumento: _parsearEstado(datos.estadoDocumento),
      usuarioId: datos.usuarioId,
      fechaRegistro: datos.fechaRegistro,
      descuentoId: datos.descuentoId,
      descuentoNombre: datos.descuentoNombre,
      montoDescuento: datos.montoDescuento,
      comprobanteEntregaImpreso: datos.comprobanteEntregaImpreso,
      fechaComprobanteEntrega: datos.fechaComprobanteEntrega,
    );
  }

  Venta _mapearDesdeVentasTableData(
    VentasTableData datos, {
    String? nombreCliente,
    bool esCotizacion = false,
    List<DetalleVenta> detalles = const [],
  }) {
    return Venta(
      id: datos.id,
      numeroCotizacion: datos.numeroCotizacion,
      numeroFactura: datos.numeroFactura,
      clienteId: datos.clienteId,
      nombreCliente: nombreCliente ?? datos.nombreCliente ?? '',
      clienteTelefono: datos.clienteTelefono,
      clienteWhatsapp: datos.clienteWhatsapp,
      clienteDireccion: datos.clienteDireccion,
      fecha: datos.fecha,
      detalles: detalles,
      montoSubtotal: datos.montoSubtotal,
      descuentoGlobal: datos.descuentoGlobal,
      itbis: datos.itbis,
      montoTotal: datos.montoTotal,
      formaPago: datos.formaPago,
      costoEnvio: datos.costoEnvio,
      abonoInicial: datos.abonoInicial,
      numeroCuotas: datos.numeroCuotas,
      plazoDias: datos.plazoDias,
      tasaInteres: datos.tasaInteres,
      montoInteres: datos.montoInteres,
      vencimiento: datos.vencimiento,
      estadoDocumento: _parsearEstado(datos.estadoDocumento),
      usuarioId: datos.usuarioId,
      fechaRegistro: datos.fechaRegistro,
      descuentoId: datos.descuentoId,
      descuentoNombre: datos.descuentoNombre,
      montoDescuento: datos.montoDescuento,
    );
  }

  @override
  Future<List<Venta>> listarVentas({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    int? usuarioId,
  }) async {
    final resultados = await _ventasDao.listarVentas(
      desde: desde,
      hasta: hasta,
      clienteId: clienteId,
      usuarioId: usuarioId,
    );
    return resultados.map((r) => _mapearDesdeVentaConCliente(r)).toList();
  }

  @override
  Future<List<Venta>> listarCotizaciones({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    int? usuarioId,
  }) async {
    final resultados = await _ventasDao.listarCotizaciones(
      desde: desde,
      hasta: hasta,
      clienteId: clienteId,
      usuarioId: usuarioId,
    );
    return resultados
        .map((r) => _mapearDesdeVentaConCliente(r, esCotizacion: true))
        .toList();
  }

  @override
  Future<Venta?> obtenerVentaPorId(int ventaId) async {
    final registro = await _ventasDao.obtenerVentaPorId(ventaId);
    if (registro == null) return null;
    final dets = await _mapearDetalles(
      await _ventasDao.listarDetalles(ventaId),
    );
    return _mapearDesdeVentasTableData(registro, detalles: dets);
  }

  @override
  Future<Venta?> obtenerVentaBorradorPorId(int cotizacionId) async {
    final registro = await _ventasDao.obtenerVentaPorId(cotizacionId);
    if (registro == null) return null;
    final dets = await _mapearDetalles(
      await _ventasDao.listarDetalles(cotizacionId),
    );
    return _mapearDesdeVentasTableData(
      registro,
      esCotizacion: true,
      detalles: dets,
    );
  }

  @override
  Future<Venta?> buscarPorNumeroCotizacion(String numero) async {
    final registro = await _ventasDao.buscarPorNumeroCotizacion(numero);
    if (registro == null) return null;
    return _mapearDesdeVentasTableData(registro, esCotizacion: true);
  }

  @override
  Future<List<Venta>> buscarPorNombreCliente(String texto) async {
    final resultados = await _ventasDao.buscarPorNombreCliente(texto);
    return resultados
        .map((r) => _mapearDesdeVentasTableData(r.venta, esCotizacion: true))
        .toList();
  }

  @override
  Future<List<Venta>> listarPendientesCobro({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final resultados = await _ventasDao.listarPendientesCobro(
      desde: desde,
      hasta: hasta,
    );
    return resultados
        .map((r) => _mapearDesdeVentasTableData(r.venta, esCotizacion: true))
        .toList();
  }

  @override
  Future<String> siguienteNumeroCotizacion({
    bool esCredito = false,
    String prefijoContado = 'C',
    String prefijoCredito = 'CR',
  }) async {
    // Prefijo 100% desde configuración global (cualquier valor).
    final p = (esCredito ? prefijoCredito : prefijoContado).trim();
    final pref = p.isEmpty ? (esCredito ? 'CR' : 'C') : p;
    final ultimo = await _ventasDao.obtenerUltimoCorrelativoCotizacion(
      prefijo: pref,
    );
    final siguiente = ultimo + 1;
    final digitos = siguiente.toString().padLeft(6, '0');
    return '$pref-$digitos';
  }

  @override
  Future<String> siguienteNumeroFactura() async {
    final ultimo = await _ventasDao.obtenerUltimoCorrelativoFactura();
    final siguiente = ultimo + 1;
    final digitos = siguiente.toString().padLeft(8, '0');
    return 'B03-$digitos';
  }

  @override
  Future<Venta> cambiarEstadoDocumento(
    int ventaId,
    EstadoDocumento nuevoEstado,
  ) async {
    await _ventasDao.actualizarVenta(
      ventaId,
      VentasTableCompanion(estadoDocumento: Value(nuevoEstado.name)),
    );
    final registro = await _ventasDao.obtenerVentaPorId(ventaId);
    return _mapearDesdeVentasTableData(registro!);
  }

  @override
  Future<Venta> registrarVenta(Venta venta) async {
    final id = await _ventasDao.insertarVenta(
      VentasTableCompanion(
        numeroCotizacion: Value(venta.numeroCotizacion),
        numeroFactura: Value(venta.numeroFactura),
        clienteId: Value(venta.clienteId),
        fecha: Value(venta.fecha),
        montoSubtotal: Value(venta.montoSubtotal),
        descuentoGlobal: Value(venta.descuentoGlobal),
        itbis: Value(venta.itbis),
        montoTotal: Value(venta.montoTotal),
        formaPago: Value(venta.formaPago),
        costoEnvio: Value(venta.costoEnvio),
        abonoInicial: Value(venta.abonoInicial),
        numeroCuotas: Value(venta.numeroCuotas),
        plazoDias: Value(venta.plazoDias),
        tasaInteres: Value(venta.tasaInteres),
        montoInteres: Value(venta.montoInteres),
        vencimiento: Value(venta.vencimiento),
        estadoDocumento: Value(venta.estadoDocumento.name),
        usuarioId: Value(venta.usuarioId),
        fechaRegistro: Value(venta.fechaRegistro),
        descuentoId: Value(venta.descuentoId),
        descuentoNombre: Value(venta.descuentoNombre),
        montoDescuento: Value(venta.montoDescuento),
      ),
    );
    await _guardarDetalles(id, venta.detalles);
    final registro = await _ventasDao.obtenerVentaPorId(id);
    final dets = await _mapearDetalles(await _ventasDao.listarDetalles(id));
    return _mapearDesdeVentasTableData(registro!, detalles: dets);
  }

  @override
  Future<Venta> registrarVentaBorrador(Venta cotizacion) async {
    final id = await _ventasDao.insertarVenta(
      VentasTableCompanion(
        numeroCotizacion: Value(cotizacion.numeroCotizacion),
        numeroFactura: Value(cotizacion.numeroFactura),
        clienteId: Value(cotizacion.clienteId),
        nombreCliente: Value(cotizacion.nombreCliente),
        clienteTelefono: Value(cotizacion.clienteTelefono),
        clienteWhatsapp: Value(cotizacion.clienteWhatsapp),
        clienteDireccion: Value(cotizacion.clienteDireccion),
        fecha: Value(cotizacion.fecha),
        montoSubtotal: Value(cotizacion.montoSubtotal),
        descuentoGlobal: Value(cotizacion.descuentoGlobal),
        itbis: Value(cotizacion.itbis),
        montoTotal: Value(cotizacion.montoTotal),
        formaPago: Value(cotizacion.formaPago),
        costoEnvio: Value(cotizacion.costoEnvio),
        abonoInicial: Value(cotizacion.abonoInicial),
        numeroCuotas: Value(cotizacion.numeroCuotas),
        plazoDias: Value(cotizacion.plazoDias),
        tasaInteres: Value(cotizacion.tasaInteres),
        montoInteres: Value(cotizacion.montoInteres),
        vencimiento: Value(cotizacion.vencimiento),
        estadoDocumento: Value(cotizacion.estadoDocumento.name),
        usuarioId: Value(cotizacion.usuarioId),
        fechaRegistro: Value(cotizacion.fechaRegistro),
        descuentoId: Value(cotizacion.descuentoId),
        descuentoNombre: Value(cotizacion.descuentoNombre),
        montoDescuento: Value(cotizacion.montoDescuento),
      ),
    );
    if (cotizacion.detalles.isEmpty) {
      throw Exception(
        'No se puede guardar la cotización sin productos. Agregue líneas e intente de nuevo.',
      );
    }
    await _guardarDetalles(id, cotizacion.detalles);
    final registro = await _ventasDao.obtenerVentaPorId(id);
    final dets = await _mapearDetalles(await _ventasDao.listarDetalles(id));
    if (dets.isEmpty) {
      throw Exception(
        'La cotización se guardó pero no se persistieron los productos. '
        'Revise la tabla ventas_detalle / permisos de BD.',
      );
    }
    return _mapearDesdeVentasTableData(
      registro!,
      esCotizacion: true,
      detalles: dets,
    );
  }

  @override
  Future<Venta> actualizarVentaBorrador(Venta cotizacion) async {
    await _ventasDao.actualizarVenta(
      cotizacion.id!,
      VentasTableCompanion(
        numeroCotizacion: Value(cotizacion.numeroCotizacion),
        numeroFactura: Value(cotizacion.numeroFactura),
        clienteId: Value(cotizacion.clienteId),
        fecha: Value(cotizacion.fecha),
        montoSubtotal: Value(cotizacion.montoSubtotal),
        descuentoGlobal: Value(cotizacion.descuentoGlobal),
        itbis: Value(cotizacion.itbis),
        montoTotal: Value(cotizacion.montoTotal),
        formaPago: Value(cotizacion.formaPago),
        costoEnvio: Value(cotizacion.costoEnvio),
        abonoInicial: Value(cotizacion.abonoInicial),
        numeroCuotas: Value(cotizacion.numeroCuotas),
        plazoDias: Value(cotizacion.plazoDias),
        tasaInteres: Value(cotizacion.tasaInteres),
        montoInteres: Value(cotizacion.montoInteres),
        vencimiento: Value(cotizacion.vencimiento),
        estadoDocumento: Value(cotizacion.estadoDocumento.name),
        usuarioId: Value(cotizacion.usuarioId),
        fechaRegistro: Value(cotizacion.fechaRegistro),
        descuentoId: Value(cotizacion.descuentoId),
        descuentoNombre: Value(cotizacion.descuentoNombre),
        montoDescuento: Value(cotizacion.montoDescuento),
      ),
    );
    final registro = await _ventasDao.obtenerVentaPorId(cotizacion.id!);
    return _mapearDesdeVentasTableData(registro!, esCotizacion: true);
  }

  /// Solo Caja: asigna numeroFactura fiscal y estado FACTURADO.
  @override
  Future<Venta> confirmarVentaBorrador(
    int cotizacionId, {
    String? formaPago,
  }) async {
    final actual = await _ventasDao.obtenerVentaPorId(cotizacionId);
    final ya = (actual?.numeroFactura ?? '').trim();
    /* NCF lo emite Caja con emitirNcfFiscal antes/durante cobro */
    final numeroFactura = ya;
    await _ventasDao.actualizarVenta(
      cotizacionId,
      VentasTableCompanion(
        estadoDocumento: Value(EstadoDocumento.facturado.name),
        numeroFactura: Value(numeroFactura),
        formaPago: formaPago != null ? Value(formaPago) : const Value.absent(),
      ),
    );
    final registro = await _ventasDao.obtenerVentaPorId(cotizacionId);
    return _mapearDesdeVentasTableData(registro!);
  }

  /// Cotización crédito: solo abono + venc. SIN factura fiscal.
  @override
  Future<Venta> actualizarAbonoInicial(int ventaId, double montoAbono) async {
    await _ventasDao.actualizarVenta(
      ventaId,
      VentasTableCompanion(abonoInicial: Value(montoAbono)),
    );
    final registro = await _ventasDao.obtenerVentaPorId(ventaId);
    return _mapearDesdeVentasTableData(registro!);
  }

  @override
  Future<Venta> actualizarCondicionesCredito({
    required int ventaId,
    required double abonoInicial,
    required int numeroCuotas,
    required int plazoDias,
    required double tasaInteres,
    double montoInteres = 0.0,
  }) async {
    await _ventasDao.actualizarVenta(
      ventaId,
      VentasTableCompanion(
        abonoInicial: Value(abonoInicial),
        numeroCuotas: Value(numeroCuotas < 1 ? 1 : numeroCuotas),
        plazoDias: Value(plazoDias < 1 ? 30 : plazoDias),
        tasaInteres: Value(tasaInteres),
        montoInteres: Value(montoInteres),
      ),
    );
    final registro = await _ventasDao.obtenerVentaPorId(ventaId);
    return _mapearDesdeVentasTableData(registro!);
  }

  /// Solo Caja (crédito): asigna numeroFactura, abono y estado FACTURADO.
  @override
  Future<Venta> registrarVentaConAbono(
    int ventaId,
    double montoAbono,
    String referencia, {
    String? formaPago,
  }) async {
    final actual = await _ventasDao.obtenerVentaPorId(ventaId);
    final ya = (actual?.numeroFactura ?? '').trim();
    /* NCF lo emite Caja con emitirNcfFiscal antes/durante cobro */
    final numeroFactura = ya;
    await _ventasDao.actualizarVenta(
      ventaId,
      VentasTableCompanion(
        estadoDocumento: Value(EstadoDocumento.facturado.name),
        numeroFactura: Value(numeroFactura),
        abonoInicial: Value(montoAbono),
        formaPago: formaPago != null ? Value(formaPago) : const Value.absent(),
      ),
    );
    final registro = await _ventasDao.obtenerVentaPorId(ventaId);
    return _mapearDesdeVentasTableData(registro!);
  }

  /// Facturación: asigna NCF (B01/B02…) ya generado y marca FACTURADO.
  /// No genera secuencia interna B03; el NCF viene de SecuenciasNcfDao.
  @override
  Future<Venta> emitirNcfFiscal(
    int ventaId,
    String ncf, {
    String? formaPago,
  }) async {
    final actual = await _ventasDao.obtenerVentaPorId(ventaId);
    if (actual == null) {
      throw StateError('Documento $ventaId no encontrado');
    }
    final ya = (actual.numeroFactura ?? '').trim();
    final yaFiscal = ya.startsWith('B01') || ya.startsWith('B02');
    if (yaFiscal) {
      throw StateError('Ya tiene NCF fiscal: $ya');
    }
    // Si tenía B03-… u otro correlativo interno, se reemplaza por B01/B02
    await _ventasDao.actualizarVenta(
      ventaId,
      VentasTableCompanion(
        estadoDocumento: Value(EstadoDocumento.facturado.name),
        numeroFactura: Value(ncf),
        formaPago: formaPago != null ? Value(formaPago) : const Value.absent(),
      ),
    );
    final registro = await _ventasDao.obtenerVentaPorId(ventaId);
    return _mapearDesdeVentasTableData(registro!);
  }

  @override
  Future<Apartado> registrarApartado(Apartado apartado) async =>
      throw UnimplementedError();

  @override
  Future<Devolucion> registrarDevolucion(Devolucion devolucion) async =>
      throw UnimplementedError();

  @override
  Future<Pago> registrarPago(Pago pago) async => throw UnimplementedError();

  @override
  Future<double> consultarSaldoCliente(int clienteId) async =>
      throw UnimplementedError();

  @override
  Future<List<Descuento>> obtenerDescuentosActivos() async =>
      throw UnimplementedError();

  @override
  Future<List<Oferta>> obtenerOfertasActivas() async =>
      throw UnimplementedError();

  @override
  Future<bool> aplicarDescuento(int ofertaId, double montoCompra) async =>
      throw UnimplementedError();

  @override
  Future<bool> validarOferta(int ofertaId, double montoCompra) async =>
      throw UnimplementedError();

  @override
  Future<void> actualizarEnCascada(int ventaId) async =>
      throw UnimplementedError();

  @override
  Future<bool> marcarComprobanteEntregaImpreso(int ventaId) async {
    final reg = await _ventasDao.obtenerVentaPorId(ventaId);
    if (reg == null) return false;
    if (reg.comprobanteEntregaImpreso) return false;
    final ncf = (reg.numeroFactura ?? '').trim();
    final facturado =
        ncf.isNotEmpty || reg.estadoDocumento == EstadoDocumento.facturado.name;
    if (!facturado) return false;
    return _ventasDao.actualizarVenta(
      ventaId,
      VentasTableCompanion(
        comprobanteEntregaImpreso: const Value(true),
        fechaComprobanteEntrega: Value(DateTime.now()),
      ),
    );
  }
}
