import 'package:fiscogest_rd/features/ventas/domain/entities/apartado.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';

class RegistrarApartado {

  RegistrarApartado(this._repository);
  final IVentasRepository _repository;

  Future<Apartado> call(Apartado apartado) async {
    return await _repository.registrarApartado(apartado);
  }
}
