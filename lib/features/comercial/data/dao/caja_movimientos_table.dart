import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

@DataClassName('CajaMovimientoData')
class CajaMovimientosTable extends Table {
  IntColumn get id => integer().autoIncrement().named('id')();
  TextColumn get tipo => textEnum<MovimientoCaja>().named('tipo')();
  TextColumn get referenciaTipo => textEnum<ReferenciaTipo>().named('referencia_tipo')();
  IntColumn get referenciaId => integer().named('referencia_id')();
  RealColumn get monto => real().named('monto')();
  TextColumn get formaPago => textEnum<FormaPago>().named('forma_pago')();
  RealColumn get saldoAnterior => real().named('saldo_anterior')();
  RealColumn get saldoNuevo => real().named('saldo_nuevo')();
  DateTimeColumn get fecha => dateTime().named('fecha').withDefault(currentDateAndTime)();
}
