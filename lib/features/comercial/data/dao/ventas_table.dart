import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/clientes/data/dao/clientes_table.dart';
import 'package:fiscogest_rd/features/seguridad/data/dao/usuarios_table.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

@DataClassName('VentaData')
class VentasTable extends Table {
  IntColumn get id => integer().autoIncrement().named('id')();
  IntColumn get clienteId => integer().named('cliente_id').references(ClientesTable, #id)();
  DateTimeColumn get fecha => dateTime().named('fecha')();
  RealColumn get montoSubtotal => real().named('monto_subtotal')();
  RealColumn get descuentoGlobal => real().named('descuento_global').withDefault(const Constant(0.0))();
  RealColumn get itbis => real().named('itbis')();
  RealColumn get montoTotal => real().named('monto_total')();
  TextColumn get formaPago => textEnum<FormaPago>().named('forma_pago')();
  TextColumn get estado => textEnum<VentaEstado>().named('estado').withDefault(const Constant('Borrador'))();
  IntColumn get usuarioId => integer().named('usuario_id').references(UsuariosTable, #id)();
  DateTimeColumn get fechaRegistro => dateTime().named('fecha_registro').withDefault(currentDateAndTime)();
}
