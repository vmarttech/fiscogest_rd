import 'package:fiscogest_rd/features/devoluciones/domain/repositories/i_devolucion_repository.dart';

class BuscarDevoluciones {
  BuscarDevoluciones(this._repositorio);
  final IDevolucionRepository _repositorio;

  Future<List<Map<String, dynamic>>> call({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    int? proveedorId,
    int? usuarioId,
    String? tipoOrigen,
  }) async {
    return _repositorio.listarDevoluciones(
      desde: desde,
      hasta: hasta,
      clienteId: clienteId,
      proveedorId: proveedorId,
      usuarioId: usuarioId,
      tipoOrigen: tipoOrigen,
    );
  }
}
