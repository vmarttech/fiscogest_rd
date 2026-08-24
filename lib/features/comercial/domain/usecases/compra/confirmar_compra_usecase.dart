import 'package:fiscogest_rd/core/eventos/evento_bus.dart';
import 'package:fiscogest_rd/core/eventos/eventos_sistema.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_compra_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_inventario_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_producto_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_proveedor_repository.dart';

/// Caso de Uso: Confirmar una compra registrada.
///
/// Cambia estado a confirmada, asigna fecha de confirmación.
/// Actualiza inventario, costos de producto y saldo de proveedor.
class ConfirmarCompraUseCase {

  ConfirmarCompraUseCase(
    this._compraRepository,
    this._inventarioRepository,
    this._productoRepository,
    this._proveedorRepository,
  );
  final ICompraRepository _compraRepository;
  final IInventarioRepository _inventarioRepository;
  final IProductoRepository _productoRepository;
  final IProveedorRepository _proveedorRepository;

  Future<Compra> call(String compraId) async {
    if (compraId.isEmpty) {
      throw Exception('Identificador de compra inválido.');
    }

    final compra = await _compraRepository.confirmarCompra(compraId);
    final detalles = await _compraRepository.listarDetallesDeCompra(compraId);

    for (final linea in detalles) {
      await _inventarioRepository.aumentarExistencias(
        productoId: linea.productoId,
        cantidad: linea.cantidad,
      );

      await _productoRepository.actualizarCostoProducto(
        productoId: linea.productoId,
        costoUnitario: linea.costoUnitario,
        cantidadAnterior: 0,
        cantidadMovimiento: linea.cantidad,
      );
    }

    await _proveedorRepository.registrarCompraProveedor(
      proveedorId: compra.proveedorId,
      monto: compra.totalCompra,
    );

    EventoBus.emitir(EventosSistema.compraConfirmada, {'compraId': compraId});

    return compra;
  }
}
