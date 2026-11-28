import 'package:fiscogest_rd/features/ventas/domain/entities/resultado_venta_inventario.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';
import 'package:fiscogest_rd/features/ventas/domain/services/i_venta_inventario_service.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_provider.dart';

class RegistrarVentaConInventarioUseCase {
  RegistrarVentaConInventarioUseCase(this._servicioInventario);
  final IVentaInventarioService _servicioInventario;

  Future<ResultadoVentaInventario> ejecutar(
    RegistrarVentaState estado, {
    int? almacenId,
  }) async {
    final ahora = DateTime.now();
    final venta = Venta(
      id: null,
      numeroCotizacion: '',
      numeroFactura: null,
      clienteId: estado.clienteId ?? 0,
      nombreCliente: estado.clienteNombre,
      fecha: ahora,
      detalles: estado.detalles,
      montoSubtotal: estado.subtotal,
      descuentoGlobal: 0.0,
      itbis: estado.itbis,
      montoTotal: estado.total,
      formaPago: estado.tipoPago,
      costoEnvio: 0.0,
      abonoInicial: estado.abonoInicial,
      vencimiento: estado.vencimiento,
      estadoDocumento: EstadoDocumento.borrador,
      usuarioId: estado.usuarioId,
      fechaRegistro: ahora,
      descuentoId: estado.descuentoId,
      descuentoNombre: estado.descuentoNombre,
      montoDescuento: estado.montoDescuento,
      almacenId: almacenId,
    );
    return await _servicioInventario.registrarVentaConInventario(venta);
  }
}
