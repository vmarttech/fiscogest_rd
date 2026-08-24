import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_inventario_repository.dart';
import 'package:fiscogest_rd/features/clientes/domain/repositories/i_cliente_repository.dart';
import 'package:fiscogest_rd/core/domain/eventos/venta_eventos.dart';
import 'package:fiscogest_rd/core/services/sincronizacion_service.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/services/i_venta_inventario_service.dart';

class VentaInventarioService implements IVentaInventarioService {
  VentaInventarioService({
    required IInventarioRepository inventarioRepo,
    required IClienteRepository clienteRepo,
    required IVentasRepository ventasRepo,
  })  : _inventarioRepo = inventarioRepo,
        _clienteRepo = clienteRepo,
        _ventasRepo = ventasRepo;

  final IInventarioRepository _inventarioRepo;
  final IClienteRepository _clienteRepo;
  final IVentasRepository _ventasRepo;

  @override
  Future<Venta> registrarVentaConInventario(Venta venta) async {
    final ventaRegistrada = await _ventasRepo.registrarVenta(venta);

    for (final detalle in venta.detalles) {
      final detalleVenta = detalle as DetalleVenta;
      await _inventarioRepo.descontarExistencias(
        productoId: detalleVenta.productoId.toString(),
        cantidad: detalleVenta.cantidad.toDouble(),
      );
    }

    if (venta.esCredito) {
      await _clienteRepo.actualizarSaldo(
        venta.clienteId.toString(),
        venta.total,
        true,
      );
    }

    SincronizacionService.instancia.disparar(
      VentaConfirmada(
        ventaId: ventaRegistrada.id.toString(),
        usuarioResponsable: venta.usuarioId?.toString() ?? '',
      ),
    );

    return ventaRegistrada;
  }
}
