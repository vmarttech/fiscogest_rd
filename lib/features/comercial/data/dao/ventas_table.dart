import 'package:drift/drift.dart';

class VentasTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get clienteId => integer()();
  TextColumn get nombreCliente => text().nullable()();
  DateTimeColumn get fecha => dateTime()();
  RealColumn get montoSubtotal => real().withDefault(const Constant(0.0))();
  RealColumn get descuentoGlobal => real().withDefault(const Constant(0.0))();
  RealColumn get itbis => real().withDefault(const Constant(0.0))();
  RealColumn get montoTotal => real().withDefault(const Constant(0.0))();
  TextColumn get formaPago => text()();
  RealColumn get costoEnvio => real().withDefault(const Constant(0.0))();
  RealColumn get abonoInicial => real().withDefault(const Constant(0.0))();
  DateTimeColumn get vencimiento => dateTime().nullable()();
  TextColumn get numeroCotizacion => text()();
  TextColumn get numeroFactura => text().nullable()();
  TextColumn get estadoDocumento => text()();
  IntColumn get usuarioId => integer()();
  DateTimeColumn get fechaRegistro => dateTime()();
  IntColumn get descuentoId => integer().nullable()();
  TextColumn get descuentoNombre => text().nullable()();
  RealColumn get montoDescuento => real().withDefault(const Constant(0.0))();
}
