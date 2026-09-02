import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/compras_table.dart';

class DetalleCompraTable extends Table {
  IntColumn get id => integer()();
  IntColumn get compraId =>
      integer().references(ComprasTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get productoId => integer()();
  TextColumn get nombreProducto => text()();
  RealColumn get cantidad => real()();
  RealColumn get costoUnitario => real()();
  RealColumn get descuentoPorcentaje => real()();
  RealColumn get montoDescuentoLinea => real()();
  RealColumn get subtotalLinea => real()();

  @override
  Set<Column> get primaryKey => {id};
}
