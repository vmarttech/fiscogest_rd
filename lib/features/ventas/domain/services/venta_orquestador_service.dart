import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/usecases/registrar_venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/usecases/actualizar_ventas_en_cascada.dart';

class VentaOrquestadorService {
  VentaOrquestadorService({
    required RegistrarVenta registrarVenta,
    required ActualizarVentasEnCascada actualizarEnCascada,
  })  : _registrarVenta = registrarVenta,
        _actualizarEnCascada = actualizarEnCascada;

  final RegistrarVenta _registrarVenta;
  final ActualizarVentasEnCascada _actualizarEnCascada;

  Future<Venta> ejecutarVentaCompleta(Venta venta) async {
    final ventaRegistrada = await _registrarVenta(venta);
    await _actualizarEnCascada(ventaRegistrada.id.toString());
    return ventaRegistrada;
  }
}
