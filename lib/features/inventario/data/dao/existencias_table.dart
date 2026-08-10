import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/inventario/data/dao/productos_table.dart';

@DataClassName('ExistenciaData')
class ExistenciasTable extends Table {
  // ✅ Clave primaria automática: autoIncrement() ya define la PK internamente
  // ✅ Eliminada declaración manual duplicada de primaryKey que bloqueaba generación
  IntColumn get id => integer().autoIncrement()();

  // ✅ Relación intacta con ProductosTable, restricción eliminación conservada
  IntColumn get idProducto => integer()
      .references(ProductosTable, #id, onDelete: KeyAction.cascade)();

  // ✅ Campos definidos según ETAPA 3.1 Existencias: cumpliendo propósito del documento maestro
  RealColumn get existenciaActual => real()();

  RealColumn get existenciaDisponible => real()();
}
