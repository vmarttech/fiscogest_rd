import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

@DataClassName('DescuentoData')
class DescuentosTable extends Table {
  IntColumn get id => integer().autoIncrement().named('id')();
  TextColumn get nombre => text().named('nombre')();
  TextColumn get tipo => textEnum<DescuentoTipo>().named('tipo')();
  RealColumn get valor => real().named('valor')();
  TextColumn get aplicaA => textEnum<AplicaA>().named('aplica_a')();
  IntColumn get referenciaId => integer().named('referencia_id').nullable()();
  DateTimeColumn get vigenciaDesde => dateTime().named('vigencia_desde')();
  DateTimeColumn get vigenciaHasta => dateTime().named('vigencia_hasta')();
  TextColumn get estado => textEnum<RegistroEstado>()
      .named('estado')
      .withDefault(const Constant('Vigente'))();
}
