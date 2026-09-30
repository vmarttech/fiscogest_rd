import 'package:fiscogest_rd/features/comercial/domain/repositories/i_promocion_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/promocion.dart';

class BuscarPromociones {
  BuscarPromociones(this._repositorio);
  final IPromocionRepository _repositorio;

  Future<List<Promocion>> call({
    DateTime? fechaReferencia,
    bool soloActivas = false,
  }) async {
    final DateTime fecha = fechaReferencia ?? DateTime.now();

    if (soloActivas) {
      return _repositorio.listarActivas(fecha);
    }

    return _repositorio.listarTodas();
  }
}
