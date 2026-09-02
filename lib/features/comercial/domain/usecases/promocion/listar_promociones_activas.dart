import 'package:fiscogest_rd/features/comercial/domain/entities/promocion.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_promocion_repository.dart';

class ListarPromocionesActivas {
  const ListarPromocionesActivas(this._repositorio);
  final IPromocionRepository _repositorio;

  Future<List<Promocion>> ejecutar({DateTime? fechaReferencia}) async {
    final fecha = fechaReferencia ?? DateTime.now();
    return _repositorio.listarActivas(fecha);
  }
}
