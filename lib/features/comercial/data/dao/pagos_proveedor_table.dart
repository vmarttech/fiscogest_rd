import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_pagar_table.dart';
import 'package:fiscogest_rd/features/proveedores/data/dao/proveedores_table.dart';

/// Historial de abonos/pagos aplicados a cuentas por pagar
@DataClassName('PagoProveedorData')
class PagosProveedorTable extends Table {
  IntColumn get id => integer().autoIncrement().named('id')();

  IntColumn get cuentaPagarId => integer()
      .named('cuenta_pagar_id')
      .references(CuentasPagarTable, #id, onDelete: KeyAction.cascade)();

  IntColumn get proveedorId =>
      integer().named('proveedor_id').references(ProveedoresTable, #id)();

  RealColumn get monto => real().named('monto')();

  DateTimeColumn get fechaPago => dateTime().named('fecha_pago')();

  TextColumn get formaPago =>
      text().named('forma_pago')(); // efectivo, transferencia, cheque, etc.

  TextColumn get referencia => text().named('referencia').nullable()();

  TextColumn get nota => text().named('nota').nullable()();
}
