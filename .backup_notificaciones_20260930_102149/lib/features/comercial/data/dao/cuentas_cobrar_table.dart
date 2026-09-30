import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/clientes/data/dao/clientes_table.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_table.dart';

class CobrarEstadoConverter extends TypeConverter<CobrarEstado, String> {
  const CobrarEstadoConverter();

  @override
  CobrarEstado fromSql(String value) {
    return CobrarEstado.values.byName(value.toLowerCase());
  }

  @override
  String toSql(CobrarEstado value) {
    return value.name;
  }
}

@DataClassName('CuentaCobrarData')
class CuentasCobrarTable extends Table {
  IntColumn get id => integer().autoIncrement().named('id')();
  IntColumn get clienteId =>
      integer().named('cliente_id').references(ClientesTable, #id)();
  IntColumn get ventaId =>
      integer().named('venta_id').references(VentasTable, #id)();
  RealColumn get montoOriginal => real().named('monto_original')();
  RealColumn get montoAbonado =>
      real().named('monto_abonado').withDefault(const Constant(0.0))();
  RealColumn get saldoPendiente => real().named('saldo_pendiente')();
  DateTimeColumn get fechaVencimiento =>
      dateTime().named('fecha_vencimiento')();
  TextColumn get estado => text()
      .named('estado')
      .withDefault(const Constant('pendiente'))
      .map(const CobrarEstadoConverter())();
}
