import 'package:drift/drift.dart';

@DataClassName('AjusteInventarioData')
class AjusteInventarioTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  // ✅ CORREGIDO nombre propiedad
  IntColumn get productoId => integer().named('id_producto')();
  TextColumn get tipoAjuste => text().named('tipo_ajuste')();
  RealColumn get cantidad => real()();
  TextColumn get motivo => text()();
  TextColumn get observaciones => text().nullable()();
  IntColumn get usuarioId => integer().named('usuario_id')();
  IntColumn get fechaCreacion => integer().named('fecha_creacion')();
}
