import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/contabilidad/data/dao/asientos_table.dart';
import 'package:fiscogest_rd/core/contabilidad/data/dao/plan_cuentas_table.dart';

class LineasAsientoTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get asientoId => integer().references(AsientosTable, #id)();
  IntColumn get cuentaId => integer().references(PlanCuentasTable, #id)();

  /// Montos en centavos (enteros). Nunca usar double/real.
  IntColumn get debeCents => integer().withDefault(const Constant(0))();
  IntColumn get haberCents => integer().withDefault(const Constant(0))();

  TextColumn get conceptoLinea => text().nullable()();

  @override
  List<String> get customConstraints => [
        // Una línea solo puede tener debe o haber (nunca ambos > 0)
        'CHECK ( (debe_cents = 0 AND haber_cents >= 0) OR (haber_cents = 0 AND debe_cents >= 0) )',
        'CHECK (debe_cents >= 0 AND haber_cents >= 0)',
      ];
}
