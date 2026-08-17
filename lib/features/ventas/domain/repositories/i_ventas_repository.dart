import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/cotizacion.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/apartado.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/devolucion.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/pago.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/descuento.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/oferta.dart';

abstract class IVentasRepository {
  Future<Venta> registrarVenta(Venta venta);
  Future<Cotizacion> registrarCotizacion(Cotizacion cotizacion);
  Future<Venta> convertirCotizacionAVenta(String cotizacionId);
  Future<Apartado> registrarApartado(Apartado apartado);
  Future<Devolucion> registrarDevolucion(Devolucion devolucion);
  Future<Pago> registrarPago(Pago pago);
  Future<double> consultarSaldoCliente(String clienteId);
  Future<List<Descuento>> obtenerDescuentosActivos();
  Future<List<Oferta>> obtenerOfertasActivas();
  Future<bool> aplicarDescuento(String ventaId, String descuentoId);
  Future<bool> validarOferta(String ofertaId, double montoCompra);
  Future<void> actualizarEnCascada(String ventaId);
}
