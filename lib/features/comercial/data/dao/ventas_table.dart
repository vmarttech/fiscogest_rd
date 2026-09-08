import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/clientes/data/dao/clientes_table.dart';
import 'package:fiscogest_rd/features/seguridad/data/dao/usuarios_table.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

class VentaEstadoConverter extends TypeConverter<VentaEstado, String> {
  const VentaEstadoConverter();
  @override
  VentaEstado fromSql(String valorDb) {
    final buscado = valorDb.trim().toLowerCase();
    return VentaEstado.values.firstWhere(
      (e) => e.name == buscado,
      orElse: () => VentaEstado.borrador,
    );
  }
  @override
  String toSql(VentaEstado valorDart) => valorDart.name;
}

@DataClassName('VentaData')
class VentasTable extends Table {
  IntColumn get id => integer().autoIncrement().named('id')();
  IntColumn get clienteId =>
      integer().named('cliente_id').references(ClientesTable, #id)();
  DateTimeColumn get fecha => dateTime().named('fecha')();
  RealColumn get montoSubtotal => real().named('monto_subtotal')();
  RealColumn get descuentoGlobal =>
      real().named('descuento_global').withDefault(const Constant(0.0))();
  RealColumn get itbis => real().named('itbis')();
  RealColumn get costoEnvio =>
      real().named('costo_envio').withDefault(const Constant(0.0))();
  RealColumn get abonoInicial =>
      real().named('abono_inicial').withDefault(const Constant(0.0))();
  DateTimeColumn get vencimiento =>
      dateTime().named('vencimiento').nullable()();
  RealColumn get montoTotal => real().named('monto_total')();
  TextColumn get formaPago => textEnum<FormaPago>().named('forma_pago')();
  TextColumn get estado => text()
      .named('estado')
      .withDefault(const Constant('borrador'))
      .map(const VentaEstadoConverter())();
  IntColumn get usuarioId =>
      integer().named('usuario_id').references(UsuariosTable, #id)();
  DateTimeColumn get fechaRegistro =>
      dateTime().named('fecha_registro').withDefault(currentDateAndTime)();
}
