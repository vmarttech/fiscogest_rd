import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cobros_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuotas_cuenta_table.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

part 'cuentas_cobrar_dao.g.dart';

@DriftAccessor(tables: [CuentasCobrarTable, CobrosTable, CuotasCuentaTable])
class CuentasCobrarDao extends DatabaseAccessor<AppDatabase>
    with _$CuentasCobrarDaoMixin {
  CuentasCobrarDao(super.db);
  final DateTime _hoy = DateTime.now();

  Future<int> registrarCuenta(CuentasCobrarTableCompanion cuenta) async {
    return await into(cuentasCobrarTable).insert(cuenta);
  }

  Future<int> crearCuentaPorVenta({
    required int clienteId,
    required int ventaId,
    required double montoOriginal,
    double montoAbonado = 0.0,
    DateTime? fechaVencimiento,
    double tasaInteres = 0.0,
    int numeroCuotas = 1,
    double montoInteresTotal = 0.0,
  }) async {
    final vencimiento = fechaVencimiento ?? _hoy.add(const Duration(days: 30));
    final saldoPendiente = montoOriginal + montoInteresTotal - montoAbonado;
    return await into(cuentasCobrarTable).insert(
      CuentasCobrarTableCompanion.insert(
        clienteId: clienteId,
        ventaId: ventaId,
        montoOriginal: montoOriginal,
        montoAbonado: Value(montoAbonado),
        saldoPendiente: saldoPendiente,
        fechaVencimiento: vencimiento,
        tasaInteres: Value(tasaInteres),
        numeroCuotas: Value(numeroCuotas),
        montoInteresTotal: Value(montoInteresTotal),
        estado: const Value(CobrarEstado.pendiente),
      ),
    );
  }

  Future<CuentaCobrarData?> obtenerCuentaPorId(int cuentaId) async {
    return await (select(
      cuentasCobrarTable,
    )..where((t) => t.id.equals(cuentaId))).getSingleOrNull();
  }

  Future<double> obtenerSaldoPorCliente(int clienteId) async {
    final cuentas = await (select(
      cuentasCobrarTable,
    )..where((t) => t.clienteId.equals(clienteId))).get();
    return cuentas.fold<double>(0.0, (sum, c) => sum + c.saldoPendiente);
  }

  Future<List<CuentaCobrarData>> listarCuentas({
    CobrarEstado? estado,
    int? clienteId,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    DateTime? venceDesde,
    DateTime? venceHasta,
    double? montoMinimo,
    double? montoMaximo,
  }) async {
    final query = select(cuentasCobrarTable);
    if (estado != null) {
      query.where((t) => t.estado.equalsValue(estado));
    }
    if (clienteId != null) {
      query.where((t) => t.clienteId.equals(clienteId));
    }
    if (venceDesde != null) {
      query.where((t) => t.fechaVencimiento.isBiggerOrEqualValue(venceDesde));
    }
    if (venceHasta != null) {
      query.where((t) => t.fechaVencimiento.isSmallerOrEqualValue(venceHasta));
    }
    if (montoMinimo != null) {
      query.where((t) => t.montoOriginal.isBiggerOrEqualValue(montoMinimo));
    }
    if (montoMaximo != null) {
      query.where((t) => t.montoOriginal.isSmallerOrEqualValue(montoMaximo));
    }
    query.orderBy([
      (t) =>
          OrderingTerm(expression: t.fechaVencimiento, mode: OrderingMode.asc),
    ]);
    return await query.get();
  }

  Future<List<CuentaCobrarData>> listarCuentasPorCobrar({
    CobrarEstado? estado,
    int? clienteId,
    DateTime? venceDesde,
    DateTime? venceHasta,
    double? montoMinimo,
    double? montoMaximo,
  }) => listarCuentas(
    estado: estado,
    clienteId: clienteId,
    venceDesde: venceDesde,
    venceHasta: venceHasta,
    montoMinimo: montoMinimo,
    montoMaximo: montoMaximo,
  );

  Future<void> actualizarEstado(int cuentaId, CobrarEstado estado) async {
    await (update(cuentasCobrarTable)..where((t) => t.id.equals(cuentaId)))
        .write(CuentasCobrarTableCompanion(estado: Value(estado)));
  }

  /// Registra el pago, distribuye el monto entre cuotas y actualiza el saldo
  /// dentro de una sola transacción.
  Future<int> registrarPago({
    required int cuentaId,
    required double montoPago,
    required double moraMensual,
    required CobrosTableCompanion cobro,
  }) async {
    return transaction(() async {
      final cuenta = await obtenerCuentaPorId(cuentaId);
      if (cuenta == null) throw StateError('La cuenta por cobrar no existe');
      if (montoPago <= 0) {
        throw StateError('El monto del pago debe ser mayor a cero');
      }
      final cuotas = await listarCuotas(cuentaId);
      final cobrosPrevios = await listarCobros(cuentaId);
      final totalAbonado = cobrosPrevios.fold<double>(
        0,
        (total, cobro) => total + cobro.montoAbonado,
      );
      final interesCronograma = cuotas.fold<double>(
        0,
        (total, cuota) => total + cuota.montoInteres,
      );
      final totalCuotas = cuotas.fold<double>(
        0,
        (total, cuota) => total + cuota.monto,
      );
      final totalObligacion = totalCuotas > 0
          ? totalCuotas
          : cuenta.montoOriginal + cuenta.montoInteresTotal;
      final abonadoEnCuotas = cuotas.fold<double>(
        0,
        (total, cuota) => total + cuota.montoPagado,
      );
      final saldoCuotas =
          (totalObligacion -
                  (cuotas.isNotEmpty ? abonadoEnCuotas : totalAbonado))
              .clamp(0.0, double.infinity);
      await _acumularMoraVencida(cuentaId, moraMensual: moraMensual);
      final moraPendiente = await _totalMoraPendiente(cuentaId);
      final saldoActual = saldoCuotas + moraPendiente;
      await (update(
        cuentasCobrarTable,
      )..where((t) => t.id.equals(cuentaId))).write(
        CuentasCobrarTableCompanion(
          montoInteresTotal: Value(
            interesCronograma > cuenta.montoInteresTotal
                ? interesCronograma
                : cuenta.montoInteresTotal,
          ),
          saldoPendiente: Value(saldoActual),
        ),
      );
      if (montoPago > saldoActual + 0.001) {
        throw StateError('El pago excede el saldo pendiente');
      }
      final moraAplicada = await _aplicarPagoAMora(cuentaId, montoPago);
      final cobroId = await into(cobrosTable).insert(
        cobro.copyWith(
          saldoAnterior: Value(saldoActual),
          saldoActual: Value(
            (saldoActual - montoPago).clamp(0.0, double.infinity),
          ),
        ),
      );
      await aplicarPagoACuotas(cuentaId, montoPago - moraAplicada);
      await actualizarSaldoYEstado(cuentaId);
      return cobroId;
    });
  }

  Future<List<CobroData>> listarCobros(int cuentaId) async {
    final query = select(cobrosTable)
      ..where((t) => t.cuentaCobrarId.equals(cuentaId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.fecha, mode: OrderingMode.desc),
      ]);
    return await query.get();
  }

  Future<void> actualizarSaldoYEstado(int cuentaId) async {
    final cuenta = await obtenerCuentaPorId(cuentaId);
    if (cuenta == null) return;
    final cobros = await listarCobros(cuentaId);
    final totalAbonado = cobros.fold<double>(
      0.0,
      (sum, c) => sum + c.montoAbonado,
    );
    final cuotas = await listarCuotas(cuentaId);
    final interesCronograma = cuotas.fold<double>(
      0,
      (total, cuota) => total + cuota.montoInteres,
    );
    final totalCuotas = cuotas.fold<double>(
      0,
      (total, cuota) => total + cuota.monto,
    );
    final totalObligacion = totalCuotas > 0
        ? totalCuotas
        : cuenta.montoOriginal + cuenta.montoInteresTotal;
    final abonadoCuotas = cuotas.fold<double>(
      0,
      (total, cuota) => total + cuota.montoPagado,
    );
    final saldoCuotas =
        (totalObligacion - (cuotas.isNotEmpty ? abonadoCuotas : totalAbonado))
            .clamp(0.0, double.infinity);
    final moraPendiente = await _totalMoraPendiente(cuentaId);
    final saldoPendiente = saldoCuotas + moraPendiente;
    CobrarEstado nuevoEstado;
    if (saldoPendiente <= 0.001) {
      nuevoEstado = CobrarEstado.pagado;
    } else {
      final diasVencido = _hoy.difference(cuenta.fechaVencimiento).inDays;
      if (diasVencido > 0) {
        nuevoEstado = CobrarEstado.vencido;
      } else if (totalAbonado > 0) {
        nuevoEstado = CobrarEstado.parcial;
      } else {
        nuevoEstado = CobrarEstado.pendiente;
      }
    }
    await (update(
      cuentasCobrarTable,
    )..where((t) => t.id.equals(cuentaId))).write(
      CuentasCobrarTableCompanion(
        montoAbonado: Value(totalAbonado),
        saldoPendiente: Value(saldoPendiente),
        montoInteresTotal: Value(
          interesCronograma > cuenta.montoInteresTotal
              ? interesCronograma
              : cuenta.montoInteresTotal,
        ),
        estado: Value(nuevoEstado),
      ),
    );
  }

  Future<Map<int, double>> moraPendientePorCuota(
    int cuentaId, {
    required double moraMensual,
    DateTime? hoy,
  }) async {
    final actual = _dia(hoy ?? DateTime.now());
    final cuotas = await listarCuotas(cuentaId);
    final diasGracia = await obtenerDiasGraciaMora();
    if (moraMensual < 0) {
      throw ArgumentError.value(moraMensual, 'moraMensual');
    }
    final ledgerRows = await customSelect(
      'SELECT cuota_id, monto_generado, monto_pagado, fecha_calculo_ms '
      'FROM moras_cuotas WHERE cuenta_cobrar_id = ?',
      variables: [Variable.withInt(cuentaId)],
    ).get();
    final ledgerPorCuota = {
      for (final row in ledgerRows) row.read<int>('cuota_id'): row,
    };
    return {
      for (final cuota in cuotas)
        cuota.id: _moraPendienteActual(
          cuota,
          ledgerPorCuota[cuota.id],
          moraMensual: moraMensual,
          diasGracia: diasGracia,
          hoy: actual,
        ),
    };
  }

  Future<double> obtenerTasaMoraMensual() async {
    final rows = await customSelect(
      'SELECT mora_porcentaje FROM parametros_credito_table '
      'ORDER BY id LIMIT 1',
    ).get();
    if (rows.isEmpty) return 0;
    return rows.first
        .read<double>('mora_porcentaje')
        .clamp(0.0, double.infinity);
  }

  Future<int> obtenerDiasGraciaMora() async {
    final rows = await customSelect(
      'SELECT dias_gracia FROM parametros_credito_table ORDER BY id LIMIT 1',
    ).get();
    if (rows.isEmpty) return 0;
    return rows.first.read<int>('dias_gracia').clamp(0, 3650);
  }

  double _moraPendienteActual(
    CuotaCuentaData cuota,
    QueryRow? ledger, {
    required double moraMensual,
    required int diasGracia,
    required DateTime hoy,
  }) {
    final saldo = (cuota.monto - cuota.montoPagado).clamp(0.0, double.infinity);
    final fechaVence = _dia(cuota.fechaVencimiento);
    final inicioMora = fechaVence.add(Duration(days: diasGracia));
    if (saldo <= 0.001 || !hoy.isAfter(inicioMora)) return 0;
    final generado = ledger?.read<double>('monto_generado') ?? 0.0;
    final pagado = ledger?.read<double>('monto_pagado') ?? 0.0;
    final fechaBase = ledger == null
        ? inicioMora
        : _dia(
            DateTime.fromMillisecondsSinceEpoch(
              ledger.read<int>('fecha_calculo_ms'),
            ),
          );
    final dias = hoy.difference(fechaBase).inDays.clamp(0, 1000000);
    final adicional = moraMensual <= 0 || dias <= 0
        ? 0.0
        : _redondearMoneda(saldo * moraMensual / 30 * dias);
    return _redondearMoneda(
      (generado - pagado + adicional).clamp(0.0, double.infinity),
    );
  }

  Future<void> _acumularMoraVencida(
    int cuentaId, {
    required double moraMensual,
    DateTime? hoy,
  }) async {
    final actual = _dia(hoy ?? DateTime.now());
    final cuotas = await listarCuotas(cuentaId);
    final diasGracia = await obtenerDiasGraciaMora();
    for (final cuota in cuotas) {
      final fechaVence = _dia(cuota.fechaVencimiento);
      final inicioMora = fechaVence.add(Duration(days: diasGracia));
      final saldo = (cuota.monto - cuota.montoPagado).clamp(
        0.0,
        double.infinity,
      );
      if (saldo <= 0.001 || !actual.isAfter(inicioMora)) continue;
      final rows = await customSelect(
        'SELECT monto_generado, monto_pagado, fecha_calculo_ms '
        'FROM moras_cuotas WHERE cuota_id = ?',
        variables: [Variable.withInt(cuota.id)],
      ).get();
      final ledger = rows.isEmpty ? null : rows.first;
      final fechaBase = ledger == null
          ? inicioMora
          : _dia(
              DateTime.fromMillisecondsSinceEpoch(
                ledger.read<int>('fecha_calculo_ms'),
              ),
            );
      final dias = actual.difference(fechaBase).inDays.clamp(0, 1000000);
      final previo = ledger?.read<double>('monto_generado') ?? 0.0;
      final adicional = moraMensual <= 0 || dias <= 0
          ? 0.0
          : _redondearMoneda(saldo * moraMensual / 30 * dias);
      final generado = _redondearMoneda(previo + adicional);
      if (generado <= 0.001 && ledger == null) continue;
      await customStatement(
        'INSERT INTO moras_cuotas '
        '(cuenta_cobrar_id, cuota_id, monto_generado, monto_pagado, fecha_calculo_ms) '
        'VALUES (?, ?, ?, ?, ?) '
        'ON CONFLICT(cuota_id) DO UPDATE SET '
        'monto_generado = excluded.monto_generado, '
        'fecha_calculo_ms = excluded.fecha_calculo_ms',
        [
          cuentaId,
          cuota.id,
          generado,
          ledger?.read<double>('monto_pagado') ?? 0.0,
          actual.millisecondsSinceEpoch,
        ],
      );
    }
  }

  Future<double> _totalMoraPendiente(int cuentaId) async {
    final rows = await customSelect(
      'SELECT COALESCE(SUM(monto_generado - monto_pagado), 0) AS total '
      'FROM moras_cuotas WHERE cuenta_cobrar_id = ?',
      variables: [Variable.withInt(cuentaId)],
    ).get();
    return rows.first.read<double>('total').clamp(0.0, double.infinity);
  }

  Future<double> _aplicarPagoAMora(int cuentaId, double monto) async {
    var restante = monto;
    var aplicado = 0.0;
    final rows = await customSelect(
      'SELECT id, monto_generado, monto_pagado FROM moras_cuotas '
      'WHERE cuenta_cobrar_id = ? AND monto_generado > monto_pagado '
      'ORDER BY cuota_id',
      variables: [Variable.withInt(cuentaId)],
    ).get();
    for (final row in rows) {
      if (restante <= 0.001) break;
      final pendiente =
          (row.read<double>('monto_generado') -
                  row.read<double>('monto_pagado'))
              .clamp(0.0, double.infinity);
      final abono = restante >= pendiente ? pendiente : restante;
      await customStatement(
        'UPDATE moras_cuotas SET monto_pagado = monto_pagado + ? WHERE id = ?',
        [abono, row.read<int>('id')],
      );
      restante -= abono;
      aplicado += abono;
    }
    return aplicado;
  }

  DateTime _dia(DateTime fecha) => DateTime(fecha.year, fecha.month, fecha.day);

  double _redondearMoneda(double monto) =>
      double.parse(monto.toStringAsFixed(2));

  Future<double> totalPorCobrar() async {
    final cuentas = await listarCuentas();
    return cuentas.fold<double>(0.0, (sum, c) => sum + c.saldoPendiente);
  }

  Future<double> totalVencido() async {
    final cuentas = await listarCuentas();
    final vencidas = cuentas.where((c) {
      if (c.estado == CobrarEstado.pagado) return false;
      if (c.saldoPendiente <= 0.001) return false;
      final f = c.fechaVencimiento;
      return DateTime.now().difference(f).inDays > 0;
    }).toList();
    return vencidas.fold<double>(0.0, (s, c) => s + c.saldoPendiente);
  }

  Future<int> cantidadClientesConDeuda() async {
    final cuentas = await listarCuentas();
    final Set<int> clientes = {};
    for (final c in cuentas) {
      if (c.saldoPendiente > 0.001) {
        clientes.add(c.clienteId);
      }
    }
    return clientes.length;
  }

  Future<int> cantidadClientesVencidos() async {
    final cuentas = await listarCuentas();
    final vencidas = cuentas.where((c) {
      if (c.estado == CobrarEstado.pagado) return false;
      if (c.saldoPendiente <= 0.001) return false;
      final f = c.fechaVencimiento;
      return DateTime.now().difference(f).inDays > 0;
    }).toList();
    return vencidas.map((c) => c.clienteId).toSet().length;
  }

  Future<List<CuentaCobrarData>> listarVencidas({int? limite}) async {
    final cuentas = await listarCuentas();
    final vencidas =
        cuentas.where((c) {
            if (c.estado == CobrarEstado.pagado) return false;
            if (c.saldoPendiente <= 0.001) return false;
            final f = c.fechaVencimiento;
            return DateTime.now().difference(f).inDays > 0;
          }).toList()
          ..sort((a, b) => b.fechaVencimiento.compareTo(a.fechaVencimiento));
    return vencidas;
  }

  Future<List<CuentaCobrarData>> listarProximasAVencer({
    required int diasAnticipacion,
    int? limite,
  }) async {
    final fechaLimite = _hoy.add(Duration(days: diasAnticipacion));
    final lista = await listarCuentas(
      venceDesde: _hoy,
      venceHasta: fechaLimite,
    );
    final filtradas = lista.where((c) => c.estado != CobrarEstado.pagado);
    return limite != null
        ? filtradas.take(limite).toList()
        : filtradas.toList();
  }

  Future<CuentaCobrarData?> obtenerCuentaPorVentaId(int ventaId) async {
    return await (select(
      cuentasCobrarTable,
    )..where((t) => t.ventaId.equals(ventaId))).getSingleOrNull();
  }

  /// NC: deja saldo 0 y estado pagado (cuenta saldada por nota de crédito).
  Future<void> anularCuentaPorNotaCredito(
    int ventaId, {
    String? referencia,
  }) async {
    final cuenta = await obtenerCuentaPorVentaId(ventaId);
    if (cuenta == null) return; // contado o sin CxC
    if (cuenta.saldoPendiente <= 0.001) return;
    await (update(
      cuentasCobrarTable,
    )..where((t) => t.id.equals(cuenta.id))).write(
      CuentasCobrarTableCompanion(
        montoAbonado: Value(cuenta.montoOriginal),
        saldoPendiente: const Value(0.0),
        estado: const Value(CobrarEstado.pagado),
      ),
    );
  }

  // ----- Plan de cuotas -----
  Future<void> eliminarCuotasDeCuenta(int cuentaId) async {
    await (delete(
      cuotasCuentaTable,
    )..where((t) => t.cuentaCobrarId.equals(cuentaId))).go();
  }

  Future<void> insertarCuota({
    required int cuentaCobrarId,
    required int numero,
    required double monto,
    required DateTime fechaVencimiento,
  }) async {
    await into(cuotasCuentaTable).insert(
      CuotasCuentaTableCompanion.insert(
        cuentaCobrarId: cuentaCobrarId,
        numero: numero,
        monto: monto,
        fechaVencimiento: fechaVencimiento,
      ),
    );
  }

  /// Genera N cuotas iguales (última ajusta centavos). Intervalo 30 días.
  Future<void> generarPlanCuotas({
    required int cuentaCobrarId,
    required double montoTotal,
    required int numeroCuotas,
    DateTime? primerVencimiento,
  }) async {
    if (numeroCuotas < 1) return;
    await eliminarCuotasDeCuenta(cuentaCobrarId);
    final n = numeroCuotas;
    final base = (montoTotal / n * 100).floor() / 100.0;
    var acumulado = 0.0;
    final inicio =
        primerVencimiento ?? DateTime.now().add(const Duration(days: 30));
    for (var i = 1; i <= n; i++) {
      final monto = i == n
          ? double.parse((montoTotal - acumulado).toStringAsFixed(2))
          : base;
      acumulado += monto;
      await insertarCuota(
        cuentaCobrarId: cuentaCobrarId,
        numero: i,
        monto: monto,
        fechaVencimiento: DateTime(
          inicio.year,
          inicio.month + (i - 1),
          inicio.day,
        ),
      );
    }
  }

  /// Inserta el plan ya calculado (sistema francés). No reparte monto/n.
  Future<void> insertarCuotasPlan({
    required int cuentaCobrarId,
    required List<
      ({
        int numero,
        DateTime fechaVencimiento,
        double monto,
        double montoCapital,
        double montoInteres,
      })
    >
    cuotas,
  }) async {
    await (delete(
      cuotasCuentaTable,
    )..where((t) => t.cuentaCobrarId.equals(cuentaCobrarId))).go();
    for (final c in cuotas) {
      await into(cuotasCuentaTable).insert(
        CuotasCuentaTableCompanion.insert(
          cuentaCobrarId: cuentaCobrarId,
          numero: c.numero,
          fechaVencimiento: c.fechaVencimiento,
          monto: c.monto,
          montoCapital: Value(c.montoCapital),
          montoInteres: Value(c.montoInteres),
          montoPagado: const Value(0.0),
          estado: const Value('pendiente'),
        ),
      );
    }
  }

  Future<List<CuotaCuentaData>> listarCuotas(int cuentaId) {
    return (select(cuotasCuentaTable)
          ..where((t) => t.cuentaCobrarId.equals(cuentaId))
          ..orderBy([(t) => OrderingTerm.asc(t.numero)]))
        .get();
  }

  Future<List<CuotaCuentaData>> listarCuotasDeCuentas(
    Iterable<int> cuentaIds,
  ) async {
    final ids = cuentaIds.toList(growable: false);
    if (ids.isEmpty) return const <CuotaCuentaData>[];
    return (select(cuotasCuentaTable)
          ..where((t) => t.cuentaCobrarId.isIn(ids))
          ..orderBy([
            (t) => OrderingTerm.asc(t.cuentaCobrarId),
            (t) => OrderingTerm.asc(t.numero),
          ]))
        .get();
  }

  /// Aplica un pago a las cuotas pendientes en orden.
  Future<void> aplicarPagoACuotas(int cuentaId, double montoPago) async {
    var resto = montoPago;
    final cuotas = await listarCuotas(cuentaId);
    for (final c in cuotas) {
      if (resto <= 0.001) break;
      if (c.estado == 'pagada') continue;
      final pendiente = (c.monto - c.montoPagado).clamp(0.0, double.infinity);
      if (pendiente <= 0.001) continue;
      final aplica = resto >= pendiente ? pendiente : resto;
      final nuevoPagado = c.montoPagado + aplica;
      final pagada = nuevoPagado + 0.001 >= c.monto;
      await (update(cuotasCuentaTable)..where((t) => t.id.equals(c.id))).write(
        CuotasCuentaTableCompanion(
          montoPagado: Value(nuevoPagado),
          estado: Value(pagada ? 'pagada' : 'parcial'),
          fechaPago: pagada ? Value(DateTime.now()) : const Value.absent(),
        ),
      );
      resto -= aplica;
    }
  }
}
