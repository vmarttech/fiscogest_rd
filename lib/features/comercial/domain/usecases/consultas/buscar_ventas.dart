import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';

class BuscarVentas {
  BuscarVentas(this._repositorio);

  final IVentasRepository _repositorio;

  Future<List<Venta>> call({
    DateTime? desde,
    DateTime? hasta,
    String? clienteId,
    String? usuarioId,
  }) async {
    return _repositorio.listarVentas(
      desde: desde,
      hasta: hasta,
      clienteId: int.tryParse(clienteId ?? ''),
      usuarioId: int.tryParse(usuarioId ?? ''),
    );
  }
}
