import 'package:drift/drift.dart';

class ProductosTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Identificación única comercial
  TextColumn get codigo => text().withLength(min: 1, max: 50).customConstraint('UNIQUE')();
  TextColumn get codigoBarras => text().nullable().customConstraint('UNIQUE')();

  // Información descriptiva
  TextColumn get nombre => text().withLength(min: 1, max: 100)();
  TextColumn get descripcion => text().nullable()();

  // Costos con restricciones seguras utilizando check() correctamente con Drift expressions
  RealColumn get precioCompra => real().check(precioCompra.isBiggerOrEqualValue(0.0))();
  RealColumn get precioVenta => real().check(precioVenta.isBiggerOrEqualValue(0.0))();

  // Inventario y mínimos seguros
  RealColumn get stock => real().check(stock.isBiggerOrEqualValue(0.0))();
  RealColumn get stockMinimo => real().check(stockMinimo.isBiggerOrEqualValue(0.0))();

  // Relaciones normalizadas obligatorias para coincidir con el Dominio
  IntColumn get categoriaId => integer()();
  IntColumn get marcaId => integer()();
  IntColumn get unidadMedidaId => integer()();

  // Estado del registro
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
}