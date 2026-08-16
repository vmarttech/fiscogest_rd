import 'package:drift/drift.dart';

@DataClassName('ExistenciaData')
class ExistenciasTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  // ✅ productoId → producto_id
  IntColumn get productoId => integer().named('id_producto')();
  RealColumn get existenciaActual => real().named('existencia_actual')();
  RealColumn get existenciaDisponible => real().named('existencia_disponible')();
  // ✅ CAMPOS NUEVOS
  TextColumn get ubicacion => text().nullable()();
  IntColumn get fechaActualizacion => integer().named('fecha_actualizacion').nullable()();
}
