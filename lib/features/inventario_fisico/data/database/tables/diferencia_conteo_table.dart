import 'package:drift/drift.dart';

@DataClassName('DiferenciaConteoData')
class DiferenciasConteo extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get conteoId => integer().named('conteo_id')();
  IntColumn get productoId => integer().named('producto_id')();
  TextColumn get codigoProducto => text().named('codigo_producto')();
  TextColumn get nombreProducto => text().named('nombre_producto')();
  RealColumn get stockSistema => real().named('stock_sistema')();
  RealColumn get stockFisico => real().named('stock_fisico')();
  RealColumn get diferencia => real()();
  TextColumn get motivo => text().nullable()();
  TextColumn get estado => text().nullable()();
}
