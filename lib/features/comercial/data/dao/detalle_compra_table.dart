import 'package:drift/drift.dart';

class DetalleCompraTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get compraId => integer()();
  IntColumn get productoId => integer()();
  TextColumn get nombreProducto => text()();
  RealColumn get cantidad => real().nullable()();
  RealColumn get costoUnitario => real().nullable()();
  RealColumn get fleteUnitario => real().nullable().withDefault(const Constant(0.0))();
  RealColumn get seguroUnitario => real().nullable().withDefault(const Constant(0.0))();
  RealColumn get arancelesUnitario => real().nullable().withDefault(const Constant(0.0))();
  RealColumn get gastosUnitario => real().nullable().withDefault(const Constant(0.0))();
  RealColumn get descuentoPorcentaje => real().nullable().withDefault(const Constant(0.0))();
  RealColumn get montoDescuentoLinea => real().nullable().withDefault(const Constant(0.0))();
  RealColumn get subtotalLinea => real().nullable()();
  RealColumn get baseImponibleLinea => real().nullable()();
  RealColumn get itbisLinea => real().nullable()();
  RealColumn get totalLinea => real().nullable()();
  RealColumn get costoAdquisicion => real().nullable()();
}
