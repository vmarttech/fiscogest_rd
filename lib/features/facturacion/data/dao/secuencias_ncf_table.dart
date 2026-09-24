import 'package:drift/drift.dart';

/// Rangos NCF autorizados (emisión de facturas de venta).
class SecuenciasNcfTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  /// B01, B02, B04, ...
  TextColumn get tipo => text()();
  /// Prefijo impreso en el NCF (normalmente igual al tipo).
  TextColumn get prefijo => text()();
  IntColumn get secuenciaActual => integer()
      .named('secuencia_actual')
      .withDefault(const Constant(0))();
  IntColumn get secuenciaDesde => integer()
      .named('secuencia_desde')
      .withDefault(const Constant(1))();
  IntColumn get secuenciaHasta => integer()
      .named('secuencia_hasta')
      .withDefault(const Constant(99999999))();
  BoolColumn get activo =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get actualizadoEn => dateTime()
      .named('actualizado_en')
      .withDefault(currentDateAndTime)();
}
