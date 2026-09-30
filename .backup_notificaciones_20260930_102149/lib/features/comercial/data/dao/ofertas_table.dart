import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/inventario/data/dao/productos_table.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

@DataClassName('OfertaData')
class OfertasTable extends Table {
  IntColumn get id => integer().autoIncrement().named('id')();
  TextColumn get nombre => text().named('nombre')();
  IntColumn get productoId =>
      integer().named('producto_id').references(ProductosTable, #id)();
  IntColumn get cantidadMinima => integer().named('cantidad_minima')();
  RealColumn get precioOferta => real().named('precio_oferta')();
  DateTimeColumn get vigenciaDesde => dateTime().named('vigencia_desde')();
  DateTimeColumn get vigenciaHasta => dateTime().named('vigencia_hasta')();
  TextColumn get estado => textEnum<RegistroEstado>()
      .named('estado')
      .withDefault(const Constant('Vigente'))();
}
