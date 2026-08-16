import 'package:drift/drift.dart';

@DataClassName('ProductoData')
class ProductosTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get codigo => text()();
  TextColumn get codigoBarras => text().named('codigo_barras').nullable()();
  TextColumn get nombre => text()();
  TextColumn get descripcion => text().nullable()();
  RealColumn get precioCompra => real().named('precio_compra')();
  RealColumn get precioVenta => real().named('precio_venta')();
  RealColumn get stock => real().nullable()();
  RealColumn get stockMinimo => real().named('stock_minimo').nullable()();
  // ✅ AGREGADO FALTANTE
  RealColumn get stockMaximo => real().named('stock_maximo').nullable()();
  IntColumn get categoriaId => integer().named('categoria_id')();
  IntColumn get marcaId => integer().named('marca_id')();
  IntColumn get unidadMedidaId => integer().named('unidad_medida_id')();
  // ✅ CORREGIDO: int, convertir bool en capa superior
  IntColumn get activo => integer().withDefault(const Constant(1))();
}
