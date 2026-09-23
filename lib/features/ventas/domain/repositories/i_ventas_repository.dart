import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/apartado.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/devolucion.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/pago.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/descuento.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/oferta.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';

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
  Future<Venta?> buscarPorNumeroCotizacion(String numero);
  Future<List<Venta>> buscarPorNombreCliente(String texto);
  Future<List<Venta>> listarPendientesCobro({DateTime? desde, DateTime? hasta});

  Future<Venta?> obtenerVentaBorradorPorId(int cotizacionId);

  Future<String> siguienteNumeroCotizacion({bool esCredito});

  Future<String> siguienteNumeroFactura();

  Future<Venta> cambiarEstadoDocumento(int ventaId, EstadoDocumento nuevoEstado);

  Future<Venta> registrarVenta(Venta venta);

  Future<Venta> registrarVentaBorrador(Venta cotizacion);

  Future<Venta> actualizarVentaBorrador(Venta cotizacion);

  Future<Venta> confirmarVentaBorrador(int cotizacionId, {String? formaPago});

  /// Solo abono (cotización crédito). NO asigna factura ni cambia a facturado.
  Future<Venta> actualizarAbonoInicial(int ventaId, double montoAbono);

  Future<Venta> registrarVentaConAbono(
    int ventaId,
    double montoAbono,
    String referencia, {
    String? formaPago,
  });

  Future<Apartado> registrarApartado(Apartado apartado);

  Future<Devolucion> registrarDevolucion(Devolucion devolucion);

  Future<Pago> registrarPago(Pago pago);

  Future<double> consultarSaldoCliente(int clienteId);

  Future<List<Descuento>> obtenerDescuentosActivos();

  Future<List<Oferta>> obtenerOfertasActivas();

  Future<bool> aplicarDescuento(int ofertaId, double montoCompra);

  Future<bool> validarOferta(int ofertaId, double montoCompra);

  Future<void> actualizarEnCascada(int ventaId);
}
