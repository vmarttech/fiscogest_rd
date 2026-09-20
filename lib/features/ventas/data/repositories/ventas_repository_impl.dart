import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_dao.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/apartado.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/devolucion.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/pago.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/descuento.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/oferta.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';

class VentasRepositoryImpl implements IVentasRepository {
  VentasRepositoryImpl(this._ventasDao, [CuentasCobrarDao? _]);
  final VentasDao _ventasDao;

  EstadoDocumento _parsearEstado(String valor) => switch(valor) {
    'borrador' => EstadoDocumento.borrador,
    'cotizado' => EstadoDocumento.cotizado,
    'enCredito' => EstadoDocumento.enCredito,
    'aprobado' => EstadoDocumento.aprobado,
    'anulado' => EstadoDocumento.anulado,
    'facturado' => EstadoDocumento.facturado,
    _ => EstadoDocumento.borrador,
  };

  Venta _mapearDesdeVentaConCliente(VentaConCliente registro, {bool esCotizacion = false}) {
    final datos = registro.venta;
    return Venta(
      id: datos.id,
      numeroCotizacion: datos.numeroCotizacion,
      numeroFactura: datos.numeroFactura,
      clienteId: datos.clienteId,
      nombreCliente: registro.nombreCliente ?? datos.nombreCliente,
      fecha: datos.fecha,
      detalles: const [],
      montoSubtotal: datos.montoSubtotal,
      descuentoGlobal: datos.descuentoGlobal,
      itbis: datos.itbis,
      montoTotal: datos.montoTotal,
      formaPago: datos.formaPago,
      costoEnvio: datos.costoEnvio,
      abonoInicial: datos.abonoInicial,
      vencimiento: datos.vencimiento,
      estadoDocumento: _parsearEstado(datos.estadoDocumento),
      usuarioId: datos.usuarioId,
      fechaRegistro: datos.fechaRegistro,
      descuentoId: datos.descuentoId,
      descuentoNombre: datos.descuentoNombre,
      montoDescuento: datos.montoDescuento,
    );
  }

  Venta _mapearDesdeVentasTableData(VentasTableData datos, {String? nombreCliente, bool esCotizacion = false}) {
    return Venta(
      id: datos.id,
      numeroCotizacion: datos.numeroCotizacion,
      numeroFactura: datos.numeroFactura,
      clienteId: datos.clienteId,
      nombreCliente: nombreCliente ?? datos.nombreCliente,
      fecha: datos.fecha,
      detalles: const [],
      montoSubtotal: datos.montoSubtotal,
      descuentoGlobal: datos.descuentoGlobal,
      itbis: datos.itbis,
      montoTotal: datos.montoTotal,
      formaPago: datos.formaPago,
      costoEnvio: datos.costoEnvio,
      abonoInicial: datos.abonoInicial,
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
    return resultados.map((r) => _mapearDesdeVentaConCliente(r, esCotizacion: true)).toList();
  }

  @override
  Future<Venta?> obtenerVentaPorId(int ventaId) async {
    final registro = await _ventasDao.obtenerVentaPorId(ventaId);
    if (registro == null) return null;
    return _mapearDesdeVentasTableData(registro);
  }

  @override
  Future<Venta?> obtenerVentaBorradorPorId(int cotizacionId) async {
    final registro = await _ventasDao.obtenerVentaPorId(cotizacionId);
    if (registro == null) return null;
    return _mapearDesdeVentasTableData(registro, esCotizacion: true);
  }

  @override
  Future<String> siguienteNumeroCotizacion({bool esCredito = false}) async {
    final ultimo = await _ventasDao.obtenerUltimoCorrelativoCotizacion(
      soloCredito: esCredito,
    );
    final siguiente = ultimo + 1;
    final digitos = siguiente.toString().padLeft(6, '0');
    return esCredito ? 'CR-$digitos' : 'C-$digitos';
  }

  @override
  Future<Venta> cambiarEstadoDocumento(
    int ventaId,
    EstadoDocumento nuevoEstado,
  ) async {
    await _ventasDao.actualizarVenta(
      ventaId,
      VentasTableCompanion(
        estadoDocumento: Value(nuevoEstado.name),
      ),
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
        nombreCliente: Value(venta.nombreCliente),
        fecha: Value(venta.fecha),
        montoSubtotal: Value(venta.montoSubtotal),
        descuentoGlobal: Value(venta.descuentoGlobal),
        itbis: Value(venta.itbis),
        montoTotal: Value(venta.montoTotal),
        formaPago: Value(venta.formaPago),
        costoEnvio: Value(venta.costoEnvio),
        abonoInicial: Value(venta.abonoInicial),
        vencimiento: Value(venta.vencimiento),
        estadoDocumento: Value(venta.estadoDocumento.name),
        usuarioId: Value(venta.usuarioId),
        fechaRegistro: Value(venta.fechaRegistro),
        descuentoId: Value(venta.descuentoId),
        descuentoNombre: Value(venta.descuentoNombre),
        montoDescuento: Value(venta.montoDescuento),
      ),
    );
    final registro = await _ventasDao.obtenerVentaPorId(id);
    return _mapearDesdeVentasTableData(registro!);
  }

