import '../entities/configuracion_entity.dart';
import '../interfaces/i_configuracion_repository.dart';

class GuardarConfiguracionUseCase {
  final IConfiguracionRepository _repository;
  GuardarConfiguracionUseCase(this._repository);

  Future<void> ejecutar(ConfiguracionEntity configuracion) async {
    await _repository.guardarConfiguracion(configuracion);
  }
}