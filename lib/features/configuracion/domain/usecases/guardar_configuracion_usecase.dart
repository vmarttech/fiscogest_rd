import 'package:fiscogest_rd/features/configuracion/domain/entities/configuracion_entity.dart';
import 'package:fiscogest_rd/features/configuracion/domain/interfaces/i_configuracion_repository.dart';

class GuardarConfiguracionUseCase {
  GuardarConfiguracionUseCase(this._repository);
  final IConfiguracionRepository _repository;

  Future<void> ejecutar(ConfiguracionEntity configuracion) async {
    await _repository.guardarConfiguracion(configuracion);
  }
}