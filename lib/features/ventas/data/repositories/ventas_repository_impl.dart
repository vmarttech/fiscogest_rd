import 'package:fiscogest_rd/features/comercial/data/dao/ventas_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/mappers/venta_mapper.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/apartado.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/devolucion.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/pago.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/descuento.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/oferta.dart';

class VentasRepositoryImpl implements IVentasRepository {
  VentasRepositoryImpl({required this.ventasDao});
  // ✅ Constructor PRIMERO — cumple sort_constructors_first
  final VentasDao ventasDao;

  Venta _mapearDesdeObjeto(VentaConCliente datos) => Venta(
        id: datos.venta.id,
        numero: 'V-${datos.venta.id}',
        clienteId: datos.venta.clienteId,
        nombreCliente: datos.nombreCliente,
        usuarioId: datos.venta.usuarioId,
        fecha: datos.venta.fecha,
        subtotal: datos.venta.montoSubtotal,
        itbis: datos.venta.itbis,
        total: datos.venta.montoTotal,
        tipoPago: VentaMapper.formaPagoToString(datos.venta.formaPago),
        esCredito: datos.venta.formaPago.name == 'credito',
        detalles: [],
        createdAt: datos.venta.fechaRegistro,
      );

  @override
  Future<List<Venta>> listarVentas({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    int? usuarioId,
  }) async {
    final listaDatos = await ventasDao.listarVentas(
      desde: desde,
      hasta: hasta,
      clienteId: clienteId,
      usuarioId: usuarioId,
    );
    return listaDatos.map<Venta>(_mapearDesdeObjeto).toList();
  }

  @override
  Future<Venta?> obtenerVentaPorId(int ventaId) async {
    final d = await ventasDao.obtenerVentaPorId(ventaId);
    if (d == null) return null;
    return Venta(
      id: d.id,
      numero: 'V-${d.id}',
      clienteId: d.clienteId,
      nombreCliente: null,
      usuarioId: d.usuarioId,
      fecha: d.fecha,
      subtotal: d.montoSubtotal,
      itbis: d.itbis,
      total: d.montoTotal,
      tipoPago: VentaMapper.formaPagoToString(d.formaPago),
      esCredito: d.formaPago.name == 'credito',
      detalles: [],
      createdAt: d.fechaRegistro,
    );
  }

  @override Future<Venta> registrarVenta(Venta venta) async => throw UnimplementedError();
  @override Future<Venta> registrarCotizacion(Venta cotizacion) async => throw UnimplementedError();
  @override Future<Venta> convertirCotizacionAVenta(int cotizacionId) async => throw UnimplementedError();
  @override Future<Apartado> registrarApartado(Apartado apartado) async => throw UnimplementedError();
  @override Future<Devolucion> registrarDevolucion(Devolucion devolucion) async => throw UnimplementedError();
  @override Future<Pago> registrarPago(Pago pago) async => throw UnimplementedError();
  @override Future<double> consultarSaldoCliente(int clienteId) async => 0.0;
  @override Future<List<Descuento>> obtenerDescuentosActivos() async => [];
  @override Future<List<Oferta>> obtenerOfertasActivas() async => [];
  @override Future<bool> aplicarDescuento(int ventaId, int descuentoId) async => false;
  @override Future<bool> validarOferta(int ofertaId, double montoCompra) async => false;
  @override Future<void> actualizarEnCascada(int ventaId) async {}
}
