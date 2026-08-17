import 'package:drift/drift.dart';

@DataClassName('ProveedorData')
class ProveedoresTable extends Table {
  IntColumn get id => integer().autoIncrement().named('id')();
  TextColumn get nombreEmpresa => text().named('nombre_empresa')();
  TextColumn get nombreContacto => text().named('nombre_contacto').nullable()();
  TextColumn get rnc => text().named('rnc').unique().nullable()();
  TextColumn get telefono => text().named('telefono').nullable()();
  TextColumn get celular => text().named('celular').nullable()();
  TextColumn get email => text().named('email').nullable()();
  TextColumn get direccion => text().named('direccion').nullable()();
  TextColumn get ciudad => text().named('ciudad').nullable()();
  TextColumn get provincia => text().named('provincia').nullable()();
  IntColumn get diasCredito => integer().named('dias_credito').withDefault(const Constant(0))();
  TextColumn get estado => text().named('estado').withDefault(const Constant('Activo'))();
  DateTimeColumn get fechaCreacion => dateTime().named('fecha_creacion').withDefault(currentDateAndTime)();
  DateTimeColumn get fechaActualizacion => dateTime().named('fecha_actualizacion').nullable()();
}
