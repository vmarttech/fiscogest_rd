import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/proveedores/data/dao/proveedores_table.dart';

class EstadoCompraConverter extends TypeConverter<EstadoCompra, String> {
  const EstadoCompraConverter();
  @override
  EstadoCompra fromSql(String value) {
    final normalizado = value.toLowerCase().trim();
    for (final e in EstadoCompra.values) {
      if (e.name.toLowerCase() == normalizado) return e;
    }
    return EstadoCompra.borrador;
  }
  @override
  String toSql(EstadoCompra value) => value.name;
}

class ComprasTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get numeroComprobante => text()();
  TextColumn get tipoComprobante => text()();
  DateTimeColumn get fechaEmision => dateTime()();
  DateTimeColumn get fechaConfirmacion => dateTime().nullable()();
  DateTimeColumn get fechaVencimiento => dateTime().nullable()();
  DateTimeColumn get fechaRecepcion => dateTime().nullable()();
  TextColumn get ncf => text().withDefault(const Constant(''))();
  TextColumn get formaPago => text().withDefault(const Constant('contado'))();
  IntColumn get diasCredito => integer().withDefault(const Constant(0))();
  TextColumn get condicionPago => text()();
  RealColumn get subtotalSinImpuestos => real()();
  RealColumn get montoDescuentoGlobal => real()();
  RealColumn get tasaImpuesto => real()();
  RealColumn get montoImpuesto => real()();
  RealColumn get totalCompra => real()();
  IntColumn get proveedorId => integer().references(ProveedoresTable, #id)();
  TextColumn get nombreProveedor => text()();
  TextColumn get estado => text()
      .map(const EstadoCompraConverter())
      .withDefault(const Constant('borrador'))();
  TextColumn get observaciones => text().nullable()();
  DateTimeColumn get creadoEn => dateTime()();
  DateTimeColumn get actualizadoEn => dateTime().nullable()();
}
