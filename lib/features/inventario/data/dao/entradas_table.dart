import 'package:drift/drift.dart';

@DataClassName('EntradaData')
class EntradasTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  // ✅ NOMBRE PROPIEDAD: productoId, mapea a BD producto_id
  IntColumn get productoId => integer().named('producto_id')();
  RealColumn get cantidad => real()();
  // ✅ CAMPOS NUEVOS FALTANTES
  RealColumn get costoUnitario => real().named('costo_unitario').nullable()();
  TextColumn get motivo => text()();
  TextColumn get usuario => text()();
  IntColumn get fecha => integer()(); // almacenamos timestamp int
  TextColumn get observacion => text().nullable()();
}
