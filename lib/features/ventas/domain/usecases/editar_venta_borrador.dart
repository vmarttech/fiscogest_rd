import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';

class EditarVentaBorrador {
  EditarVentaBorrador(this._repository);
  final IVentasRepository _repository;

  Future<Venta> call(Venta cotizacion) async {
    return await _repository.actualizarVentaBorrador(cotizacion);
  }
}
