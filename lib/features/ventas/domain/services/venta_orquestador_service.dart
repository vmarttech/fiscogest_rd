import 'package:fiscogest_rd/core/eventos/evento_bus.dart';
import 'package:fiscogest_rd/core/eventos/eventos_sistema.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/usecases/registrar_venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/usecases/actualizar_ventas_en_cascada.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_provider.dart';

class VentaOrquestadorService {
  VentaOrquestadorService({
    required RegistrarVentaConInventarioUseCase registrarVenta,
    required ActualizarVentasEnCascada actualizarEnCascada,
  })  : _registrarVenta = registrarVenta,
        _actualizarEnCascada = actualizarEnCascada;

  final RegistrarVentaConInventarioUseCase _registrarVenta;
  final ActualizarVentasEnCascada _actualizarEnCascada;

  Future<Venta> ejecutarVentaCompleta(
    RegistrarVentaState estado, {
    int? almacenId,
  }) async {
    final resultado = await _registrarVenta.ejecutar(
      estado,
      almacenId: almacenId,
    );
    final ventaRegistrada = resultado.venta;
    final idVenta = ventaRegistrada.id!;
    await _actualizarEnCascada(idVenta);

    final netoCents = (ventaRegistrada.montoSubtotal * 100).round();
    final itbisCents = (ventaRegistrada.itbis * 100).round();
    final totalCents = (ventaRegistrada.montoTotal * 100).round();
    final contado = !ventaRegistrada.esCredito;

    EventoBus.emitir(EventosSistema.ventaConfirmada, {
      'ventaId': idVenta,
      'montoNetoCents': netoCents,
      'itbisCents': itbisCents,
      'totalCents': totalCents,
      'costoCents': resultado.costoCents,
      'contado': contado,
      'formaPago': ventaRegistrada.formaPago,
      'montoNeto': ventaRegistrada.montoSubtotal,
      'itbis': ventaRegistrada.itbis,
      'total': ventaRegistrada.montoTotal,
    });

    return ventaRegistrada;
  }
}
