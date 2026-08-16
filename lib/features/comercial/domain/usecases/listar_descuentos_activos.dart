import 'package:fiscogest_rd/features/comercial/domain/entities/descuento.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_descuento_repository.dart';

class ListarDescuentosActivos {
  ListarDescuentosActivos(this._repositorio);
  final IDescuentoRepository _repositorio;

  Future<List<Descuento>> call() async {
    return _repositorio.listarDescuentosActivos();
  }
}
