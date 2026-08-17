import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/clientes/data/dao/clientes_table.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_table.dart';

@DataClassName('CotizacionData')
class CotizacionesTable extends Table {
  IntColumn get id => integer().autoIncrement().named('id')();
  IntColumn get clienteId => integer().named('cliente_id').references(ClientesTable, #id)();
  DateTimeColumn get fechaEmision => dateTime().named('fecha_emision')();
  DateTimeColumn get fechaVigencia => dateTime().named('fecha_vigencia')();
  RealColumn get montoSubtotal => real().named('monto_subtotal')();
  RealColumn get descuentoGlobal => real().named('descuento_global').withDefault(const Constant(0.0))();
  RealColumn get itbis => real().named('itbis')();
  RealColumn get montoTotal => real().named('monto_total')();
  TextColumn get estado => textEnum<CotizacionEstado>().named('estado').withDefault(const Constant('Pendiente'))();
  IntColumn get ventaConvertidaId => integer().named('venta_convertida_id').nullable().references(VentasTable, #id)();
  TextColumn get observaciones => text().named('observaciones').nullable()();
}
