import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/configuracion/domain/entities/configuracion_entity.dart';
import 'package:fiscogest_rd/features/configuracion/domain/interfaces/i_configuracion_repository.dart';
// ✅ QUITADO import sin uso que generaba advertencia

class ConfiguracionRepositoryImpl implements IConfiguracionRepository {
  ConfiguracionRepositoryImpl(this.db);
  // ✅ CONSTRUCTOR PRIMERO: corrige aviso sort_constructors_first
  final AppDatabase db;

  @override
  Future<ConfiguracionEmpresa?> obtenerConfiguracion() async {
    final registro = await db.select(db.configuracionTable).getSingleOrNull();
    if (registro != null) {
      return ConfiguracionEmpresa(
        id: registro.id,
        nombreComercial: registro.nombreNegocio,
        razonSocial: registro.nombreNegocio,
        rnc: registro.rncCedula,
        direccion: '',
        telefono: '',
        correo: '',
        logoUrl: '',
        moneda: registro.moneda,
        zonaHoraria: '',
        formatoImpresion: '',
        formatoFecha: registro.formatoFecha,
        impuestoPorcentaje: registro.impuestoPorcentaje,
        idioma: registro.idioma,
      );
    }
    return null;
  }

  @override
  Future<void> guardarConfiguracion(ConfiguracionEmpresa configuracion) async {
    // ✅ RESUELTO int? → int: validación + conversión segura
    if (configuracion.id != null) {
      final idSeguro = configuracion.id!;
      await db.update(db.configuracionTable).replace(
        ConfiguracionTableCompanion(
          id: Value(idSeguro),
          nombreNegocio: Value(configuracion.nombreComercial),
          rncCedula: Value(configuracion.rnc),
          moneda: Value(configuracion.moneda),
          formatoFecha: Value(configuracion.formatoFecha),
          impuestoPorcentaje: Value(configuracion.impuestoPorcentaje),
          idioma: Value(configuracion.idioma),
        ),
      );
    } else {
      // ✅ SINTAXIS DRIFT CORREGIDA: usa into + insert correcto
      await db.into(db.configuracionTable).insert(
        ConfiguracionTableCompanion(
          nombreNegocio: Value(configuracion.nombreComercial),
          rncCedula: Value(configuracion.rnc),
          moneda: Value(configuracion.moneda),
          formatoFecha: Value(configuracion.formatoFecha),
          impuestoPorcentaje: Value(configuracion.impuestoPorcentaje),
          idioma: Value(configuracion.idioma),
        ),
      );
    }
  }
}
