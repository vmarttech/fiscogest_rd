import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/detalle_compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_compra_repository.dart';

/// Caso de Uso: Registrar una nueva compra con sus líneas de detalle.
///
/// Valida datos y delega el almacenamiento al repositorio.
class RegistrarCompraUseCase {

  RegistrarCompraUseCase(this._compraRepository);
  final ICompraRepository _compraRepository;

  Future<Compra> call({
    required Compra compra,
    required List<DetalleCompra> detalles,
  }) async {
    if (detalles.isEmpty) {
      throw Exception('La compra debe contener al menos un producto.');
    }

    return _compraRepository.registrarCompra(
      compra: compra,
      detalles: detalles,
    );
  }
}
