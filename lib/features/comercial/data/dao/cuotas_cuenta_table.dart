import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_table.dart';

/// Cuota de un plan de pago de cuenta por cobrar.
@DataClassName('CuotaCuentaData')
class CuotasCuentaTable extends Table {
  IntColumn get id => integer().autoIncrement().named('id')();
  IntColumn get cuentaCobrarId => integer()
      .named('cuenta_cobrar_id')
      .references(CuentasCobrarTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get numero => integer().named('numero')();
  RealColumn get monto => real().named('monto')();
  RealColumn get montoPagado =>
      real().named('monto_pagado').withDefault(const Constant(0.0))();
  DateTimeColumn get fechaVencimiento =>
      dateTime().named('fecha_vencimiento')();

  /// pendiente | parcial | pagada
  TextColumn get estado =>
      text().named('estado').withDefault(const Constant('pendiente'))();
  DateTimeColumn get fechaPago => dateTime().named('fecha_pago').nullable()();
}
