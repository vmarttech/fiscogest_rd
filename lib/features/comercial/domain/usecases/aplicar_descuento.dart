import 'package:fiscogest_rd/features/comercial/domain/entities/descuento.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_descuento_repository.dart';

class AplicarDescuento {
  AplicarDescuento(this._repositorio);
  final IDescuentoRepository _repositorio;

  Future<double> call({
    required Descuento descuento,
    required double montoOriginal,
  }) async {
    if (montoOriginal <= 0) return 0.0;
    return _repositorio.aplicarDescuento(
      descuento: descuento,
      montoOriginal: montoOriginal,
    );
  }
}
