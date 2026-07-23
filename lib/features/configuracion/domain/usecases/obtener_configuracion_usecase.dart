import '../entities/configuracion_entity.dart';
import '../interfaces/i_configuracion_repository.dart';

class ObtenerConfiguracionUseCase {
  final IConfiguracionRepository _repository;
  ObtenerConfiguracionUseCase(this._repository);

  Future<ConfiguracionEntity?> ejecutar() async {
    return await _repository.obtenerConfiguracion();
  }
}