import 'package:fiscogest_rd/features/inventario/data/dao/productos_dao.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/kardex.dart';
import 'package:fiscogest_rd/features/inventario/domain/enums/tipo_movimiento.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/ikardex_repository.dart';
import 'package:fiscogest_rd/features/inventario/domain/services/i_inventario_service.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
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


    for (final elemento in venta.detalles) {
      final detalle = elemento;

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
        usuarioId: venta.usuarioId,
      );

      await kardexRepository.registrarMovimiento(movimientoKardex);
      await inventarioService.restarStock(detalle.productoId, detalle.cantidad.toDouble());
    }

    if (ventaRegistrada.id != null) {
      await ventasRepository.actualizarEnCascada(ventaRegistrada.id!);
    }

    return ventaRegistrada;
  }

  @override
  Future<void> aplicarSalidaInventario(Venta venta) async {
    if (venta.id == null) {
      throw Exception('La venta no tiene id');
    }
    if (venta.detalles.isEmpty) {
      throw Exception(
        'La venta no tiene líneas de detalle. No se puede descontar inventario.',
      );
    }
    final refDoc = (venta.numeroFactura != null && venta.numeroFactura!.isNotEmpty)
        ? 'Factura ${venta.numeroFactura}'
        : 'Venta #${venta.numeroCotizacion}';
    for (final detalle in venta.detalles) {
      final producto = await productosDao.obtenerPorId(detalle.productoId);
      final nombre = (detalle.nombreProducto != null &&
              detalle.nombreProducto!.trim().isNotEmpty)
          ? detalle.nombreProducto!.trim()
          : (producto?.nombre ?? 'Producto ${detalle.productoId}');
      final saldoAnterior =
          await kardexRepository.obtenerSaldoActual(detalle.productoId);
      final cant = detalle.cantidad.toDouble();
      if (saldoAnterior < cant) {
        throw Exception(
          'Stock insuficiente: $nombre, disponible=$saldoAnterior, vendiendo=$cant',
        );
      }
      final costoUnitario = producto?.precioCompra ?? 0.0;
      final saldoNuevo = saldoAnterior - cant;
      final movimientoKardex = Kardex(
        productoId: detalle.productoId,
        tipoMovimiento: TipoMovimiento.salida,
        cantidad: cant,
        saldoAnterior: saldoAnterior,
        saldoNuevo: saldoNuevo,
        costoUnitario: costoUnitario,
        totalMovimiento: costoUnitario * cant,
        fechaMovimiento: venta.fecha,
        documentoReferencia: refDoc,
        observacion: 'Salida por cobro Caja — $nombre',
        usuarioId: venta.usuarioId,
      );
      await kardexRepository.registrarMovimiento(movimientoKardex);
      await inventarioService.restarStock(detalle.productoId, cant);
    }
  }

  @override
  Future<void> aplicarEntradaInventarioPorNc(
    Venta venta, {
    required String ncfNc,
  }) async {
    if (venta.id == null) {
      throw Exception('La venta no tiene id');
    }
    if (venta.detalles.isEmpty) {
      throw Exception(
        'La venta no tiene líneas de detalle. No se puede devolver inventario.',
      );
    }
    final ncfFact = (venta.numeroFactura ?? venta.numeroCotizacion).trim();
    final refDoc = 'NC $ncfNc / Factura $ncfFact';
    for (final detalle in venta.detalles) {
      final producto = await productosDao.obtenerPorId(detalle.productoId);
      final nombre = (detalle.nombreProducto != null &&
              detalle.nombreProducto!.trim().isNotEmpty)
          ? detalle.nombreProducto!.trim()
          : (producto?.nombre ?? 'Producto ${detalle.productoId}');
      final saldoAnterior =
          await kardexRepository.obtenerSaldoActual(detalle.productoId);
      final cant = detalle.cantidad.toDouble();
      final costoUnitario = producto?.precioCompra ?? 0.0;
      final saldoNuevo = saldoAnterior + cant;
      final movimientoKardex = Kardex(
        productoId: detalle.productoId,
        tipoMovimiento: TipoMovimiento.entrada,
        cantidad: cant,
        saldoAnterior: saldoAnterior,
        saldoNuevo: saldoNuevo,
        costoUnitario: costoUnitario,
        totalMovimiento: costoUnitario * cant,
        fechaMovimiento: DateTime.now(),
        documentoReferencia: refDoc,
        observacion: 'Entrada por nota de crédito — $nombre',
        usuarioId: venta.usuarioId,
      );
      await kardexRepository.registrarMovimiento(movimientoKardex);
      await inventarioService.sumarStock(detalle.productoId, cant);
    }
  }

}
