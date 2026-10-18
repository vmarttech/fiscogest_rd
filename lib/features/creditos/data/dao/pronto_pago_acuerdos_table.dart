import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_table.dart';

/// Acuerdo de liquidación anticipada (descuento solo sobre intereses).
/// No altera el plan de cuotas hasta que se cobra en Caja (estado = aplicado).
@DataClassName('ProntoPagoAcuerdoData')
class ProntoPagoAcuerdosTable extends Table {
  @override
  String get tableName => 'pronto_pago_acuerdos';

  IntColumn get id => integer().autoIncrement().named('id')();

  IntColumn get cuentaId => integer()
      .named('cuenta_id')
      .references(CuentasCobrarTable, #id)();

  /// Solo uno activo por cuenta: se cancela el anterior al crear otro.
  TextColumn get estado =>
      text().named('estado').withDefault(const Constant('activo'))();
  // activo | cancelado | aplicado

  RealColumn get capitalPendiente =>
      real().named('capital_pendiente')();

  RealColumn get interesPendiente =>
      real().named('interes_pendiente')();

  RealColumn get descuentoInteresPct =>
      real().named('descuento_interes_pct').withDefault(const Constant(0.0))();

  RealColumn get descuentoMonto =>
      real().named('descuento_monto').withDefault(const Constant(0.0))();

  RealColumn get interesTrasDescuento =>
      real().named('interes_tras_descuento')();

  /// Monto que Caja debe cobrar para liquidar.
  RealColumn get montoLiquidacion =>
      real().named('monto_liquidacion')();

  IntColumn get cuotasPendientes =>
      integer().named('cuotas_pendientes').withDefault(const Constant(0))();

  TextColumn get notas =>
      text().named('notas').withDefault(const Constant(''))();

  IntColumn get usuarioId =>
      integer().named('usuario_id').nullable()();

  DateTimeColumn get creadoEn =>
      dateTime().named('creado_en').withDefault(currentDateAndTime)();

  DateTimeColumn get aplicadoEn =>
      dateTime().named('aplicado_en').nullable()();
}
