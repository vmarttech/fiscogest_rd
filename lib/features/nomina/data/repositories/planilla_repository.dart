import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/nomina/domain/entities/empleado.dart';
import 'package:fiscogest_rd/features/nomina/domain/entities/planilla.dart';
import 'package:fiscogest_rd/features/nomina/domain/services/calculadora_nomina_rd.dart';

class PlanillaRepository {
  PlanillaRepository(this._db);
  final AppDatabase _db;

  DateTime _parseDt(dynamic v) {
    if (v is DateTime) return v;
    return DateTime.tryParse(v?.toString() ?? '') ?? DateTime.now();
  }

  Planilla _mapPlanilla(Map<String, dynamic> d, {List<PlanillaLinea> lineas = const []}) {
    return Planilla(
      id: (d['id'] as num?)?.toInt(),
      periodo: d['periodo']?.toString() ?? '',
      tipoPeriodo: d['tipo_periodo']?.toString() ?? 'mensual',
      fechaInicio: _parseDt(d['fecha_inicio']),
      fechaFin: _parseDt(d['fecha_fin']),
      estado: d['estado']?.toString() ?? 'borrador',
      totalBruto: (d['total_bruto'] as num?)?.toDouble() ?? 0,
      totalNeto: (d['total_neto'] as num?)?.toDouble() ?? 0,
      totalTssTrab: (d['total_tss_trab'] as num?)?.toDouble() ?? 0,
      totalIsr: (d['total_isr'] as num?)?.toDouble() ?? 0,
      totalCostoEmpleador: (d['total_costo_empleador'] as num?)?.toDouble() ?? 0,
      fechaPago: d['fecha_pago'] == null ? null : _parseDt(d['fecha_pago']),
      notas: d['notas']?.toString(),
      creadoEn: d['creado_en'] == null ? null : _parseDt(d['creado_en']),
      actualizadoEn: d['actualizado_en'] == null ? null : _parseDt(d['actualizado_en']),
      lineas: lineas,
    );
  }

  PlanillaLinea _mapLinea(Map<String, dynamic> d) {
    return PlanillaLinea(
      id: (d['id'] as num?)?.toInt(),
      planillaId: (d['planilla_id'] as num?)?.toInt() ?? 0,
      empleadoId: (d['empleado_id'] as num?)?.toInt() ?? 0,
      nombreEmpleado: d['nombre_empleado']?.toString() ?? '',
      cargo: d['cargo']?.toString(),
      salarioBase: (d['salario_base'] as num?)?.toDouble() ?? 0,
      montoBruto: (d['monto_bruto'] as num?)?.toDouble() ?? 0,
      tssAfp: (d['tss_afp'] as num?)?.toDouble() ?? 0,
      tssSfs: (d['tss_sfs'] as num?)?.toDouble() ?? 0,
      isr: (d['isr'] as num?)?.toDouble() ?? 0,
      montoNeto: (d['monto_neto'] as num?)?.toDouble() ?? 0,
      afpPatronal: (d['afp_patronal'] as num?)?.toDouble() ?? 0,
      sfsPatronal: (d['sfs_patronal'] as num?)?.toDouble() ?? 0,
      srlPatronal: (d['srl_patronal'] as num?)?.toDouble() ?? 0,
      fondoSolidaridad: (d['fondo_solidaridad'] as num?)?.toDouble() ?? 0,
      infotep: (d['infotep'] as num?)?.toDouble() ?? 0,
      notas: d['notas']?.toString(),
    );
  }

  static const _selPlanilla = '''
    SELECT id, periodo, tipo_periodo, fecha_inicio, fecha_fin, estado,
           total_bruto, total_neto, total_tss_trab, total_isr,
           total_costo_empleador, fecha_pago, notas, creado_en, actualizado_en
    FROM planillas_table
  ''';

  static const _selLinea = '''
    SELECT id, planilla_id, empleado_id, nombre_empleado, cargo,
           salario_base, monto_bruto, tss_afp, tss_sfs, isr, monto_neto,
           afp_patronal, sfs_patronal, srl_patronal, fondo_solidaridad,
           infotep, notas
    FROM planilla_lineas_table
  ''';

  Future<List<Planilla>> listar() async {
    final rows = await _db.customSelect(
      '$_selPlanilla ORDER BY periodo DESC, id DESC',
      readsFrom: {_db.planillasTable},
    ).get();
    return rows.map((r) => _mapPlanilla(r.data)).toList();
  }

  Future<Planilla?> obtener(int id) async {
    final rows = await _db.customSelect(
      '$_selPlanilla WHERE id = ?',
      variables: [Variable.withInt(id)],
      readsFrom: {_db.planillasTable},
    ).get();
    if (rows.isEmpty) return null;
    final lineas = await listarLineas(id);
    return _mapPlanilla(rows.first.data, lineas: lineas);
  }

  Future<List<PlanillaLinea>> listarLineas(int planillaId) async {
    final rows = await _db.customSelect(
      '$_selLinea WHERE planilla_id = ? ORDER BY id ASC',
      variables: [Variable.withInt(planillaId)],
      readsFrom: {_db.planillaLineasTable},
    ).get();
    return rows.map((r) => _mapLinea(r.data)).toList();
  }

