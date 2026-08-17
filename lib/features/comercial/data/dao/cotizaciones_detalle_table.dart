import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/inventario/data/dao/productos_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cotizaciones_table.dart';

@DataClassName('CotizacionDetalleData')
class CotizacionesDetalleTable extends Table {
  IntColumn get id => integer().autoIncrement().named('id')();
  IntColumn get cotizacionId => integer().named('cotizacion_id').references(CotizacionesTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get productoId => integer().named('producto_id').references(ProductosTable, #id)();
  RealColumn get cantidad => real().named('cantidad')();
  RealColumn get precioUnitario => real().named('precio_unitario')();
  RealColumn get descuentoLinea => real().named('descuento_linea').withDefault(const Constant(0.0))();
  RealColumn get subtotal => real().named('subtotal')();
}
