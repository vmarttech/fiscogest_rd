import 'package:fiscogest_rd/features/configuracion/domain/entities/configuracion_entity.dart';

abstract class IConfiguracionRepository {
  Future<ConfiguracionEmpresa?> obtenerConfiguracion();
  Future<void> guardarConfiguracion(ConfiguracionEmpresa configuracion);
}