  Future<bool> existePeriodo(String periodo) async {
    final rows = await _db.customSelect(
      'SELECT id FROM planillas_table WHERE periodo = ? LIMIT 1',
      variables: [Variable.withString(periodo)],
      readsFrom: {_db.planillasTable},
    ).get();
    return rows.isNotEmpty;
  }

  Future<int> crearDesdeEmpleados({
    required String periodo,
    required String tipoPeriodo,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required List<Empleado> empleados,
    String? notas,
  }) async {
    if (await existePeriodo(periodo)) {
      throw StateError('Ya existe una planilla para el periodo $periodo');
    }
    final activos = empleados.where((e) => e.activo && e.id != null).toList();
    if (activos.isEmpty) {
      throw StateError('No hay empleados activos');
    }

    final now = DateTime.now();
    return _db.transaction(() async {
      double tBruto = 0, tNeto = 0, tTss = 0, tIsr = 0, tCosto = 0;
      final pairs = <(Empleado, ({
        double afp,
        double sfs,
        double isr,
        double neto,
        double rentaNeta,
        double afpPat,
        double sfsPat,
        double srlPat,
        double fondoSol,
        double infotep,
        double costoEmpleador,
      }))>[];
      for (final e in activos) {
        final c = CalculadoraNominaRd.desdeBruto(e.salarioBase);
        pairs.add((e, c));
        tBruto += e.salarioBase;
        tNeto += c.neto;
        tTss += c.afp + c.sfs;
        tIsr += c.isr;
        tCosto += c.costoEmpleador;
      }

      final row = await _db.into(_db.planillasTable).insertReturning(
            PlanillasTableCompanion.insert(
              periodo: periodo,
              tipoPeriodo: Value(tipoPeriodo),
              fechaInicio: fechaInicio,
              fechaFin: fechaFin,
              estado: const Value('borrador'),
              totalBruto: Value(tBruto),
              totalNeto: Value(tNeto),
              totalTssTrab: Value(tTss),
              totalIsr: Value(tIsr),
              totalCostoEmpleador: Value(tCosto),
              notas: Value(notas),
              creadoEn: now,
              actualizadoEn: Value(now),
            ),
          );

      for (final pair in pairs) {
        final e = pair.$1;
        final c = pair.$2;
        await _db.into(_db.planillaLineasTable).insert(
              PlanillaLineasTableCompanion.insert(
                planillaId: row.id,
                empleadoId: e.id!,
                nombreEmpleado: e.nombreCompleto,
                cargo: Value(e.cargo),
                salarioBase: Value(e.salarioBase),
                montoBruto: Value(e.salarioBase),
                tssAfp: Value(c.afp),
                tssSfs: Value(c.sfs),
                isr: Value(c.isr),
                montoNeto: Value(c.neto),
                afpPatronal: Value(c.afpPat),
                sfsPatronal: Value(c.sfsPat),
                srlPatronal: Value(c.srlPat),
                fondoSolidaridad: Value(c.fondoSol),
                infotep: Value(c.infotep),
              ),
            );
      }
      return row.id;
    });
  }

  Future<void> actualizarLineaMonto(int lineaId, double montoBruto) async {
    final c = CalculadoraNominaRd.desdeBruto(montoBruto);
    await (_db.update(_db.planillaLineasTable)..where((t) => t.id.equals(lineaId)))
        .write(
      PlanillaLineasTableCompanion(
        montoBruto: Value(montoBruto),
        tssAfp: Value(c.afp),
        tssSfs: Value(c.sfs),
        isr: Value(c.isr),
        montoNeto: Value(c.neto),
        afpPatronal: Value(c.afpPat),
        sfsPatronal: Value(c.sfsPat),
        srlPatronal: Value(c.srlPat),
        fondoSolidaridad: Value(c.fondoSol),
        infotep: Value(c.infotep),
      ),
    );
  }

  Future<void> recalcularTotal(int planillaId) async {
    final lineas = await listarLineas(planillaId);
    double tBruto = 0, tNeto = 0, tTss = 0, tIsr = 0, tCosto = 0;
    for (final l in lineas) {
      tBruto += l.montoBruto;
      tNeto += l.montoNeto;
      tTss += l.tssAfp + l.tssSfs;
      tIsr += l.isr;
      tCosto += l.costoEmpleador;
    }
    await (_db.update(_db.planillasTable)..where((t) => t.id.equals(planillaId)))
        .write(
      PlanillasTableCompanion(
        totalBruto: Value(tBruto),
        totalNeto: Value(tNeto),
        totalTssTrab: Value(tTss),
        totalIsr: Value(tIsr),
        totalCostoEmpleador: Value(tCosto),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
  }

  Future<void> cerrar(int planillaId) async {
    await (_db.update(_db.planillasTable)..where((t) => t.id.equals(planillaId)))
        .write(
      PlanillasTableCompanion(
        estado: const Value('cerrada'),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
  }

  Future<void> marcarPagada(int planillaId, {DateTime? fechaPago}) async {
    await (_db.update(_db.planillasTable)..where((t) => t.id.equals(planillaId)))
        .write(
      PlanillasTableCompanion(
        estado: const Value('pagada'),
        fechaPago: Value(fechaPago ?? DateTime.now()),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
  }

  Future<void> eliminar(int planillaId) async {
    await (_db.delete(_db.planillaLineasTable)
          ..where((t) => t.planillaId.equals(planillaId)))
        .go();
    await (_db.delete(_db.planillasTable)..where((t) => t.id.equals(planillaId)))
        .go();
  }
}
