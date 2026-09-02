import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/inventario/data/dao/productos_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/devoluciones_table.dart';

@DataClassName('DevolucionDetalleData')
class DevolucionesDetalleTable extends Table {
  IntColumn get id => integer().autoIncrement().named('id')();
  IntColumn get devolucionId => integer()
      .named('devolucion_id')
      .references(DevolucionesTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get productoId =>
      integer().named('producto_id').references(ProductosTable, #id)();
  RealColumn get cantidad => real().named('cantidad')();
  RealColumn get precioUnitario => real().named('precio_unitario')();
  RealColumn get subtotal => real().named('subtotal')();
  TextColumn get motivoLinea => text().named('motivo_linea').nullable()();
}
