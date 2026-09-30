import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/creditos/data/dao/solicitudes_credito_table.dart';

@DataClassName('ReferenciaCreditoData')
class ReferenciasCreditoTable extends Table {
  IntColumn get id => integer().autoIncrement().named('id')();

  IntColumn get solicitudId => integer()
      .named('solicitud_id')
      .references(SolicitudesCreditoTable, #id, onDelete: KeyAction.cascade)();

  TextColumn get nombre =>
      text().named('nombre').withDefault(const Constant(''))();
  TextColumn get relacion =>
      text().named('relacion').withDefault(const Constant(''))();
  TextColumn get telefono =>
      text().named('telefono').withDefault(const Constant(''))();
  TextColumn get direccion =>
      text().named('direccion').withDefault(const Constant(''))();
  IntColumn get orden =>
      integer().named('orden').withDefault(const Constant(1))();
}
