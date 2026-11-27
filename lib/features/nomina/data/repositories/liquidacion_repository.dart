import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/nomina/domain/entities/liquidacion_historial.dart';
import 'package:fiscogest_rd/features/nomina/domain/services/calculadora_prestaciones_rd.dart';

class LiquidacionRepository {
  LiquidacionRepository(this._db);
  final AppDatabase _db;

  DateTime _dt(dynamic v) {
    if (v is DateTime) return v;
    return DateTime.tryParse(v?.toString() ?? '') ?? DateTime.now();
  }

  Future<List<LiquidacionHistorial>> listar({int? empleadoId}) async {
    final vars = <Variable>[];
    var where = '';
    if (empleadoId != null) {
      where = 'WHERE empleado_id = ?';
      vars.add(Variable.withInt(empleadoId));
    }
    final rows = await _db.customSelect(
      '''
      SELECT id, empleado_id, nombre_empleado, fecha_ingreso, fecha_salida,
             salario_mensual, anios_servicio, monto_preaviso, monto_cesantia,
             monto_vacaciones, monto_regalia, total, notas, creado_en
      FROM liquidaciones_table
      $where
      ORDER BY creado_en DESC, id DESC
      ''',
      variables: vars,
      readsFrom: {_db.liquidacionesTable},
    ).get();

    return rows.map((r) {
      final d = r.data;
      return LiquidacionHistorial(
        id: (d['id'] as num?)?.toInt(),
        empleadoId: (d['empleado_id'] as num?)?.toInt() ?? 0,
        nombreEmpleado: d['nombre_empleado']?.toString() ?? '',
        fechaIngreso: _dt(d['fecha_ingreso']),
        fechaSalida: _dt(d['fecha_salida']),
        salarioMensual: (d['salario_mensual'] as num?)?.toDouble() ?? 0,
        aniosServicio: (d['anios_servicio'] as num?)?.toDouble() ?? 0,
        montoPreaviso: (d['monto_preaviso'] as num?)?.toDouble() ?? 0,
        montoCesantia: (d['monto_cesantia'] as num?)?.toDouble() ?? 0,
        montoVacaciones: (d['monto_vacaciones'] as num?)?.toDouble() ?? 0,
        montoRegalia: (d['monto_regalia'] as num?)?.toDouble() ?? 0,
        total: (d['total'] as num?)?.toDouble() ?? 0,
        notas: d['notas']?.toString(),
        creadoEn: _dt(d['creado_en']),
      );
    }).toList();
  }

  Future<int> guardar({
    required int empleadoId,
    required String nombreEmpleado,
    required LiquidacionPrestaciones liq,
    String? notas,
  }) async {
    final row = await _db.into(_db.liquidacionesTable).insertReturning(
          LiquidacionesTableCompanion.insert(
            empleadoId: empleadoId,
            nombreEmpleado: nombreEmpleado,
            fechaIngreso: liq.fechaIngreso,
            fechaSalida: liq.fechaSalida,
            salarioMensual: liq.salarioMensual,
            aniosServicio: liq.aniosServicio,
            montoPreaviso: Value(liq.montoPreaviso),
            montoCesantia: Value(liq.montoCesantia),
            montoVacaciones: Value(liq.montoVacaciones),
            montoRegalia: Value(liq.montoRegalia),
            total: Value(liq.total),
            notas: Value(notas),
            creadoEn: DateTime.now(),
          ),
        );
    return row.id;
  }

  Future<void> eliminar(int id) async {
    await (_db.delete(_db.liquidacionesTable)..where((t) => t.id.equals(id)))
        .go();
  }
}
