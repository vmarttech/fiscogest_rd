import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/abono_credito.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/cuenta_por_cobrar.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/estado_credito.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/plan_pago.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/cuota.dart';
import 'package:fiscogest_rd/features/creditos/domain/repositories/i_cuenta_por_cobrar_repository.dart';
import 'package:fiscogest_rd/features/creditos/domain/services/calculadora_credito_service.dart';

/// Implementación sobre [CuentasCobrarDao] y [CobrosTable] (feature comercial).
class CuentaPorCobrarRepositoryImpl implements ICuentaPorCobrarRepository {
  CuentaPorCobrarRepositoryImpl(this._dao);

  final CuentasCobrarDao _dao;

  CobrarEstado _aCobrarEstado(EstadoCredito e) {
    return switch (e) {
      EstadoCredito.pagado => CobrarEstado.pagado,
      EstadoCredito.vencido => CobrarEstado.vencido,
      EstadoCredito.proximoAVencer => CobrarEstado.pendiente,
      EstadoCredito.alDia => CobrarEstado.pendiente,
    };
  }

  EstadoCredito _desdeCobrarEstado(CobrarEstado e, DateTime venc) {
    final hoy = DateTime.now();
    return switch (e) {
      CobrarEstado.pagado => EstadoCredito.pagado,
      CobrarEstado.vencido => EstadoCredito.vencido,
      CobrarEstado.parcial =>
        venc.isBefore(hoy) ? EstadoCredito.vencido : EstadoCredito.alDia,
      CobrarEstado.pendiente =>
        venc.isBefore(hoy) ? EstadoCredito.vencido : EstadoCredito.alDia,
    };
  }

  CuentaPorCobrar _mapear(
    CuentaCobrarData row, {
    List<AbonoCredito> abonos = const [],
  }) {
    return CuentaPorCobrar(
      id: row.id,
      numero: 'CXC-${row.id.toString().padLeft(6, '0')}',
      clienteId: row.clienteId,
      ventaId: row.ventaId,
      totalOriginal: row.montoOriginal,
      // El capital se guarda neto del abono inicial; montoAbonado es el
      // acumulado de cobros posteriores.
      abonoInicial: 0,
      tasaInteres: row.tasaInteres,
      montoInteres: row.montoInteresTotal,
      numeroCuotas: row.numeroCuotas,
      fechaCreacion: row.fechaVencimiento,
      fechaVencimiento: row.fechaVencimiento,
      estado: _desdeCobrarEstado(row.estado, row.fechaVencimiento),
      abonos: abonos,
    );
  }

  List<Cuota> _mapearCuotas(
    Iterable<CuotaCuentaData> rows, {
    Map<int, double> moraPorCuota = const <int, double>{},
  }) => [
    for (final q in rows)
      Cuota(
        id: q.id,
        numeroCuota: q.numero,
        fechaVencimiento: q.fechaVencimiento,
        montoCapital: q.montoCapital > 0.0001
            ? q.montoCapital
            : (q.monto - q.montoInteres),
        montoInteres: q.montoInteres,
        montoTotal: q.monto,
        saldoDespues: (q.monto - q.montoPagado).clamp(0.0, double.infinity),
        saldoCuotaPendiente: (q.monto - q.montoPagado).clamp(
          0.0,
          double.infinity,
        ),
        pagada: q.estado == 'pagada' || q.monto - q.montoPagado <= 0.001,
        fechaPago: q.fechaPago,
        moraPendiente: moraPorCuota[q.id] ?? 0,
      ),
  ];

