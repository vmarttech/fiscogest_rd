import 'package:fiscogest_rd/features/ventas/domain/entities/devolucion.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';

class RegistrarDevolucion {

  RegistrarDevolucion(this._repository);
  final IVentasRepository _repository;

  Future<Devolucion> call(Devolucion devolucion) async {
    return await _repository.registrarDevolucion(devolucion);
  }
}
