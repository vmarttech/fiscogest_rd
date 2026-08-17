import 'package:drift/drift.dart';

@DataClassName('UsuarioData')
class UsuariosTable extends Table {
  IntColumn get id => integer().autoIncrement().named('id')();
  TextColumn get nombre => text().named('nombre')();
  TextColumn get apellido => text().named('apellido').nullable()();
  TextColumn get email => text().named('email').unique().nullable()();
  TextColumn get username => text().named('username').unique()();
  TextColumn get passwordHash => text().named('password_hash')();
  TextColumn get rol => text().named('rol').withDefault(const Constant('Vendedor'))();
  TextColumn get estado => text().named('estado').withDefault(const Constant('Activo'))();
  DateTimeColumn get fechaCreacion => dateTime().named('fecha_creacion').withDefault(currentDateAndTime)();
  DateTimeColumn get fechaUltimoAcceso => dateTime().named('fecha_ultimo_acceso').nullable()();
}
