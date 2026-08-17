import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/inventario/data/dao/productos_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_table.dart';

@DataClassName('VentaDetalleData')
class VentasDetalleTable extends Table {
  IntColumn get id => integer().autoIncrement().named('id')();
  IntColumn get ventaId => integer().named('venta_id').references(VentasTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get productoId => integer().named('producto_id').references(ProductosTable, #id)();
  RealColumn get cantidad => real().named('cantidad')();
  RealColumn get precioUnitario => real().named('precio_unitario')();
  RealColumn get descuentoLinea => real().named('descuento_linea').withDefault(const Constant(0.0))();
  RealColumn get subtotal => real().named('subtotal')();
  RealColumn get impuesto => real().named('impuesto')();
}
