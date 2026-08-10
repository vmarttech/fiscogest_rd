import 'package:fiscogest_rd/features/configuracion/domain/entities/configuracion_entity.dart';
import 'package:fiscogest_rd/features/configuracion/domain/interfaces/i_configuracion_repository.dart';

class GuardarConfiguracionUseCase {
  GuardarConfiguracionUseCase(this._repo);
  // ✅ Constructor primero
  final IConfiguracionRepository _repo;

  Future<void> call(ConfiguracionEmpresa datos) async {
    await _repo.guardarConfiguracion(datos);
  }
}
