import 'package:drift/drift.dart';

/// Una sesión = un turno de caja (abierta hasta cerrar).
@DataClassName('CajaSesionData')
class CajaSesionesTable extends Table {
  IntColumn get id => integer().autoIncrement().named('id')();
  DateTimeColumn get fechaApertura =>
      dateTime().named('fecha_apertura')();
  RealColumn get fondoInicial => real().named('fondo_inicial')();
  IntColumn get usuarioId =>
      integer().named('usuario_id').withDefault(const Constant(1))();
  /// abierta | cerrada
  TextColumn get estado =>
      text().named('estado').withDefault(const Constant('abierta'))();
  DateTimeColumn get fechaCierre =>
      dateTime().named('fecha_cierre').nullable()();
  RealColumn get saldoTeorico =>
      real().named('saldo_teorico').nullable()();
  RealColumn get montoContado =>
      real().named('monto_contado').nullable()();
  RealColumn get diferencia =>
      real().named('diferencia').nullable()();
  TextColumn get observacion =>
      text().named('observacion').nullable()();
}
