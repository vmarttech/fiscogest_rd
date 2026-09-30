import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/detalle_compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_compra_repository.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/kardex.dart';
import 'package:fiscogest_rd/features/inventario/domain/enums/tipo_movimiento.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/ikardex_repository.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_producto_repository.dart';
import 'package:fiscogest_rd/features/proveedores/domain/repositories/i_proveedor_repository.dart';

class ConfirmarCompraServices {
  ConfirmarCompraServices({
    required this.kardexRepo,
    required this.productoRepo,
    required this.proveedorRepo,
    required this.compraRepo,
    this.idUsuarioSistema = 1,
  });

  final IKardexRepository kardexRepo;
  final IProductoRepository productoRepo;
  final IProveedorRepository proveedorRepo;
  final ICompraRepository compraRepo;
  final int idUsuarioSistema;

  // ---------------------------------------------------------------------------
  // CONFIRMACIÓN
  // ---------------------------------------------------------------------------

  Future<void> calcularCostoAdquisicion(Compra compra) async {
    final detalles = await _obtenerDetalles(compra.id);
    for (final detalle in detalles) {
      final producto = await productoRepo.obtenerProductoPorId(detalle.productoId);
      if (producto == null) continue;

      final stockAnterior = producto.stock ?? 0.0;
      final costoPromAnterior = producto.costoPromedio;
      final cantidadNueva = detalle.cantidad;
      final costoLimpio = detalle.costoUnitario;
      final gastosUnit =
          detalle.fleteUnitario +
          detalle.seguroUnitario +
          detalle.arancelesUnitario +
          detalle.gastosUnitario;
      final costoAdq = detalle.costoAdquisicion > 0
          ? detalle.costoAdquisicion
          : (costoLimpio + gastosUnit);
      final nuevoCostoPromedio = stockAnterior <= 0
          ? costoAdq
          : ((stockAnterior * costoPromAnterior) + (cantidadNueva * costoAdq)) /
              (stockAnterior + cantidadNueva);
      await productoRepo.actualizarProducto(producto.copyWith(
        precioCompra: costoLimpio,
        gastosAsociados: gastosUnit,
        costoPromedio: nuevoCostoPromedio,
        stock: stockAnterior + cantidadNueva,
      ));
    }
  }

  Future<void> registrarMovimientoKardex(Compra compra) async {
    final detalles = await _obtenerDetalles(compra.id);
    final documento = 'Compra #${compra.id} | ${compra.nombreProveedor}';

    for (final detalle in detalles) {
      final saldoAnterior = await kardexRepo.obtenerSaldoActual(detalle.productoId);
      final saldoNuevo = saldoAnterior + detalle.cantidad;

      await kardexRepo.registrarMovimiento(Kardex(
        productoId: detalle.productoId,
        tipoMovimiento: TipoMovimiento.entrada,
        cantidad: detalle.cantidad,
        saldoAnterior: saldoAnterior,
        saldoNuevo: saldoNuevo,
        costoUnitario: detalle.costoAdquisicion,
        totalMovimiento: detalle.cantidad * detalle.costoAdquisicion,
        fechaMovimiento: DateTime.now(),
        documentoReferencia: documento,
        observacion: 'Confirmación de compra — ${compra.numeroComprobante}',
        usuarioId: idUsuarioSistema,
      ));
    }
  }

  Future<void> actualizarSaldoProveedor(Compra compra) async {
    if (!compra.esCredito) return;

    final proveedor = await proveedorRepo.obtenerProveedorPorId(compra.proveedorId);
    if (proveedor == null) return;

    final saldoActual = await proveedorRepo.obtenerSaldo(compra.proveedorId);
    final limite = proveedor.limiteCredito;

    if (limite > 0 && (saldoActual + compra.totalCompra) > limite) {
      throw StateError(
        'El monto de la compra (RD\$${compra.totalCompra.toStringAsFixed(2)}) '
        'excede el límite de crédito del proveedor.\n'
        'Saldo actual: RD\$${saldoActual.toStringAsFixed(2)}\n'
        'Límite: RD\$${limite.toStringAsFixed(2)}',
      );
    }

    await proveedorRepo.agregarSaldo(compra.proveedorId, compra.totalCompra);
  }

