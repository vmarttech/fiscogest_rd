import 'package:drift/drift.dart';

/// Licencia local del equipo (offline-first).
class LicenciasTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// gratis | basico | simplificado | pro | aliases históricos
  TextColumn get plan => text()();

  /// prueba | mensual | trimestral | semestral | anual | vitalicia
  TextColumn get vigenciaTipo => text()();

  TextColumn get fechaInicio => text()();
  TextColumn get fechaFin => text().nullable()();

  IntColumn get maxDispositivos => integer().withDefault(const Constant(1))();
  IntColumn get maxCajas => integer().withDefault(const Constant(1))();

  BoolColumn get ecfHabilitado =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get vitalicia => boolean().withDefault(const Constant(false))();

  /// activa | gracia | vencida | no_activada | registro_requerido
  TextColumn get estado => text()();

  TextColumn get fingerprint => text().nullable()();
  TextColumn get codigoActivacion => text().nullable()();
  TextColumn get payloadFirma => text().nullable()();
  TextColumn get actualizadoEn => text()();
}
