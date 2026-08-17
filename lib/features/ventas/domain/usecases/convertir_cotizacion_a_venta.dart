import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';

class ConvertirCotizacionAVenta {
  ConvertirCotizacionAVenta(this._repository);
  final IVentasRepository _repository;

  Future<Venta> call(String cotizacionId) async {
    return await _repository.convertirCotizacionAVenta(int.parse(cotizacionId));
  }
}
