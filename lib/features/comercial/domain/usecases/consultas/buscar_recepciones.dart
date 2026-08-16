import 'package:fiscogest_rd/features/comercial/domain/repositories/i_recepcion_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/recepcion.dart';

class BuscarRecepciones {
  BuscarRecepciones(this._repositorio);
  final IRecepcionRepository _repositorio;

  Future<List<Recepcion>> call({
    DateTime? desde,
    DateTime? hasta,
    String? proveedorId,
    String? compraId,
  }) async {
    final List<Recepcion> todas = await _repositorio.listarTodos(desde: desde, hasta: hasta);

    return todas.where((recepcion) {
      if (proveedorId != null && recepcion.proveedorId != proveedorId) return false;
      if (compraId != null && recepcion.compraId != compraId) return false;
      return true;
    }).toList();
  }
}
