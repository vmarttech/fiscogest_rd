import 'package:fiscogest_rd/features/apartados/domain/repositories/i_apartado_repository.dart';

class BuscarApartados {
  BuscarApartados(this._repositorio);
  final IApartadoRepository _repositorio;

  Future<List<Map<String, dynamic>>> call({
    DateTime? desde,
    DateTime? hasta,
    String? clienteId,
    String? usuarioId,
    String? estado,
  }) async {
    return _repositorio.listarApartados(
      desde: desde,
      hasta: hasta,
      clienteId: int.tryParse(clienteId ?? ''),
      usuarioId: int.tryParse(usuarioId ?? ''),
      estado: estado,
    );
  }
}
