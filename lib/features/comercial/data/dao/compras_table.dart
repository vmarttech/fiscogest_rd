import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

class ComprasTable extends Table {
  TextColumn get id => text()();
  TextColumn get proveedorId => text()();
  TextColumn get nombreProveedor => text()();
  DateTimeColumn get fechaEmision => dateTime()();
  DateTimeColumn get fechaConfirmacion => dateTime().nullable()();
  TextColumn get numeroComprobante => text()();
  RealColumn get subtotalSinImpuestos => real()();
  RealColumn get montoDescuentoGlobal => real()();
  RealColumn get tasaImpuesto => real()();
  RealColumn get montoImpuesto => real()();
  RealColumn get totalCompra => real()();
  TextColumn get observaciones => text()();
  IntColumn get estado => intEnum<EstadoCompra>()();
  DateTimeColumn get creadoEn => dateTime()();
  DateTimeColumn get actualizadoEn => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
