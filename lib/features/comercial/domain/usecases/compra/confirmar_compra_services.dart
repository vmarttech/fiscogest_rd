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

  Future<void> calcularCostoAdquisicion(Compra compra) async {
    final detalles = await _obtenerDetalles(compra.id);
    for (final detalle in detalles) {
      final producto = await productoRepo.obtenerProductoPorId(detalle.productoId);
      if (producto == null) continue;

      final stockAnterior = producto.stock ?? 0.0;
      final costoPromAnterior = producto.costoPromedio;
      final cantidadNueva = detalle.cantidad;
      final costoUnitarioNuevo = detalle.costoAdquisicion;

      final nuevoCostoPromedio = stockAnterior <= 0
          ? costoUnitarioNuevo
          : ((stockAnterior * costoPromAnterior) + (cantidadNueva * costoUnitarioNuevo)) /
              (stockAnterior + cantidadNueva);

      await productoRepo.actualizarProducto(producto.copyWith(
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
        'Límite: RD\$${limite.toStringAsFixed(2)}'
      );
    }
    await proveedorRepo.agregarSaldo(compra.proveedorId, compra.totalCompra);
  }

  Future<void> ejecutarActualizaciones(Compra compra) async {
    await calcularCostoAdquisicion(compra);
    await registrarMovimientoKardex(compra);
    await actualizarSaldoProveedor(compra);
  }

  Future<List<DetalleCompra>> _obtenerDetalles(int compraId) async {
    return await compraRepo.listarDetallesDeCompra(compraId);
  }
}
