import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/clientes/data/dao/clientes_table.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_table.dart';

@DataClassName('ApartadoData')
class ApartadosTable extends Table {
  IntColumn get id => integer().autoIncrement().named('id')();
  IntColumn get clienteId =>
      integer().named('cliente_id').references(ClientesTable, #id)();
  DateTimeColumn get fechaReserva => dateTime().named('fecha_reserva')();
  DateTimeColumn get fechaLimite => dateTime().named('fecha_limite')();
  RealColumn get montoTotal => real().named('monto_total')();
  RealColumn get montoAbonado =>
      real().named('monto_abonado').withDefault(const Constant(0.0))();
  RealColumn get saldoPendiente => real().named('saldo_pendiente')();
  TextColumn get estado => textEnum<ApartadoEstado>()
      .named('estado')
      .withDefault(const Constant('Reservado'))();
  IntColumn get ventaConvertidaId => integer()
      .named('venta_convertida_id')
      .nullable()
      .references(VentasTable, #id)();
}
