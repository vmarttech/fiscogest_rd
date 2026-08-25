import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';

class BuscarCotizaciones {
  BuscarCotizaciones(this._repositorio);
  final ICotizacionRepository _repositorio;

  Future<List<Map<String, dynamic>>> call({
    DateTime? desde,
    DateTime? hasta,
    String? clienteId,
    String? usuarioId,
  }) async {
    return _repositorio.listarCotizaciones(
      desde: desde,
      hasta: hasta,
      clienteId: int.tryParse(clienteId ?? ''),
      usuarioId: int.tryParse(usuarioId ?? ''),
    );
  }
}
