import 'package:fiscogest_rd/features/comercial/domain/repositories/i_descuento_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/descuento.dart';

class BuscarDescuentos {
  BuscarDescuentos(this._repositorio);
  final IDescuentoRepository _repositorio;

  Future<List<Descuento>> call({
    bool soloActivos = false,
  }) async {
    if (soloActivos) {
      return _repositorio.listarDescuentosActivos();
    }

    return _repositorio.listarDescuentosActivos();
  }
}
