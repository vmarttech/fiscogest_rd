import 'package:drift/drift.dart';

/// Historial de pagos de un fiao - defensa ante "yo ya pague eso".
@DataClassName('AbonoFioData')
class AbonosFiaoTable extends Table {
  IntColumn get id => integer().autoIncrement().named('id')();
  IntColumn get fioId => integer().named('fio_id')();
  DateTimeColumn get fecha =>
      dateTime().named('fecha').withDefault(currentDateAndTime)();
  RealColumn get monto => real().named('monto')();
}
