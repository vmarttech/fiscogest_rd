import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/inventario/data/dao/productos_table.dart';

@DataClassName('ExistenciaData')
class ExistenciasTable extends Table {
  // ✅ SINTAXIS IGUAL A PRODUCTOS/ENTRADAS/SALIDAS → elimina error aliasedName
  IntColumn get id => integer().autoIncrement()();

  IntColumn get idProducto => integer()
      .references(ProductosTable, #id, onDelete: KeyAction.cascade)();

  RealColumn get existenciaActual => real()();

  RealColumn get existenciaDisponible => real()();

  @override
  Set<Column> get primaryKey => {id};
}
