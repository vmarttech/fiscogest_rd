import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/compras_table.dart';

class DetalleCompraTable extends Table {
  TextColumn get id => text()();
  TextColumn get compraId => text().references(ComprasTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get productoId => text()();
  TextColumn get nombreProducto => text()();
  RealColumn get cantidad => real()();
  RealColumn get costoUnitario => real()();
  RealColumn get descuentoPorcentaje => real()();
  RealColumn get montoDescuentoLinea => real()();
  RealColumn get subtotalLinea => real()();

  @override
  Set<Column> get primaryKey => {id};
}
