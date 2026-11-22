import 'package:flutter/foundation.dart';
import 'package:fiscogest_rd/features/inventario/data/dao/productos_dao.dart';
import 'package:fiscogest_rd/features/almacenes/data/dao/stock_almacen_dao.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/kardex.dart';
import 'package:fiscogest_rd/features/inventario/domain/enums/tipo_movimiento.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/ikardex_repository.dart';
import 'package:fiscogest_rd/features/inventario/domain/services/i_inventario_service.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';
import 'package:fiscogest_rd/features/ventas/domain/services/i_venta_inventario_service.dart';

class VentaInventarioServiceImpl implements IVentaInventarioService {
  VentaInventarioServiceImpl({
    required this.ventasRepository,
    required this.kardexRepository,
    required this.inventarioService,
    required this.productosDao,
    required this.stockAlmacenDao,
  });

  final IVentasRepository ventasRepository;
  final IKardexRepository kardexRepository;
  final IInventarioService inventarioService;
  final ProductosDao productosDao;
  final StockAlmacenDao stockAlmacenDao;

  /// `productos_table.stock` es el saldo que muestran las pantallas de
  /// inventario. Algunas entradas antiguas actualizaron esa columna sin crear
  /// un movimiento de kárdex; por eso Caja debe usarla como fuente principal.
  /// Almacén de la venta: venta.almacenId; si es nulo (borradores viejos),
  /// se cae al almacén principal.
  Future<int> _almacenIdDeVenta(Venta venta) async {
    final id = venta.almacenId;
    if (id != null) return id;
    final principal = await stockAlmacenDao.idPrincipal();
    if (principal != null) return principal;
    throw StateError(
      'No hay almacén principal definido para registrar ventas.',
    );
  }

  /// Existencia en una sucursal específica (stock_almacen).
  Future<double> _stockEnAlmacen(int productoId, int almacenId) async {
    final cantidad = await stockAlmacenDao.cantidad(productoId, almacenId);
    final principal = await stockAlmacenDao.idPrincipal();
    // FALLBACK_PRINCIPAL: fila ausente (seed pendiente o producto nuevo) en el
    // principal: no bloquear la venta; se cae al stock global (espejo).
    if (principal != null && almacenId == principal && cantidad <= 0) {
      final producto = await productosDao.obtenerPorId(productoId);
      final global = producto?.stock;
      if (global != null && global > 0) return global;
    }
    return cantidad;
  }

  Future<void> _descontarEnAlmacen(
    int productoId,
    int almacenId,
    double cantidad,
  ) async {
    var actual = await stockAlmacenDao.cantidad(productoId, almacenId);
    final principal = await stockAlmacenDao.idPrincipal();
    if (principal != null && almacenId == principal && actual <= 0) {
      final producto = await productosDao.obtenerPorId(productoId);
      final global = producto?.stock ?? 0.0;
      if (global > 0) actual = global;
    }
    await stockAlmacenDao.setCantidad(productoId, almacenId, actual - cantidad);
    if (principal != null && almacenId == principal) {
      await inventarioService.restarStock(productoId, cantidad);
    }
  }

  Future<void> _sumarEnAlmacen(
    int productoId,
    int almacenId,
    double cantidad,
  ) async {
    final actual = await stockAlmacenDao.cantidad(productoId, almacenId);
    await stockAlmacenDao.setCantidad(productoId, almacenId, actual + cantidad);
    final principal = await stockAlmacenDao.idPrincipal();
    if (principal != null && almacenId == principal) {
      await inventarioService.sumarStock(productoId, cantidad);
    }
  }

  // ignore: unused_element
  Future<double> _stockActual(int productoId) async {
    final producto = await productosDao.obtenerPorId(productoId);
    if (producto == null) {
      throw StateError('No se encontró el producto $productoId');
    }
    final stock = producto.stock;
    if (stock != null) return stock;
    return kardexRepository.obtenerSaldoActual(productoId);
  }

  Future<void> _validarExistencias(
    List<DetalleVenta> detalles,
    int almacenId,
  ) async {
    final cantidades = <int, double>{};
    final disponibles = <int, double>{};
    for (final detalle in detalles) {
      final id = detalle.productoId;
      disponibles[id] ??= await _stockEnAlmacen(id, almacenId);
      final acumulada = (cantidades[id] ?? 0) + detalle.cantidad;
      cantidades[id] = acumulada;
      if (acumulada > disponibles[id]!) {
        throw StateError(
          'Stock insuficiente en esta sucursal (almacén $almacenId): '
          '${detalle.nombreProducto ?? 'producto'}, '
          'disponible=${disponibles[id]}, vendiendo=$acumulada',
        );
      }
    }
  }

