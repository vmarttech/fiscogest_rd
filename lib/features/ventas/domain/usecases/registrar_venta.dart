import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/services/i_venta_inventario_service.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_provider.dart';

class RegistrarVentaConInventarioUseCase {
  RegistrarVentaConInventarioUseCase(this._servicioInventario);
  final IVentaInventarioService _servicioInventario;

  Future<Venta> ejecutar(RegistrarVentaState estado) async {
    final venta = Venta(
      id: null,
      numero: '',
      clienteId: estado.clienteId ?? 0,
      nombreCliente: estado.clienteNombre,
      fecha: DateTime.now(),
      detalles: estado.detalles,
      subtotal: estado.subtotal,
      itbis: estado.itbis,
      total: estado.total,
      tipoPago: estado.tipoPago,
      esCredito: estado.esCredito,
      abonoInicial: estado.abonoInicial,
      vencimiento: estado.vencimiento,
      usuarioId: estado.usuarioId,
      createdAt: DateTime.now(),
      descuentoId: estado.descuentoId,
      descuentoNombre: estado.descuentoNombre,
      montoDescuento: estado.montoDescuento,
    );
    return await _servicioInventario.registrarVentaConInventario(venta);
  }
}
