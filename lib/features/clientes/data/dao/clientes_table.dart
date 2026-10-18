import 'package:drift/drift.dart';

class ClientesTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get codigo => text().unique()();
  TextColumn get nombre => text()();
  TextColumn get rncCedula => text()();
  TextColumn get telefono => text()();
  TextColumn get whatsapp => text().nullable()();
  TextColumn get correo => text()();
  TextColumn get direccion => text()();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  RealColumn get saldoPendiente => real().withDefault(const Constant(0.0))();
  /// Ingreso mensual demostrado (base del límite de cuota).
  RealColumn get ingresoMensual =>
      real().named('ingreso_mensual').withDefault(const Constant(0.0))();
  /// Tope de cuota mensual aprobado por crédito (editable).
  /// Sugerido = ingresoMensual * % capacidad (default 30%).
  RealColumn get limiteCuotaMensual =>
      real().named('limite_cuota_mensual').withDefault(const Constant(0.0))();
}

