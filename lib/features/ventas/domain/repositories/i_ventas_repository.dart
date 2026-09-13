import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/apartado.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/devolucion.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/pago.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/descuento.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/oferta.dart';
abstract class IVentasRepository {
  Future<List<Venta>> listarVentas({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    int? usuarioId,
  });
  Future<List<Venta>> listarCotizaciones({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    int? usuarioId,
  });
  Future<Venta?> obtenerVentaPorId(int ventaId);
  Future<String> siguienteNumeroCotizacion();
  Future<Venta> registrarVenta(Venta venta);
  Future<Venta> registrarVentaBorrador(Venta cotizacion);
  Future<Venta?> obtenerVentaBorradorPorId(int cotizacionId);
  Future<Venta> actualizarVentaBorrador(Venta cotizacion);
  Future<Venta> confirmarVentaBorrador(int cotizacionId);
  Future<Apartado> registrarApartado(Apartado apartado);
  Future<Devolucion> registrarDevolucion(Devolucion devolucion);
  Future<Pago> registrarPago(Pago pago);
  Future<double> consultarSaldoCliente(int clienteId);
  Future<List<Descuento>> obtenerDescuentosActivos();
  Future<List<Oferta>> obtenerOfertasActivas();
  Future<bool> aplicarDescuento(int ventaId, int descuentoId);
  Future<bool> validarOferta(int ofertaId, double montoCompra);
  Future<void> actualizarEnCascada(int ventaId);
}
