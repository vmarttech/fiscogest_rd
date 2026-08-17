import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_table.dart';

@DataClassName('DevolucionData')
class DevolucionesTable extends Table {
  IntColumn get id => integer().autoIncrement().named('id')();
  IntColumn get ventaId => integer().named('venta_id').references(VentasTable, #id)();
  DateTimeColumn get fecha => dateTime().named('fecha')();
  TextColumn get motivo => text().named('motivo')();
  TextColumn get tipo => textEnum<DevolucionTipo>().named('tipo')();
  RealColumn get montoDevuelto => real().named('monto_devuelto')();
  TextColumn get estado => textEnum<DevolucionEstado>().named('estado').withDefault(const Constant('Registrada'))();
  BoolColumn get afectaInventario => boolean().named('afecta_inventario').withDefault(const Constant(true))();
  BoolColumn get afectaCaja => boolean().named('afecta_caja')();
}