  Future<CuentaPorCobrar> _mapearConCuotas(
    CuentaCobrarData row, {
    required List<AbonoCredito> abonos,
    required List<CuotaCuentaData> cuotasRows,
  }) async {
    final cuenta = _mapear(row, abonos: abonos);
    final moraMensual = await _dao.obtenerTasaMoraMensual();
    final moraPorCuota = cuotasRows.isEmpty
        ? const <int, double>{}
        : await _dao.moraPendientePorCuota(row.id, moraMensual: moraMensual);
    final cuotas = _mapearCuotas(cuotasRows, moraPorCuota: moraPorCuota);
    if (cuotas.isEmpty) return cuenta.copyWith(estado: cuenta.estadoActual());
    final interesCronograma = cuotas.fold<double>(
      0,
      (total, cuota) => total + cuota.montoInteres,
    );
    final plan = PlanPago(
      tasaInteresMensual: row.tasaInteres,
      numeroCuotas: cuotas.length,
      montoPorCuota: cuotas.first.montoTotal,
      fechaPrimerVencimiento: cuotas.first.fechaVencimiento,
      cuotas: cuotas,
    );
    final conPlan = cuenta.copyWith(
      planPago: plan,
      numeroCuotas: cuotas.length,
      tasaInteres: row.tasaInteres,
      montoInteres: interesCronograma > row.montoInteresTotal
          ? interesCronograma
          : row.montoInteresTotal,
      moraCalculada: moraPorCuota.values.fold<double>(0, (a, b) => a + b),
    );
    return conPlan.copyWith(
      fechaVencimiento: conPlan.fechaProximoVencimiento,
      estado: conPlan.estadoActual(),
    );
  }

  FormaPago _parseFormaPago(String? raw) {
    final t = (raw ?? 'efectivo').toLowerCase();
    for (final f in FormaPago.values) {
      if (f.name.toLowerCase() == t) return f;
    }
    // fallback frecuente en el proyecto
    try {
      return FormaPago.values.byName('efectivo');
    } catch (_) {
      return FormaPago.values.first;
    }
  }

  @override
  Future<int> registrarCredito({
    required CuentaPorCobrar cuenta,
    PlanPago? planPago,
    AbonoCredito? abonoInicial,
  }) async {
    final ventaId = cuenta.ventaId;
    if (ventaId == null || ventaId <= 0) {
      throw Exception('La cuenta de crédito requiere ventaId de la cotización');
    }
    final abono = abonoInicial?.monto ?? cuenta.abonoInicial;
    final nCuotas = cuenta.numeroCuotas < 1 ? 1 : cuenta.numeroCuotas;
    final tasa = cuenta.tasaInteres;
    final totalVenta = cuenta.totalOriginal;
    final capital = (totalVenta - abono).clamp(0.0, double.infinity);

    PlanPago plan = (planPago != null && planPago.cuotas.isNotEmpty)
        ? planPago
        : CalculadoraCreditoService.generarPlanPago(
            capital: capital,
            tasaMensual: tasa,
            numeroCuotas: nCuotas,
            fechaPrimerVencimiento: cuenta.fechaVencimiento,
          );
    if (plan.cuotas.isEmpty && nCuotas >= 1) {
      plan = CalculadoraCreditoService.generarPlanPago(
        capital: capital,
        tasaMensual: tasa,
        numeroCuotas: nCuotas,
        fechaPrimerVencimiento: cuenta.fechaVencimiento,
      );
    }

    final id = await _dao.crearCuentaPorVenta(
      clienteId: cuenta.clienteId,
      ventaId: ventaId,
      montoOriginal: capital,
      montoAbonado: 0.0,
      fechaVencimiento: cuenta.fechaVencimiento,
      montoInteresTotal: plan.cuotas.fold<double>(
        0,
        (total, cuota) => total + cuota.montoInteres,
      ),
    );

    if (plan.cuotas.isNotEmpty) {
      await _dao.insertarCuotasPlan(
        cuentaCobrarId: id,
        cuotas: [
          for (final c in plan.cuotas)
            (
              numero: c.numeroCuota,
              fechaVencimiento: c.fechaVencimiento,
              monto: c.montoTotal,
              montoCapital: c.montoCapital,
              montoInteres: c.montoInteres,
            ),
        ],
      );
    } else {
      await _dao.generarPlanCuotas(
        cuentaCobrarId: id,
        montoTotal: capital,
        numeroCuotas: nCuotas,
        primerVencimiento: cuenta.fechaVencimiento,
      );
    }
    return id;
  }

