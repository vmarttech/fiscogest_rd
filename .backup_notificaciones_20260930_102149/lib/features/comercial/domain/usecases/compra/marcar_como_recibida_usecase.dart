import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_compra_repository.dart';

class MarcarComoRecibidaUseCase {
  MarcarComoRecibidaUseCase({
    required this.compraRepository,
  });

  final ICompraRepository compraRepository;

  Future<Compra> call(int compraId) async {
    final compra = await compraRepository.obtenerCompraPorId(compraId);
    if (compra == null) throw StateError('Compra no encontrada: $compraId');

    if (compra.estado != EstadoCompra.confirmada) {
      throw StateError(
        'Solo se puede marcar como Recibida una compra en estado Confirmada',
      );
    }

    return await compraRepository.marcarComoRecibida(compraId);
  }
}
