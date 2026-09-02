import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/usecases/registrar_venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/usecases/actualizar_ventas_en_cascada.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_provider.dart';

class VentaOrquestadorService {
  VentaOrquestadorService({
    required RegistrarVentaConInventarioUseCase registrarVenta,
    required ActualizarVentasEnCascada actualizarEnCascada,
  }) : _registrarVenta = registrarVenta,
       _actualizarEnCascada = actualizarEnCascada;

  final RegistrarVentaConInventarioUseCase _registrarVenta;
  final ActualizarVentasEnCascada _actualizarEnCascada;

  Future<Venta> ejecutarVentaCompleta(RegistrarVentaState estado) async {
    final ventaRegistrada = await _registrarVenta.ejecutar(estado);
    final idVenta = ventaRegistrada.id!;
    await _actualizarEnCascada(idVenta);
    return ventaRegistrada;
  }
}
