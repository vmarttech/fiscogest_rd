import 'package:fiscogest_rd/core/eventos/evento_bus.dart';
import 'package:fiscogest_rd/core/eventos/eventos_sistema.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/kardex.dart';
import 'package:fiscogest_rd/features/inventario/domain/enums/tipo_movimiento.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_producto_repository.dart' as inventario;
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/detalle_compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_compra_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_proveedor_repository.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/ikardex_repository.dart';

class ConfirmarCompraUseCase {
  ConfirmarCompraUseCase(
    this._compraRepository,
    this._proveedorRepository,
    this._kardexRepository,
    this._productoRepoReal,
  );

  final ICompraRepository _compraRepository;
  final IProveedorRepository _proveedorRepository;
  final IKardexRepository _kardexRepository;
  final inventario.IProductoRepository _productoRepoReal;

  Future<Compra> call(String compraId) async {
    if (compraId.isEmpty) {
      throw Exception('Identificador de compra inválido.');
    }

    final compra = await _compraRepository.confirmarCompra(compraId);
    final detalles = await _compraRepository.listarDetallesDeCompra(compraId);

    for (final DetalleCompra linea in detalles) {
      final productoPorCodigo = await _productoRepoReal.obtenerProductoPorCodigo(linea.productoId);
      if (productoPorCodigo != null) {
        final saldoAnterior = await _kardexRepository.obtenerSaldoActual(productoPorCodigo.id.toString());
        final saldoNuevoCalculado = saldoAnterior + linea.cantidad;

        await _productoRepoReal.actualizarProducto(
          productoPorCodigo.copyWith(stock: saldoNuevoCalculado),
        );

        final movimiento = Kardex(
          productoId: productoPorCodigo.id!,
          tipoMovimiento: TipoMovimiento.entrada,
          cantidad: linea.cantidad,
          saldoAnterior: saldoAnterior,
          saldoNuevo: saldoNuevoCalculado,
          costoUnitario: linea.costoUnitario,
          totalMovimiento: linea.cantidad * linea.costoUnitario,
          fechaMovimiento: DateTime.now(),
          documentoReferencia: compraId,
          observacion: 'Compra confirmada',
          usuarioId: 0,
        );
        await _kardexRepository.registrarMovimiento(movimiento);
        continue;
      }

      final int? productoIdInt = int.tryParse(linea.productoId);
      if (productoIdInt != null && productoIdInt > 0) {
        final producto = await _productoRepoReal.obtenerProductoPorId(productoIdInt);
        if (producto != null) {
          final saldoAnterior = await _kardexRepository.obtenerSaldoActual(producto.id.toString());
          final saldoNuevoCalculado = saldoAnterior + linea.cantidad;

          await _productoRepoReal.actualizarProducto(
            producto.copyWith(stock: saldoNuevoCalculado),
          );

          final movimiento = Kardex(
            productoId: productoIdInt,
            tipoMovimiento: TipoMovimiento.entrada,
            cantidad: linea.cantidad,
            saldoAnterior: saldoAnterior,
            saldoNuevo: saldoNuevoCalculado,
            costoUnitario: linea.costoUnitario,
            totalMovimiento: linea.cantidad * linea.costoUnitario,
            fechaMovimiento: DateTime.now(),
            documentoReferencia: compraId,
            observacion: 'Compra confirmada (por ID)',
            usuarioId: 0,
          );
          await _kardexRepository.registrarMovimiento(movimiento);
          continue;
        }
      }

      throw Exception('Producto "${linea.nombreProducto}" no encontrado en inventario. Verifique código o ID.');
    }

    await _proveedorRepository.registrarCompraProveedor(
      proveedorId: compra.proveedorId,
      monto: compra.totalCompra,
    );

    EventoBus.emitir(EventosSistema.compraConfirmada, {'compraId': compraId});
    return compra;
  }
}