  @override
  Future<CuentaPorCobrar?> obtenerPorId(int cuentaId) async {
    final row = await _dao.obtenerCuentaPorId(cuentaId);
    if (row == null) return null;
    final abonos = await listarAbonos(cuentaId);
    final cuotasRows = await _dao.listarCuotas(cuentaId);
    return _mapearConCuotas(row, abonos: abonos, cuotasRows: cuotasRows);
  }

  @override
  Future<List<CuentaPorCobrar>> listarCuentas({
    EstadoCredito? estado,
    int? clienteId,
    DateTime? desde,
    DateTime? hasta,
    DateTime? venceDesde,
    DateTime? venceHasta,
    double? montoMinimo,
    double? montoMaximo,
    String? busqueda,
  }) async {
    final rows = await _dao.listarCuentas(
      // El estado almacenado puede quedar viejo cuando llega una fecha de pago.
      // Se determina luego usando las cuotas pendientes de cada cuenta.
      estado: null,
      clienteId: clienteId,
      fechaDesde: desde,
      fechaHasta: hasta,
      venceDesde: null,
      venceHasta: null,
      montoMinimo: montoMinimo,
      montoMaximo: montoMaximo,
    );
    final cuotasRows = await _dao.listarCuotasDeCuentas(rows.map((r) => r.id));
    final cuotasPorCuenta = <int, List<CuotaCuentaData>>{};
    for (final cuota in cuotasRows) {
      cuotasPorCuenta.putIfAbsent(cuota.cuentaCobrarId, () => []).add(cuota);
    }
    final cuentas = await Future.wait(
      rows.map(
        (row) async => _mapearConCuotas(
          row,
          abonos: await listarAbonos(row.id),
          cuotasRows: cuotasPorCuenta[row.id] ?? const <CuotaCuentaData>[],
        ),
      ),
    );
    final desdeVence = venceDesde == null ? null : _dia(venceDesde);
    final hastaVence = venceHasta == null ? null : _dia(venceHasta);
    return cuentas
        .where((cuenta) {
          if (estado != null && cuenta.estadoActual() != estado) return false;
          final fecha = _dia(cuenta.fechaProximoVencimiento);
          if (desdeVence != null && fecha.isBefore(desdeVence)) return false;
          if (hastaVence != null && fecha.isAfter(hastaVence)) return false;
          return true;
        })
        .toList(growable: false);
  }

  DateTime _dia(DateTime fecha) => DateTime(fecha.year, fecha.month, fecha.day);

  @override
  Future<int> registrarAbono(AbonoCredito abono) async {
    final cuenta = await obtenerPorId(abono.cuentaId);
    if (cuenta == null) throw StateError('La cuenta por cobrar no existe');
    final saldoAnt = cuenta.saldoPendiente;
    if (abono.monto <= 0) {
      throw StateError('El monto del pago debe ser mayor a cero');
    }
    if (abono.monto > saldoAnt + 0.001) {
      throw StateError('El pago excede el saldo pendiente');
    }

    return _dao.registrarPago(
      cuentaId: abono.cuentaId,
      montoPago: abono.monto,
      moraMensual: await _dao.obtenerTasaMoraMensual(),
      cobro: CobrosTableCompanion.insert(
        cuentaCobrarId: abono.cuentaId,
        fecha: abono.fecha,
        montoAbonado: abono.monto,
        formaPago: _parseFormaPago(abono.metodoPago),
        saldoAnterior: saldoAnt,
        saldoActual: (saldoAnt - abono.monto).clamp(0.0, double.infinity),
      ),
    );
  }

  @override
  Future<void> actualizarEstado(int cuentaId, EstadoCredito nuevoEstado) {
    return _dao.actualizarEstado(cuentaId, _aCobrarEstado(nuevoEstado));
  }

  @override
  Future<void> marcarComoPagada(int cuentaId) {
    return _dao.actualizarEstado(cuentaId, CobrarEstado.pagado);
  }

  @override
  Future<void> cancelarCuenta(int cuentaId, String motivo) {
    // Sin estado cancelado en BD comercial: se deja como pendiente documentado en motivo (fase futura)
    return _dao.actualizarEstado(cuentaId, CobrarEstado.pendiente);
  }

