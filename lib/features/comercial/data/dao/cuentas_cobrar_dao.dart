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
  }) async {
    final vencimiento = fechaVencimiento ?? _hoy.add(const Duration(days: 30));
    final saldoPendiente = montoOriginal - montoAbonado;
    return await into(cuentasCobrarTable).insert(
      CuentasCobrarTableCompanion.insert(
        clienteId: clienteId,
        ventaId: ventaId,
        montoOriginal: montoOriginal,
        montoAbonado: Value(montoAbonado),
        saldoPendiente: saldoPendiente,
        fechaVencimiento: vencimiento,
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

  Future<int> registrarCobro(CobrosTableCompanion cobro) async {
    final cobroId = await into(cobrosTable).insert(cobro);
    if (cobro.cuentaCobrarId.present) {
      await actualizarSaldoYEstado(cobro.cuentaCobrarId.value);
    }
    return cobroId;
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
    final saldoPendiente = (cuenta.montoOriginal - totalAbonado).clamp(
      0.0,
      double.infinity,
    );
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
        estado: Value(nuevoEstado),
      ),
    );
  }

  Future<double> totalPorCobrar() async {
    final cuentas = await listarCuentas();
    return cuentas.fold<double>(0.0, (sum, c) => sum + c.saldoPendiente);
  }

  Future<double> totalVencido() async {
    final cuentas = await listarCuentas(estado: CobrarEstado.vencido);
    return cuentas.fold<double>(0.0, (sum, c) => sum + c.saldoPendiente);
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
    final cuentas = await listarCuentas(estado: CobrarEstado.vencido);
    final Set<int> clientes = {};
    for (final c in cuentas) {
      clientes.add(c.clienteId);
    }
    return clientes.length;
  }

  Future<List<CuentaCobrarData>> listarVencidas({int? limite}) async {
    final lista = await listarCuentas(estado: CobrarEstado.vencido);
    return limite != null ? lista.take(limite).toList() : lista;
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
    return await (select(cuentasCobrarTable)
          ..where((t) => t.ventaId.equals(ventaId)))
        .getSingleOrNull();
  }

  /// NC: deja saldo 0 y estado pagado (cuenta saldada por nota de crédito).
  Future<void> anularCuentaPorNotaCredito(int ventaId, {String? referencia}) async {
    final cuenta = await obtenerCuentaPorVentaId(ventaId);
    if (cuenta == null) return; // contado o sin CxC
    if (cuenta.saldoPendiente <= 0.001) return;
    await (update(cuentasCobrarTable)..where((t) => t.id.equals(cuenta.id)))
        .write(
      CuentasCobrarTableCompanion(
        montoAbonado: Value(cuenta.montoOriginal),
        saldoPendiente: const Value(0.0),
        estado: const Value(CobrarEstado.pagado),
      ),
    );
  }



  // ----- Plan de cuotas -----
  Future<void> eliminarCuotasDeCuenta(int cuentaId) async {
    await (delete(cuotasCuentaTable)
          ..where((t) => t.cuentaCobrarId.equals(cuentaId)))
        .go();
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
    final inicio = primerVencimiento ??
        DateTime.now().add(const Duration(days: 30));
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
    required List<({int numero, DateTime fechaVencimiento, double monto})> cuotas,
  }) async {
    await (delete(cuotasCuentaTable)
          ..where((t) => t.cuentaCobrarId.equals(cuentaCobrarId)))
        .go();
    for (final c in cuotas) {
      await into(cuotasCuentaTable).insert(
        CuotasCuentaTableCompanion.insert(
          cuentaCobrarId: cuentaCobrarId,
          numero: c.numero,
          fechaVencimiento: c.fechaVencimiento,
          monto: c.monto,
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
