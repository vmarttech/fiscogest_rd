import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_compra_repository.dart';

/// Caso de Uso: Confirmar una compra registrada.
///
/// Cambia estado a confirmada, asigna fecha de confirmación.
/// Disparará actualizaciones automáticas tras persistencia.
class ConfirmarCompraUseCase {

  ConfirmarCompraUseCase(this._compraRepository);
  final ICompraRepository _compraRepository;

  Future<Compra> call(String compraId) async {
    if (compraId.isEmpty) {
      throw Exception('Identificador de compra inválido.');
    }

    return _compraRepository.confirmarCompra(compraId);
  }
}
