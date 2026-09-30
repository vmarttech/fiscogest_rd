import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';
import 'package:fiscogest_rd/features/ventas/domain/services/i_venta_inventario_service.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_provider.dart';

class RegistrarVentaConInventarioUseCase {
  RegistrarVentaConInventarioUseCase(this._servicioInventario);
  final IVentaInventarioService _servicioInventario;

  Future<Venta> ejecutar(RegistrarVentaState estado) async {
    final ahora = DateTime.now();
    final venta = Venta(
      id: null,
      numeroCotizacion: '', // Se asigna en el repositorio al guardar
      numeroFactura: null, // Nulo hasta que CAJA lo asigne
      clienteId: estado.clienteId ?? 0,
      nombreCliente: estado.clienteNombre,
      fecha: ahora,
      detalles: estado.detalles,
      montoSubtotal: estado.subtotal,
      descuentoGlobal: 0.0, // Valor por defecto
      itbis: estado.itbis,
      montoTotal: estado.total,
      formaPago: estado.tipoPago,
      costoEnvio: 0.0, // Valor por defecto
      abonoInicial: estado.abonoInicial,
      vencimiento: estado.vencimiento,
      estadoDocumento: EstadoDocumento.borrador, // Estado inicial
      usuarioId: estado.usuarioId,
      fechaRegistro: ahora,
      descuentoId: estado.descuentoId,
      descuentoNombre: estado.descuentoNombre,
      montoDescuento: estado.montoDescuento,
    );
    return await _servicioInventario.registrarVentaConInventario(venta);
  }
}
