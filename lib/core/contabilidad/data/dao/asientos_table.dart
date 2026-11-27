import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/enums/estado_asiento.dart';

class EstadoAsientoConverter extends TypeConverter<EstadoAsiento, String> {
  const EstadoAsientoConverter();

  @override
  EstadoAsiento fromSql(String value) {
    final normalizado = value.toLowerCase().trim();
    for (final e in EstadoAsiento.values) {
      if (e.name.toLowerCase() == normalizado) return e;
    }
    return EstadoAsiento.values.first;
  }

  @override
  String toSql(EstadoAsiento value) => value.name;
}

class AsientosTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get numeroAsiento => text()();
  DateTimeColumn get fecha => dateTime()();
  TextColumn get concepto => text()();
  TextColumn get estado => text()
      .map(const EstadoAsientoConverter())
      .withDefault(const Constant('borrador'))();
  TextColumn get documentoOrigen => text().nullable()();
  TextColumn get tipoOrigen => text().nullable()();
  IntColumn get referenciaId => integer().nullable()();
  TextColumn get motivoAnulacion => text().nullable()();
  DateTimeColumn get creadoEn =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get actualizadoEn => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {numeroAsiento},
      ];
}