  @override
  Future<Venta> registrarVentaBorrador(Venta cotizacion) async {
    final id = await _ventasDao.insertarVenta(
      VentasTableCompanion(
        numeroCotizacion: Value(cotizacion.numeroCotizacion),
        numeroFactura: Value(cotizacion.numeroFactura),
        clienteId: Value(cotizacion.clienteId),
        nombreCliente: Value(cotizacion.nombreCliente),
        fecha: Value(cotizacion.fecha),
        montoSubtotal: Value(cotizacion.montoSubtotal),
        descuentoGlobal: Value(cotizacion.descuentoGlobal),
        itbis: Value(cotizacion.itbis),
        montoTotal: Value(cotizacion.montoTotal),
        formaPago: Value(cotizacion.formaPago),
        costoEnvio: Value(cotizacion.costoEnvio),
        abonoInicial: Value(cotizacion.abonoInicial),
        vencimiento: Value(cotizacion.vencimiento),
        estadoDocumento: Value(EstadoDocumento.cotizado.name),
        usuarioId: Value(cotizacion.usuarioId),
        fechaRegistro: Value(cotizacion.fechaRegistro),
        descuentoId: Value(cotizacion.descuentoId),
        descuentoNombre: Value(cotizacion.descuentoNombre),
        montoDescuento: Value(cotizacion.montoDescuento),
      ),
    );
    final registro = await _ventasDao.obtenerVentaPorId(id);
    return _mapearDesdeVentasTableData(registro!, esCotizacion: true);
  }

  @override
  Future<Venta> actualizarVentaBorrador(Venta cotizacion) async {
    await _ventasDao.actualizarVenta(
      cotizacion.id!,
      VentasTableCompanion(
        numeroCotizacion: Value(cotizacion.numeroCotizacion),
        numeroFactura: Value(cotizacion.numeroFactura),
        clienteId: Value(cotizacion.clienteId),
        nombreCliente: Value(cotizacion.nombreCliente),
        fecha: Value(cotizacion.fecha),
        montoSubtotal: Value(cotizacion.montoSubtotal),
        descuentoGlobal: Value(cotizacion.descuentoGlobal),
        itbis: Value(cotizacion.itbis),
        montoTotal: Value(cotizacion.montoTotal),
        formaPago: Value(cotizacion.formaPago),
        costoEnvio: Value(cotizacion.costoEnvio),
        abonoInicial: Value(cotizacion.abonoInicial),
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

  @override
  Future<Venta> confirmarVentaBorrador(int cotizacionId) async {
    await _ventasDao.actualizarVenta(
      cotizacionId,
      VentasTableCompanion(
        estadoDocumento: Value(EstadoDocumento.facturado.name),
      ),
    );
    final registro = await _ventasDao.obtenerVentaPorId(cotizacionId);
    return _mapearDesdeVentasTableData(registro!);
  }

  @override
  Future<Venta> registrarVentaConAbono(int ventaId, double montoAbono, String referencia) async {
    await _ventasDao.actualizarVenta(
      ventaId,
      VentasTableCompanion(
        estadoDocumento: Value(EstadoDocumento.enCredito.name),
        abonoInicial: Value(montoAbono),
      ),
    );
    final registro = await _ventasDao.obtenerVentaPorId(ventaId);
    return _mapearDesdeVentasTableData(registro!);
  }

  @override
  Future<Apartado> registrarApartado(Apartado apartado) async => throw UnimplementedError();
  @override
  Future<Devolucion> registrarDevolucion(Devolucion devolucion) async => throw UnimplementedError();
  @override
  Future<Pago> registrarPago(Pago pago) async => throw UnimplementedError();
  @override
  Future<double> consultarSaldoCliente(int clienteId) async => throw UnimplementedError();
  @override
  Future<List<Descuento>> obtenerDescuentosActivos() async => throw UnimplementedError();
  @override
  Future<List<Oferta>> obtenerOfertasActivas() async => throw UnimplementedError();
  @override
  Future<bool> aplicarDescuento(int ofertaId, double montoCompra) async => throw UnimplementedError();
  @override
  Future<bool> validarOferta(int ofertaId, double montoCompra) async => throw UnimplementedError();
  @override
  Future<void> actualizarEnCascada(int ventaId) async => throw UnimplementedError();
}
