import 'package:fiscogest_rd/core/eventos/evento_bus.dart';
import 'package:fiscogest_rd/core/eventos/eventos_sistema.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/kardex.dart';
import 'package:fiscogest_rd/features/inventario/domain/enums/tipo_movimiento.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_compra_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_inventario_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_producto_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_proveedor_repository.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/ikardex_repository.dart';

class ConfirmarCompraUseCase {
  ConfirmarCompraUseCase(
    this._compraRepository,
    this._inventarioRepository,
    this._productoRepository,
    this._proveedorRepository,
    this._kardexRepository,
  );
  final ICompraRepository _compraRepository;
  final IInventarioRepository _inventarioRepository;
  final IProductoRepository _productoRepository;
  final IProveedorRepository _proveedorRepository;
  final IKardexRepository _kardexRepository;

  Future<Compra> call(String compraId) async {
    if (compraId.isEmpty) {
      throw Exception('Identificador de compra inválido.');
    }
    final compra = await _compraRepository.confirmarCompra(compraId);
    final detalles = await _compraRepository.listarDetallesDeCompra(compraId);

    for (final linea in detalles) {
      final saldoAnterior = await _kardexRepository.obtenerSaldoActual(linea.productoId);

      await _inventarioRepository.aumentarExistencias(
        productoId: linea.productoId,
        cantidad: linea.cantidad,
      );

      await _productoRepository.actualizarCostoProducto(
        productoId: linea.productoId,
        costoUnitario: linea.costoUnitario,
        cantidadAnterior: saldoAnterior,
        cantidadMovimiento: linea.cantidad,
      );

      final productoIdInt = int.tryParse(linea.productoId) ?? 0;

      final movimiento = Kardex(
        productoId: productoIdInt,
        tipoMovimiento: TipoMovimiento.entrada,
        cantidad: linea.cantidad,
        saldoAnterior: saldoAnterior,
        saldoNuevo: saldoAnterior + linea.cantidad,
        costoUnitario: linea.costoUnitario,
        totalMovimiento: linea.cantidad * linea.costoUnitario,
        fechaMovimiento: DateTime.now(),
        documentoReferencia: compraId,
        observacion: 'Compra confirmada',
        usuarioId: 0,
      );
      await _kardexRepository.registrarMovimiento(movimiento);
    }

    await _proveedorRepository.registrarCompraProveedor(
      proveedorId: compra.proveedorId,
      monto: compra.totalCompra,
    );

    EventoBus.emitir(EventosSistema.compraConfirmada, {'compraId': compraId});
    return compra;
  }
}
