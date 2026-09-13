import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/proveedores/data/dao/proveedores_table.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

class PagarEstadoConverter extends TypeConverter<PagarEstado, String> {
  const PagarEstadoConverter();

  @override
  PagarEstado fromSql(String value) {
    return PagarEstado.values.byName(value.toLowerCase());
  }

  @override
  String toSql(PagarEstado value) {
    return value.name;
  }
}

@DataClassName('CuentaPagarData')
class CuentasPagarTable extends Table {
  IntColumn get id => integer().autoIncrement().named('id')();
  IntColumn get proveedorId =>
      integer().named('proveedor_id').references(ProveedoresTable, #id)();
  TextColumn get concepto => text().named('concepto')();
  RealColumn get monto => real().named('monto')();
  DateTimeColumn get fechaEmision => dateTime().named('fecha_emision')();
  DateTimeColumn get fechaVencimiento =>
      dateTime().named('fecha_vencimiento')();
  TextColumn get estado => text()
      .named('estado')
      .withDefault(const Constant('pendiente'))
      .map(const PagarEstadoConverter())();
  TextColumn get tipoGasto => textEnum<TipoGasto>().named('tipo_gasto')();
}
