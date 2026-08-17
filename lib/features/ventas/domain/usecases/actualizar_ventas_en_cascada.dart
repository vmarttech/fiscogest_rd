import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';

class ActualizarVentasEnCascada {

  ActualizarVentasEnCascada(this._repository);
  final IVentasRepository _repository;

  Future<void> call(String ventaId) async {
    return await _repository.actualizarEnCascada(ventaId);
  }
}
