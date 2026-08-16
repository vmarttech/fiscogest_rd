import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_compra_repository.dart';

/// Caso de Uso: Obtener listado completo de compras.
class ListarComprasUseCase {

  ListarComprasUseCase(this._compraRepository);
  final ICompraRepository _compraRepository;

  Future<List<Compra>> call() async {
    return _compraRepository.listarCompras();
  }
}
