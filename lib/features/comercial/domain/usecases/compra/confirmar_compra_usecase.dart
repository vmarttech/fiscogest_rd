import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_compra_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/ejecutar_actualizaciones_comerciales.dart';

class ConfirmarCompraUseCase {
  ConfirmarCompraUseCase({
    required ICompraRepository compraRepository,
    required EjecutarActualizacionesComerciales ejecutarActualizaciones,
  }) : _compraRepository = compraRepository,
       _ejecutarActualizaciones = ejecutarActualizaciones;

  final ICompraRepository _compraRepository;
  final EjecutarActualizacionesComerciales _ejecutarActualizaciones;

  Future<Compra> call(int compraId) async {
    final compra = await _compraRepository.obtenerCompraPorId(compraId);
    if (compra == null) {
      throw StateError('Compra no encontrada: $compraId');
    }

    final compraConfirmada = await _compraRepository.confirmarCompra(compraId);

    await _ejecutarActualizaciones.ejecutarCompra(
      idProducto: 0,
      cantidad: 0,
      costoUnitario: 0,
      proveedorId: compra.proveedorId,
      montoTotal: compra.totalCompra,
      fecha: compra.fechaEmision,
    );

    return compraConfirmada;
  }
}
