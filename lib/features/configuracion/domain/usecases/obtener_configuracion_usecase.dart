import 'package:fiscogest_rd/features/configuracion/domain/entities/configuracion_entity.dart';
import 'package:fiscogest_rd/features/configuracion/domain/interfaces/i_configuracion_repository.dart';

class ObtenerConfiguracionUseCase {
  ObtenerConfiguracionUseCase(this._repo);
  // ✅ Constructor primero
  final IConfiguracionRepository _repo;

  Future<ConfiguracionEmpresa?> call() async {
    return await _repo.obtenerConfiguracion();
  }
}