  @override
  Future<List<AbonoCredito>> listarAbonos(int cuentaId) async {
    final cobros = await _dao.listarCobros(cuentaId);
    return [
      for (final c in cobros)
        AbonoCredito(
          cuentaId: cuentaId,
          monto: c.montoAbonado,
          fecha: c.fecha,
          metodoPago: c.formaPago.name,
          usuarioId: 1,
        ),
    ];
  }

  @override
  Future<List<CuentaPorCobrar>> listarCuentasPorCliente(int clienteId) {
    return listarCuentas(clienteId: clienteId);
  }

  @override
  Future<double> totalPorCobrar() async {
    final cuentas = await listarCuentas();
    return cuentas.fold<double>(
      0,
      (total, cuenta) => total + cuenta.saldoPendiente,
    );
  }

  @override
  Future<double> totalVencido() async {
    final cuentas = await listarCuentas();
    return cuentas.fold<double>(
      0,
      (total, cuenta) =>
          total + cuenta.saldoCuotasVencidas() + cuenta.moraCalculada,
    );
  }

  @override
  Future<int> cantidadClientesConDeuda() async {
    final cuentas = await listarCuentas();
    return cuentas
        .where((cuenta) => cuenta.saldoPendiente > 0.001)
        .map((cuenta) => cuenta.clienteId)
        .toSet()
        .length;
  }

  @override
  Future<int> cantidadClientesVencidos() async {
    final cuentas = await listarCuentas();
    return cuentas
        .where((cuenta) => cuenta.estadoActual() == EstadoCredito.vencido)
        .map((cuenta) => cuenta.clienteId)
        .toSet()
        .length;
  }

  @override
  Future<double> totalPorVencerEnRango(DateTime desde, DateTime hasta) async {
    final inicio = _dia(desde);
    final fin = _dia(hasta);
    final cuentas = await listarCuentas();
    return cuentas.fold<double>(0, (total, cuenta) {
      final fecha = _dia(cuenta.fechaProximoVencimiento);
      if (fecha.isBefore(inicio) || fecha.isAfter(fin)) return total;
      return total + cuenta.saldoPendiente;
    });
  }

  @override
  Future<List<CuentaPorCobrar>> listarVencidas({int? limite}) async {
    final cuentas = await listarCuentas();
    final vencidas =
        cuentas
            .where((cuenta) => cuenta.estadoActual() == EstadoCredito.vencido)
            .toList()
          ..sort(
            (a, b) => b
                .diasVencido(DateTime.now())
                .compareTo(a.diasVencido(DateTime.now())),
          );
    return limite == null ? vencidas : vencidas.take(limite).toList();
  }

  @override
  Future<List<CuentaPorCobrar>> listarProximasAVencer({
    required int diasAnticipacion,
    int? limite,
  }) async {
    final hoy = _dia(DateTime.now());
    final limiteFecha = hoy.add(Duration(days: diasAnticipacion));
    final proximas =
        (await listarCuentas()).where((cuenta) {
          if (cuenta.estaPagada ||
              cuenta.estadoActual(hoy: hoy) == EstadoCredito.vencido) {
            return false;
          }
          final fecha = _dia(cuenta.fechaProximoVencimiento);
          return !fecha.isBefore(hoy) && !fecha.isAfter(limiteFecha);
        }).toList()..sort(
          (a, b) =>
              a.fechaProximoVencimiento.compareTo(b.fechaProximoVencimiento),
        );
    return limite == null ? proximas : proximas.take(limite).toList();
  }

  @override
  Future<void> generarPlanCuotas({
    required int cuentaId,
    required int numeroCuotas,
    DateTime? primerVencimiento,
  }) async {
    final row = await _dao.obtenerCuentaPorId(cuentaId);
    if (row == null) throw Exception('Cuenta no encontrada');
    final monto = row.saldoPendiente > 0.001
        ? row.saldoPendiente
        : row.montoOriginal;
    final n = numeroCuotas < 1 ? 1 : numeroCuotas;
    await _dao.generarPlanCuotas(
      cuentaCobrarId: cuentaId,
      montoTotal: monto,
      numeroCuotas: n,
      primerVencimiento: primerVencimiento ?? row.fechaVencimiento,
    );
  }
}
