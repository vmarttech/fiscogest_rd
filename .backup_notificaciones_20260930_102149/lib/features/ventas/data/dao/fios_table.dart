import 'package:drift/drift.dart';

/// Fiao informal: deuda de palabra (colmado). No es crédito formal ni cuotas.
@DataClassName('FioData')
class FiosTable extends Table {
  IntColumn get id => integer().autoIncrement().named('id')();

  TextColumn get nombreCliente =>
      text().named('nombre_cliente').withLength(min: 1, max: 120)();

  RealColumn get montoOriginal => real().named('monto_original')();

  RealColumn get montoAbonado =>
      real().named('monto_abonado').withDefault(const Constant(0.0))();

  RealColumn get saldoPendiente => real().named('saldo_pendiente')();

  DateTimeColumn get fecha =>
      dateTime().named('fecha').withDefault(currentDateAndTime)();

  TextColumn get nota => text().named('nota').nullable()();

  /// pendiente | pagado
  TextColumn get estado =>
      text().named('estado').withDefault(const Constant('pendiente'))();

  /// Opcional: vínculo a cotización/venta si existió
  IntColumn get ventaId => integer().named('venta_id').nullable()();
}
