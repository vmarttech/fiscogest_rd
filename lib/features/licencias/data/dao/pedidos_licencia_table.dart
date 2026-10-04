import 'package:drift/drift.dart';

/// Pedido de licencia (pago por transferencia / Toke).
class PedidosLicenciaTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// FG-48291 (solo dígitos tras el prefijo)
  TextColumn get referencia => text().unique()();

  TextColumn get plan => text()();
  TextColumn get vigenciaTipo => text()();
  RealColumn get monto => real()();
  TextColumn get moneda => text().withDefault(const Constant('DOP'))();

  /// pendiente_pago | pago_reportado | pagado | licencia_emitida | expirado
  TextColumn get estado => text()();

  TextColumn get negocioNombre => text().nullable()();
  TextColumn get rnc => text().nullable()();
  TextColumn get fechaCreacion => text()();
  TextColumn get fechaExpiracionPedido => text()();

  /// toke | banreservas | bhd | apap | null
  TextColumn get medioPagoPreferido => text().nullable()();
  TextColumn get notas => text().nullable()();
}
