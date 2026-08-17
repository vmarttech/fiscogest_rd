import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/cotizacion.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/apartado.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/devolucion.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/pago.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/descuento.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/oferta.dart';

abstract class IVentasRepository {
  Future<List<Map<String, dynamic>>> listarVentas({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    int? usuarioId,
  });

  Future<Venta> registrarVenta(Venta venta);

  Future<Cotizacion> registrarCotizacion(Cotizacion cotizacion);

  Future<Venta> convertirCotizacionAVenta(int cotizacionId);

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
