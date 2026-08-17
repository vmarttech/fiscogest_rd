import 'package:fiscogest_rd/features/devoluciones/domain/repositories/i_devolucion_repository.dart';

class BuscarDevoluciones {
  BuscarDevoluciones(this._repositorio);
  final IDevolucionRepository _repositorio;

  Future<List<Map<String, dynamic>>> call({
    DateTime? desde,
    DateTime? hasta,
    String? clienteId,
    String? proveedorId,
    String? usuarioId,
    String? tipoOrigen,
  }) async {
    return _repositorio.listarDevoluciones(
      desde: desde,
      hasta: hasta,
      clienteId: int.tryParse(clienteId ?? ''),
      proveedorId: int.tryParse(proveedorId ?? ''),
      usuarioId: int.tryParse(usuarioId ?? ''),
      tipoOrigen: tipoOrigen,
    );
  }
}
