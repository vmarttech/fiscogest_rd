import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

class ComprasTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get proveedorId => integer()();
  TextColumn get nombreProveedor => text()();
  DateTimeColumn get fechaEmision => dateTime()();
  DateTimeColumn get fechaVencimiento => dateTime()();
  DateTimeColumn get fechaConfirmacion => dateTime().nullable()();
  DateTimeColumn get fechaRecepcion => dateTime().nullable()();
  TextColumn get numeroComprobante => text()();
  TextColumn get ncf => text()();
  TextColumn get tipoComprobante => text()();
  TextColumn get formaPago => text()();
  TextColumn get condicionPago => text()();
  IntColumn get diasCredito => integer().withDefault(const Constant(0))();
  RealColumn get subtotalSinImpuestos => real()();
  RealColumn get montoDescuentoGlobal => real()();
  RealColumn get tasaImpuesto => real()();
  RealColumn get montoImpuesto => real()();
  RealColumn get totalCompra => real()();
  IntColumn get estado => intEnum<EstadoCompra>()();
  TextColumn get observaciones => text().withDefault(const Constant(''))();
  DateTimeColumn get creadoEn => dateTime()();
  DateTimeColumn get actualizadoEn => dateTime().nullable()();
}
