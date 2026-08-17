import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/inventario/data/dao/productos_table.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

@DataClassName('KardexComercialData')
class KardexComercialTable extends Table {
  IntColumn get id => integer().autoIncrement().named('id')();
  IntColumn get productoId => integer().named('producto_id').references(ProductosTable, #id)();
  TextColumn get tipoMovimiento => textEnum<MovimientoInventario>().named('tipo_movimiento')();
  TextColumn get referenciaTipo => textEnum<ReferenciaTipo>().named('referencia_tipo')();
  IntColumn get referenciaId => integer().named('referencia_id')();
  RealColumn get cantidad => real().named('cantidad')();
  RealColumn get stockAnterior => real().named('stock_anterior')();
  RealColumn get stockNuevo => real().named('stock_nuevo')();
  DateTimeColumn get fecha => dateTime().named('fecha').withDefault(currentDateAndTime)();
}
