import 'package:drift/drift.dart';

class VentasTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get clienteId => integer()();
  TextColumn get nombreCliente => text().nullable()();
  TextColumn get clienteTelefono => text().nullable()();
  TextColumn get clienteWhatsapp => text().nullable()();
  TextColumn get clienteDireccion => text().nullable()();
  DateTimeColumn get fecha => dateTime()();
  RealColumn get montoSubtotal => real().withDefault(const Constant(0.0))();
  RealColumn get descuentoGlobal => real().withDefault(const Constant(0.0))();
  RealColumn get itbis => real().withDefault(const Constant(0.0))();
  RealColumn get montoTotal => real().withDefault(const Constant(0.0))();
  TextColumn get formaPago => text()();
  RealColumn get costoEnvio => real().withDefault(const Constant(0.0))();
  RealColumn get abonoInicial => real().withDefault(const Constant(0.0))();
  IntColumn get numeroCuotas =>
      integer().named('numero_cuotas').withDefault(const Constant(1))();
  IntColumn get plazoDias =>
      integer().named('plazo_dias').withDefault(const Constant(30))();
  RealColumn get tasaInteres =>
      real().named('tasa_interes').withDefault(const Constant(0.0))();
  RealColumn get montoInteres =>
      real().named('monto_interes').withDefault(const Constant(0.0))();
  DateTimeColumn get vencimiento => dateTime().nullable()();
  TextColumn get numeroCotizacion => text()();
  TextColumn get numeroFactura => text().nullable()();
  TextColumn get estadoDocumento => text()();
  IntColumn get usuarioId => integer()();
  DateTimeColumn get fechaRegistro => dateTime()();
  IntColumn get descuentoId => integer().nullable()();
  TextColumn get descuentoNombre => text().nullable()();
  RealColumn get montoDescuento => real().withDefault(const Constant(0.0))();
  BoolColumn get comprobanteEntregaImpreso =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get fechaComprobanteEntrega => dateTime().nullable()();
}
