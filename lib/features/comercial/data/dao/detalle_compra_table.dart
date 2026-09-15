import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/compras_table.dart';

class DetalleCompraTable extends Table {
  IntColumn get id => integer()();
  IntColumn get compraId =>
      integer().references(ComprasTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get productoId => integer()();
  TextColumn get nombreProducto => text()();
  RealColumn get cantidad => real().nullable()();
  RealColumn get costoUnitario => real().nullable()();
  RealColumn get fleteUnitario => real().nullable().withDefault(const Constant(0.0))();
  RealColumn get seguroUnitario => real().nullable().withDefault(const Constant(0.0))();
  RealColumn get arancelesUnitario => real().nullable().withDefault(const Constant(0.0))();
  RealColumn get gastosUnitario => real().nullable().withDefault(const Constant(0.0))();
  RealColumn get descuentoPorcentaje => real().nullable()();
  RealColumn get montoDescuentoLinea => real().nullable()();
  RealColumn get subtotalLinea => real().nullable()();
  RealColumn get costoAdquisicion => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
