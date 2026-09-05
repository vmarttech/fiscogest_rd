import 'package:fiscogest_rd/features/inventario/data/dao/productos_dao.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/kardex.dart';
import 'package:fiscogest_rd/features/inventario/domain/enums/tipo_movimiento.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/ikardex_repository.dart';
import 'package:fiscogest_rd/features/inventario/domain/services/i_inventario_service.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';
import 'package:fiscogest_rd/features/ventas/domain/services/i_venta_inventario_service.dart';

class VentaInventarioServiceImpl implements IVentaInventarioService {
  VentaInventarioServiceImpl({
    required this.ventasRepository,
    required this.kardexRepository,
    required this.inventarioService,
    required this.productosDao,
  });

  final IVentasRepository ventasRepository;
  final IKardexRepository kardexRepository;
  final IInventarioService inventarioService;
  final ProductosDao productosDao;

  @override
  Future<Venta> registrarVentaConInventario(Venta venta) async {
    final ventaRegistrada = await ventasRepository.registrarVenta(venta);

    if (ventaRegistrada.id == null) {
      throw Exception('No se pudo guardar la venta');
    }

    final usuarioIdSeguro = venta.usuarioId ?? 1;

    for (final elemento in venta.detalles) {
      final detalle = elemento as DetalleVenta;

      final saldoAnterior = await kardexRepository.obtenerSaldoActual(detalle.productoId);
      if (saldoAnterior < detalle.cantidad) {
        throw Exception('Stock insuficiente: producto ${detalle.nombreProducto}, disponible=$saldoAnterior, vendiendo=${detalle.cantidad}');
      }

      final producto = await productosDao.obtenerPorId(detalle.productoId);
      final costoUnitario = producto?.precioCompra ?? 0.0;
      final saldoNuevo = saldoAnterior - detalle.cantidad;

      final movimientoKardex = Kardex(
        productoId: detalle.productoId,
        tipoMovimiento: TipoMovimiento.salida,
        cantidad: detalle.cantidad.toDouble(),
        saldoAnterior: saldoAnterior,
        saldoNuevo: saldoNuevo,
        costoUnitario: costoUnitario,
        totalMovimiento: costoUnitario * detalle.cantidad,
        fechaMovimiento: venta.fecha,
        documentoReferencia: 'Venta #${ventaRegistrada.numero}',
        observacion: 'Venta de ${detalle.nombreProducto ?? "Producto"}',
        usuarioId: usuarioIdSeguro,
      );

      await kardexRepository.registrarMovimiento(movimientoKardex);
      await inventarioService.restarStock(detalle.productoId, detalle.cantidad.toDouble());
    }

    if (ventaRegistrada.id != null) {
      await ventasRepository.actualizarEnCascada(ventaRegistrada.id!);
    }

    return ventaRegistrada;
  }
}
