import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/enums/tipo_cuenta.dart';

class TipoCuentaConverter extends TypeConverter<TipoCuenta, String> {
  const TipoCuentaConverter();

  @override
  TipoCuenta fromSql(String value) {
    final normalizado = value.toLowerCase().trim();
    for (final e in TipoCuenta.values) {
      if (e.name.toLowerCase() == normalizado) return e;
    }
    return TipoCuenta.values.first;
  }

  @override
  String toSql(TipoCuenta value) => value.name;
}

class PlanCuentasTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get codigo => text()();
  TextColumn get nombre => text()();
  TextColumn get tipo => text().map(const TipoCuentaConverter())();
  IntColumn get padreId => integer().nullable()();
  IntColumn get nivel => integer()();
  BoolColumn get permiteMovimiento =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  TextColumn get descripcion => text().nullable()();
  DateTimeColumn get creadoEn =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get actualizadoEn => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {codigo},
      ];
}
