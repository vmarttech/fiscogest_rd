import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/proveedores/data/dao/proveedores_table.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

@DataClassName('CuentaPagarData')
class CuentasPagarTable extends Table {
  IntColumn get id => integer().autoIncrement().named('id')();
  IntColumn get proveedorId => integer().named('proveedor_id').references(ProveedoresTable, #id)();
  TextColumn get concepto => text().named('concepto')();
  RealColumn get monto => real().named('monto')();
  DateTimeColumn get fechaEmision => dateTime().named('fecha_emision')();
  DateTimeColumn get fechaVencimiento => dateTime().named('fecha_vencimiento')();
  TextColumn get estado => textEnum<PagarEstado>().named('estado').withDefault(const Constant('Pendiente'))();
  TextColumn get tipoGasto => textEnum<TipoGasto>().named('tipo_gasto')();
}
