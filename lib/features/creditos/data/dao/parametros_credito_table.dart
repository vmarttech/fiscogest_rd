import 'package:drift/drift.dart';

@DataClassName('ParametroCreditoData')
class ParametrosCreditoTable extends Table {
  IntColumn get id => integer().autoIncrement().named('id')();

  RealColumn get tasaMensualDefault =>
      real().named('tasa_mensual_default').withDefault(const Constant(0.0))();

  IntColumn get cuotasDefault =>
      integer().named('cuotas_default').withDefault(const Constant(12))();

  IntColumn get plazoMaxMeses =>
      integer().named('plazo_max_meses').withDefault(const Constant(24))();

  IntColumn get diasGracia =>
      integer().named('dias_gracia').withDefault(const Constant(0))();

  RealColumn get moraPorcentaje =>
      real().named('mora_porcentaje').withDefault(const Constant(0.0))();

  TextColumn get plantillaSolicitud =>
      text().named('plantilla_solicitud').withDefault(const Constant(''))();

  TextColumn get plantillaContrato =>
      text().named('plantilla_contrato').withDefault(const Constant(''))();

  DateTimeColumn get actualizadoEn =>
      dateTime().named('actualizado_en').withDefault(currentDateAndTime)();
}
