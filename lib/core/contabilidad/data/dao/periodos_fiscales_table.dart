import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/enums/estado_periodo.dart';

class EstadoPeriodoConverter extends TypeConverter<EstadoPeriodo, String> {
  const EstadoPeriodoConverter();

  @override
  EstadoPeriodo fromSql(String value) {
    final n = value.toLowerCase().trim();
    for (final e in EstadoPeriodo.values) {
      if (e.name == n) return e;
    }
    return EstadoPeriodo.abierto;
  }

  @override
  String toSql(EstadoPeriodo value) => value.name;
}

class PeriodosFiscalesTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get codigo => text()();
  TextColumn get nombre => text()();
  DateTimeColumn get fechaInicio => dateTime()();
  DateTimeColumn get fechaFin => dateTime()();
  TextColumn get estado => text()
      .map(const EstadoPeriodoConverter())
      .withDefault(const Constant('abierto'))();
  TextColumn get paisCodigo => text().withDefault(const Constant('DO'))();
  DateTimeColumn get creadoEn =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get actualizadoEn => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {codigo, paisCodigo},
      ];
}
