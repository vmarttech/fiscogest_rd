import 'package:drift/drift.dart';

class NotasCreditoTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get ncf => text()();
  TextColumn get ncfFacturaOrigen => text().named('ncf_factura_origen')();
  IntColumn get ventaIdOrigen => integer().named('venta_id_origen')();
  TextColumn get numeroCotizacion =>
      text().named('numero_cotizacion').withDefault(const Constant(''))();
  TextColumn get nombreCliente => text().named('nombre_cliente').nullable()();
  RealColumn get monto => real().withDefault(const Constant(0.0))();
  TextColumn get motivo => text().withDefault(const Constant(''))();
  DateTimeColumn get creadoEn =>
      dateTime().named('creado_en').withDefault(currentDateAndTime)();
}
