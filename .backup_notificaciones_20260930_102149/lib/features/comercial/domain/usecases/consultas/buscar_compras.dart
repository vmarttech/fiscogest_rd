import 'package:fiscogest_rd/features/comercial/domain/repositories/i_compra_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';

class BuscarCompras {
  BuscarCompras(this._repositorio);
  final ICompraRepository _repositorio;

  Future<List<Compra>> call({
    DateTime? desde,
    DateTime? hasta,
    int? proveedorId,
  }) async {
    final List<Compra> todas = await _repositorio.listarCompras();
    return todas.where((compra) {
      if (desde != null && compra.fechaEmision.isBefore(desde)) return false;
      if (hasta != null && compra.fechaEmision.isAfter(hasta)) return false;
      if (proveedorId != null && compra.proveedorId != proveedorId) {
        return false;
      }
      return true;
    }).toList();
  }
}