  @override
  Future<Venta> registrarVentaConInventario(Venta venta) async {
    final almacenId = await _almacenIdDeVenta(venta);

    // Validar contra la existencia de la sucursal activa (stock_almacen).
    await _validarExistencias(venta.detalles, almacenId);
    final ventaRegistrada = await ventasRepository.registrarVenta(venta);

    if (ventaRegistrada.id == null) {
      throw Exception('No se pudo guardar la venta');
    }

    for (final elemento in venta.detalles) {
      final detalle = elemento;

      final saldoAnterior = await _stockEnAlmacen(
        detalle.productoId,
        almacenId,
      );
      if (saldoAnterior < detalle.cantidad) {
        throw Exception(
          'Stock insuficiente en esta sucursal: '
          '${detalle.nombreProducto ?? "producto"}, '
          'disponible=$saldoAnterior, vendiendo=${detalle.cantidad}',
        );
      }

      final producto = await productosDao.obtenerPorId(detalle.productoId);
      final promedio = producto?.costoPromedio ?? 0.0;
      final costoUnitario = promedio > 0
          ? promedio
          : (producto?.precioCompra ?? 0.0);
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
        observacion:
            'Venta de ${detalle.nombreProducto ?? "Producto"} — almacén $almacenId',
        usuarioId: venta.usuarioId,
      );

      await kardexRepository.registrarMovimiento(movimientoKardex);
      await _descontarEnAlmacen(
        detalle.productoId,
        almacenId,
        detalle.cantidad.toDouble(),
      );
    }

    if (ventaRegistrada.id != null) {
      try {
        await ventasRepository.actualizarEnCascada(ventaRegistrada.id!);
      } catch (e) {
        debugPrint('[Venta] actualizarEnCascada sin implementar: $e');
      }
    }

    return ventaRegistrada;
  }

  @override
  Future<void> aplicarSalidaInventario(Venta venta) async {
    final almacenId = await _almacenIdDeVenta(venta);
    if (venta.id == null) {
      throw Exception('La venta no tiene id');
    }
    if (venta.detalles.isEmpty) {
      throw Exception(
        'La venta no tiene líneas de detalle. No se puede descontar inventario.',
      );
    }
    await _validarExistencias(venta.detalles, almacenId);
    final refDoc =
        (venta.numeroFactura != null && venta.numeroFactura!.isNotEmpty)
        ? 'Factura ${venta.numeroFactura}'
        : 'Venta #${venta.numeroCotizacion}';
    for (final detalle in venta.detalles) {
      final historial = await kardexRepository.obtenerHistorialPorProducto(
        detalle.productoId,
      );
      final yaRegistrada = historial.any(
        (m) =>
            m.tipoMovimiento == TipoMovimiento.salida &&
            m.documentoReferencia == refDoc,
      );
      if (yaRegistrada) continue;

      final producto = await productosDao.obtenerPorId(detalle.productoId);
      final nombre =
          (detalle.nombreProducto != null &&
              detalle.nombreProducto!.trim().isNotEmpty)
          ? detalle.nombreProducto!.trim()
          : (producto?.nombre ?? 'Producto ${detalle.productoId}');
      final saldoAnterior = await _stockEnAlmacen(
        detalle.productoId,
        almacenId,
      );
      final cant = detalle.cantidad.toDouble();
      if (saldoAnterior < cant) {
        throw Exception(
          'Stock insuficiente: $nombre, disponible=$saldoAnterior, vendiendo=$cant',
        );
      }
      final promedio = producto?.costoPromedio ?? 0.0;
      final costoUnitario = promedio > 0
          ? promedio
          : (producto?.precioCompra ?? 0.0);
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
      await _descontarEnAlmacen(detalle.productoId, almacenId, cant);
    }
  }

  @override
  Future<void> aplicarEntradaInventarioPorNc(
    Venta venta, {
    required String ncfNc,
  }) async {
    final almacenId = await _almacenIdDeVenta(venta);
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
      final nombre =
          (detalle.nombreProducto != null &&
              detalle.nombreProducto!.trim().isNotEmpty)
          ? detalle.nombreProducto!.trim()
          : (producto?.nombre ?? 'Producto ${detalle.productoId}');
      final saldoAnterior = await _stockEnAlmacen(
        detalle.productoId,
        almacenId,
      );
      final cant = detalle.cantidad.toDouble();
      final promedio = producto?.costoPromedio ?? 0.0;
      final costoUnitario = promedio > 0
          ? promedio
          : (producto?.precioCompra ?? 0.0);
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
      await _sumarEnAlmacen(detalle.productoId, almacenId, cant);
    }
  }
}
