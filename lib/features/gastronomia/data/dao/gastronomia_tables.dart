import 'package:drift/drift.dart';

@DataClassName('ExtraGastronomicoData')
class ExtrasGastronomiaTable extends Table {
  @override
  String get tableName => 'extras_gastronomia';
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text()();
  RealColumn get precio => real().withDefault(const Constant(0.0))();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('ProductoExtraData')
class ProductoExtraTable extends Table {
  @override
  String get tableName => 'producto_extra';
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productoId => integer()();
  IntColumn get extraId => integer()();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
}

@DataClassName('SectorDeliveryData')
class SectoresDeliveryTable extends Table {
  @override
  String get tableName => 'sectores_delivery';
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text().unique()();
  RealColumn get tarifaEnvio => real().withDefault(const Constant(0.0))();
  RealColumn get montoMinimoEnvioGratis =>
      real().withDefault(const Constant(0.0))();
  IntColumn get orden => integer().withDefault(const Constant(0))();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('RepartidorData')
class RepartidoresTable extends Table {
  @override
  String get tableName => 'repartidores';
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text()();
  TextColumn get telefono => text().withDefault(const Constant(''))();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('PedidoGastronomiaData')
class PedidosGastronomiaTable extends Table {
  @override
  String get tableName => 'pedidos_gastronomia';
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().withDefault(const Constant(''))();
  TextColumn get tipo => text().withDefault(const Constant('local'))();
  TextColumn get estado => text().withDefault(const Constant('pendiente'))();
  IntColumn get clienteId => integer().nullable()();
  TextColumn get nombreCliente =>
      text().withDefault(const Constant('Consumidor Final'))();
  TextColumn get telefono => text().withDefault(const Constant(''))();
  IntColumn get sectorId => integer().nullable()();
  TextColumn get direccionReferencia =>
      text().withDefault(const Constant(''))();
  RealColumn get costoEnvio => real().withDefault(const Constant(0.0))();
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
  RealColumn get itbis => real().withDefault(const Constant(0.0))();
  RealColumn get descuento => real().withDefault(const Constant(0.0))();
  RealColumn get propina => real().withDefault(const Constant(0.0))();
  RealColumn get total => real().withDefault(const Constant(0.0))();
  TextColumn get formaPago => text().withDefault(const Constant('efectivo'))();
  IntColumn get ventaId => integer().nullable()();
  IntColumn get repartidorId => integer().nullable()();
  TextColumn get estadoEntrega =>
      text().withDefault(const Constant('pendiente'))();
  TextColumn get notas => text().withDefault(const Constant(''))();
  IntColumn get usuarioId => integer().nullable()();
  DateTimeColumn get fecha => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get sincronizado => boolean().withDefault(const Constant(false))();
}

@DataClassName('PedidoGastronomiaLineaData')
class PedidoGastronomiaLineaTable extends Table {
  @override
  String get tableName => 'pedido_gastronomia_linea';
  IntColumn get id => integer().autoIncrement()();
  IntColumn get pedidoId => integer()();
  IntColumn get productoId => integer()();
  TextColumn get nombreSnapshot => text().withDefault(const Constant(''))();
  RealColumn get cantidad => real().withDefault(const Constant(1.0))();
  RealColumn get precioUnitario => real().withDefault(const Constant(0.0))();
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
  TextColumn get notas => text().withDefault(const Constant(''))();
}

@DataClassName('PedidoLineaExtraData')
class PedidoLineaExtraTable extends Table {
  @override
  String get tableName => 'pedido_linea_extra';
  IntColumn get id => integer().autoIncrement()();
  IntColumn get lineaId => integer()();
  IntColumn get extraId => integer().nullable()();
  TextColumn get nombreSnapshot => text().withDefault(const Constant(''))();
  RealColumn get precioSnapshot => real().withDefault(const Constant(0.0))();
}

/// Meta gastronómica separada: NO toca productos_table.
@DataClassName('ProductoGastroMetaData')
class ProductosGastroMetaTable extends Table {
  @override
  String get tableName => 'productos_gastro_meta';
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productoId => integer().unique()();
  TextColumn get fotoPath => text().withDefault(const Constant(''))();
  BoolColumn get esGastronomico =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get destacado => boolean().withDefault(const Constant(false))();
  BoolColumn get disponibleMenu =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get actualizadoEn => dateTime().nullable()();
  TextColumn get fotoRemotaKey => text().nullable()();
  BoolColumn get fotoSincronizado =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get fotoActualizadoEn => dateTime().nullable()();
}

/// Meta de menú por categoría: NO toca categorias.
@DataClassName('CategoriaMenuMetaData')
class CategoriasMenuMetaTable extends Table {
  @override
  String get tableName => 'categorias_menu_meta';
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoriaId => integer().unique()();
  BoolColumn get visibleEnMenu => boolean().withDefault(const Constant(true))();
  IntColumn get ordenMenu => integer().withDefault(const Constant(0))();
}
