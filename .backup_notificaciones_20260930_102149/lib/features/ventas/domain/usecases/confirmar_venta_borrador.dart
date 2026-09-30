import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';

class ConfirmarVentaBorrador {
  ConfirmarVentaBorrador(this._repository);

  final IVentasRepository _repository;

  Future<Venta> call(int cotizacionId) async {
    return await _repository.confirmarVentaBorrador(cotizacionId);
  }
}
