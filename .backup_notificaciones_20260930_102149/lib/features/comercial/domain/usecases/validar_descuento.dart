import 'package:fiscogest_rd/features/comercial/domain/entities/descuento.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_descuento_repository.dart';

class ValidarDescuento {
  ValidarDescuento(this._repositorio);
  final IDescuentoRepository _repositorio;

  Future<bool> call(Descuento descuento) async {
    if (!descuento.activo) return false;
    return _repositorio.validarDescuento(descuento);
  }
}
