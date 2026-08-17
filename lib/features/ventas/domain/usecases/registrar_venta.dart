import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';

class RegistrarVenta {

  RegistrarVenta(this._repository);
  final IVentasRepository _repository;

  Future<Venta> call(Venta venta) async {
    return await _repository.registrarVenta(venta);
  }
}
