import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_table.dart';

@DataClassName('CobroData')
class CobrosTable extends Table {
  IntColumn get id => integer().autoIncrement().named('id')();
  IntColumn get cuentaCobrarId => integer()
      .named('cuenta_cobrar_id')
      .references(CuentasCobrarTable, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get fecha => dateTime().named('fecha')();
  RealColumn get montoAbonado => real().named('monto_abonado')();
  TextColumn get formaPago => textEnum<FormaPago>().named('forma_pago')();
  RealColumn get saldoAnterior => real().named('saldo_anterior')();
  RealColumn get saldoActual => real().named('saldo_actual')();
}
