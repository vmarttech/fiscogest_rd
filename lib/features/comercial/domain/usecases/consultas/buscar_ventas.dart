import 'package:fiscogest_rd/features/ventas/domain/repositories/i_venta_repository.dart';

class BuscarVentas {
  BuscarVentas(this._repositorio);
  final IVentaRepository _repositorio;

  Future<List<Map<String, dynamic>>> call({
    DateTime? desde,
    DateTime? hasta,
    String? clienteId,
    String? usuarioId,
  }) async {
    return _repositorio.listarVentas(
      desde: desde,
      hasta: hasta,
      clienteId: clienteId,
      usuarioId: usuarioId,
    );
  }
}
