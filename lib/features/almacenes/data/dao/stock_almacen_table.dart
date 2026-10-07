import 'package:drift/drift.dart';

@DataClassName('StockAlmacenData')
class StockAlmacenTable extends Table {
  @override
  String get tableName => 'stock_almacen';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get productoId => integer()();
  IntColumn get almacenId => integer()();
  RealColumn get cantidad => real().withDefault(const Constant(0.0))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {productoId, almacenId},
      ];
}
