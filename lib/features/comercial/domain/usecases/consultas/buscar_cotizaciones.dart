import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';

class BuscarCotizaciones {
  BuscarCotizaciones(this._repositorio);
  final IVentasRepository _repositorio;

  Future<List<Venta>> call({
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
