import 'package:fiscogest_rd/features/configuracion/domain/entities/configuracion_entity.dart';
import 'package:fiscogest_rd/features/configuracion/domain/interfaces/i_configuracion_repository.dart';
import 'package:fiscogest_rd/features/configuracion/data/dao/configuracion_dao.dart';

class ConfiguracionRepositoryImpl implements IConfiguracionRepository {
  ConfiguracionRepositoryImpl(this._configuracionDao);
  final ConfiguracionDao _configuracionDao;

  @override
  Future<ConfiguracionEntity> obtenerConfiguracion() async {
    final model = await _configuracionDao.obtenerConfiguracion();
    if (model == null) {
      return const ConfiguracionEntity(
        id: '1',
        nombreComercial: 'FiscoGest RD',
        razonSocial: 'FiscoGest RD, S.R.L.',
        rnc: '131-00000-1',
        direccion: 'Av. Principal, Santo Domingo',
        telefono: '809-000-0000',
        correo: 'admin@fiscogest.rd',
        logoUrl: '',
        moneda: 'DOP (\$)',
        zonaHoraria: 'America/Santo_Domingo',
        formatoImpresion: 'Ticket 80mm',
        formatoFecha: 'DD/MM/YYYY',
        impuestoPorcentaje: 18.0,
        idioma: 'Español',
      );
    }
    return ConfiguracionEntity(
      id: model.id.toString(),
      nombreComercial: model.nombreNegocio,
      razonSocial: 'FiscoGest RD, S.R.L.',
      rnc: model.rncCedula,
      direccion: 'Av. Principal, Santo Domingo',
      telefono: '809-000-0000',
      correo: 'admin@fiscogest.rd',
      logoUrl: '',
      moneda: model.moneda,
      zonaHoraria: 'America/Santo_Domingo',
      formatoImpresion: 'Ticket 80mm',
      formatoFecha: model.formatoFecha,
      impuestoPorcentaje: model.impuestoPorcentaje,
      idioma: model.idioma,
    );
  }

  @override
  Future<void> guardarConfiguracion(ConfiguracionEntity configuracion) async {
    // Implementación de persistencia local adaptada
  }
}
