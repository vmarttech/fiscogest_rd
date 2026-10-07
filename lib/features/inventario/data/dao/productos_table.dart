import 'package:drift/drift.dart';

@DataClassName('ProductoData')
class ProductosTable extends Table {
  @override
  String get tableName => 'productos_table';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get codigo => text()();
  TextColumn get codigoBarras => text().nullable().named('codigo_barras')();
  TextColumn get nombre => text()();
  TextColumn get descripcion => text().nullable()();
  RealColumn get precioCompra => real()
      .named('precio_compra')
      .nullable()
      .withDefault(const Constant(0.0))();
  RealColumn get gastosAsociados => real()
      .named('gastos_asociados')
      .nullable()
      .withDefault(const Constant(0.0))();
  RealColumn get precioVenta => real()
      .named('precio_venta')
      .nullable()
      .withDefault(const Constant(0.0))();
  RealColumn get margenGanancia => real()
      .named('margen_ganancia')
      .nullable()
      .withDefault(const Constant(0.0))();
  RealColumn get precioMinimo => real()
      .named('precio_minimo')
      .nullable()
      .withDefault(const Constant(0.0))();
  RealColumn get precioMayorista => real()
      .named('precio_mayorista')
      .nullable()
      .withDefault(const Constant(0.0))();
  RealColumn get precioEspecial => real()
      .named('precio_especial')
      .nullable()
      .withDefault(const Constant(0.0))();
  RealColumn get stock => real().nullable().withDefault(const Constant(0.0))();
  RealColumn get stockReservado => real()
      .named('stock_reservado')
      .nullable()
      .withDefault(const Constant(0.0))();
  RealColumn get stockMinimo => real()
      .named('stock_minimo')
      .nullable()
      .withDefault(const Constant(0.0))();
  RealColumn get stockMaximo => real()
      .named('stock_maximo')
      .nullable()
      .withDefault(const Constant(0.0))();
  IntColumn get categoriaId => integer().named('categoria_id')();
  IntColumn get marcaId => integer().named('marca_id')();
  IntColumn get unidadMedidaId => integer().named('unidad_medida_id')();
  IntColumn get impuestoId => integer().nullable().named('impuesto_id')();
  IntColumn get activo => integer().withDefault(const Constant(1))();
}
