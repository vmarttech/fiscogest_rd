import 'package:fiscogest_rd/features/configuracion/domain/entities/configuracion_entity.dart';

abstract class IConfiguracionRepository {
  Future<ConfiguracionEntity?> obtenerConfiguracion();
  Future<void> guardarConfiguracion(ConfiguracionEntity configuracion);
}
