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

  /// Fecha compromiso de pago. Null = regla por defecto (15 dias).
  DateTimeColumn get fechaCompromiso =>
      dateTime().named('fecha_compromiso').nullable()();

  /// Vínculo opcional al cliente del catálogo (cuando se eligió de la lista).
  IntColumn get clienteId => integer().named('cliente_id').nullable()();

  /// Teléfono/WhatsApp capturado al anotar (o rellenado después).
  /// Permite avisar sin depender solo del match por nombre.
  TextColumn get telefono => text().named('telefono').nullable()();
}