  Future<void> ejecutarActualizaciones(Compra compra) async {
    await calcularCostoAdquisicion(compra);
    await registrarMovimientoKardex(compra);
    await actualizarSaldoProveedor(compra);
  }

  // ---------------------------------------------------------------------------
  // ANULACIÓN CONTROLADA (proceso inverso)
  // ---------------------------------------------------------------------------

  /// Revierte el impacto de una compra ya confirmada.
  /// Debe llamarse ANTES de marcar la compra como anulada en la base de datos.
  Future<void> revertirActualizaciones(Compra compra) async {
    if (compra.estado != EstadoCompra.confirmada &&
        compra.estado != EstadoCompra.recibida) {
      // Solo se revierten compras que ya impactaron inventario / saldo
      return;
    }

    await _revertirStockYCosto(compra);
    await _revertirMovimientoKardex(compra);
    await _revertirSaldoProveedor(compra);
  }

  Future<void> _revertirStockYCosto(Compra compra) async {
    final detalles = await _obtenerDetalles(compra.id);

    for (final detalle in detalles) {
      final producto = await productoRepo.obtenerProductoPorId(detalle.productoId);
      if (producto == null) continue;

      final stockActual = producto.stock ?? 0.0;
      final cantidad = detalle.cantidad;

      // No permitir stock negativo
      if (stockActual < cantidad) {
        throw StateError(
          'No se puede anular la compra #${compra.id}: '
          'el producto "${detalle.nombreProducto}" tiene stock insuficiente '
          '(disponible: $stockActual, se requiere revertir: $cantidad).',
        );
      }

      final nuevoStock = stockActual - cantidad;

      // Recalcular costo promedio ponderado inverso (aproximación segura)
      // Si el stock queda en 0, se deja el costo anterior.
      double nuevoCostoPromedio = producto.costoPromedio;
      if (nuevoStock > 0 && stockActual > 0) {
        final valorTotalAnterior = stockActual * producto.costoPromedio;
        final valorEstaCompra = cantidad * detalle.costoAdquisicion;
        nuevoCostoPromedio = (valorTotalAnterior - valorEstaCompra) / nuevoStock;
        if (nuevoCostoPromedio < 0) nuevoCostoPromedio = 0;
      }

      await productoRepo.actualizarProducto(producto.copyWith(
        stock: nuevoStock,
        costoPromedio: nuevoCostoPromedio,
      ));
    }
  }

  Future<void> _revertirMovimientoKardex(Compra compra) async {
    final detalles = await _obtenerDetalles(compra.id);
    final documento = 'Anulación Compra #${compra.id} | ${compra.nombreProveedor}';

    for (final detalle in detalles) {
      final saldoAnterior = await kardexRepo.obtenerSaldoActual(detalle.productoId);
      final saldoNuevo = saldoAnterior - detalle.cantidad;

      if (saldoNuevo < 0) {
        throw StateError(
          'No se puede anular: el kardex del producto ${detalle.productoId} '
          'quedaría negativo.',
        );
      }

      await kardexRepo.registrarMovimiento(Kardex(
        productoId: detalle.productoId,
        tipoMovimiento: TipoMovimiento.salida,
        cantidad: detalle.cantidad,
        saldoAnterior: saldoAnterior,
        saldoNuevo: saldoNuevo,
        costoUnitario: detalle.costoAdquisicion,
        totalMovimiento: detalle.cantidad * detalle.costoAdquisicion,
        fechaMovimiento: DateTime.now(),
        documentoReferencia: documento,
        observacion: 'Anulación de compra — ${compra.numeroComprobante}',
        usuarioId: idUsuarioSistema,
      ));
    }
  }

  Future<void> _revertirSaldoProveedor(Compra compra) async {
    if (!compra.esCredito) return;

    final proveedor = await proveedorRepo.obtenerProveedorPorId(compra.proveedorId);
    if (proveedor == null) return;

    // Restar el monto de la compra del saldo del proveedor
    await proveedorRepo.agregarSaldo(compra.proveedorId, -compra.totalCompra);
  }

  Future<List<DetalleCompra>> _obtenerDetalles(int compraId) async {
    return await compraRepo.listarDetallesDeCompra(compraId);
  }
}
