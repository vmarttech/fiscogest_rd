import 'package:drift/drift.dart';

@DataClassName('KardexData')
class KardexTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  // ✅ UNIFICADO: productoId -> columna producto_id
  IntColumn get productoId => integer().named('producto_id')();
  TextColumn get tipoMovimiento => text().named('tipo_movimiento')();
  RealColumn get cantidad => real()();
  RealColumn get saldoAnterior => real().named('saldo_anterior')();
  RealColumn get saldoNuevo => real().named('saldo_nuevo')();
  RealColumn get costoUnitario => real().named('costo_unitario')();
  RealColumn get totalMovimiento => real().named('total_movimiento')();
  IntColumn get referenciaId => integer().named('referencia_id').nullable()();
  TextColumn get documentoReferencia => text().named('documento_referencia').nullable()();
  TextColumn get motivo => text().nullable()();
  IntColumn get usuarioId => integer().named('usuario_id').nullable()();
  IntColumn get fechaMovimiento => integer().named('fecha_movimiento')(); // timestamp
  TextColumn get observacion => text().nullable()();
}
