import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/apartado.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/devolucion.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/pago.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/descuento.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/oferta.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';

class VentasRepositoryImpl implements IVentasRepository {
  // SIN parámetro ventasDao en el constructor
  VentasRepositoryImpl();

  @override
  Future<List<Venta>> listarVentas({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    int? usuarioId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Venta?> obtenerVentaPorId(int ventaId) async {
    throw UnimplementedError();
  }

  @override
  Future<Venta> registrarVenta(Venta venta) async {
    throw UnimplementedError();
  }

  @override
  Future<Venta> registrarCotizacion(Venta cotizacion) async {
    throw UnimplementedError();
  }

  @override
  Future<Venta?> obtenerCotizacionPorId(int cotizacionId) async {
    throw UnimplementedError();
  }

  @override
  Future<Venta> actualizarCotizacion(Venta cotizacion) async {
    throw UnimplementedError();
  }

  @override
  Future<Venta> convertirCotizacionAVenta(int cotizacionId) async {
    throw UnimplementedError();
  }

  @override
  Future<Apartado> registrarApartado(Apartado apartado) async {
    throw UnimplementedError();
  }

  @override
  Future<Devolucion> registrarDevolucion(Devolucion devolucion) async {
    throw UnimplementedError();
  }

  @override
  Future<Pago> registrarPago(Pago pago) async {
    throw UnimplementedError();
  }

  @override
  Future<double> consultarSaldoCliente(int clienteId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Descuento>> obtenerDescuentosActivos() async {
    throw UnimplementedError();
  }

  @override
  Future<List<Oferta>> obtenerOfertasActivas() async {
    throw UnimplementedError();
  }

  @override
  Future<bool> aplicarDescuento(int ventaId, int descuentoId) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> validarOferta(int ofertaId, double montoCompra) async {
    throw UnimplementedError();
  }

  @override
  Future<void> actualizarEnCascada(int ventaId) async {
    throw UnimplementedError();
  }
}
