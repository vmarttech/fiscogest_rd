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
      abonoInicial: row.montoAbonado,
      tasaInteres: row.tasaInteres,
      montoInteres: row.montoInteresTotal,
      numeroCuotas: row.numeroCuotas,
      fechaCreacion: row.fechaVencimiento,
      fechaVencimiento: row.fechaVencimiento,
      estado: _desdeCobrarEstado(row.estado, row.fechaVencimiento),
      abonos: abonos,
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
    final tasa = row.tasaInteres;
    final cuotas = [
      for (final q in cuotasRows)
        Cuota(
          id: q.id,
          numeroCuota: q.numero,
          fechaVencimiento: q.fechaVencimiento,
          montoCapital: q.montoCapital > 0.0001 ? q.montoCapital : (q.monto - q.montoInteres),
          montoInteres: q.montoInteres,
          montoTotal: q.monto,
          saldoDespues: (q.monto - q.montoPagado).clamp(0.0, double.infinity),
          pagada: q.estado == 'pagada',
          fechaPago: q.fechaPago,
        ),
    ];
    PlanPago? plan;
    if (cuotas.isNotEmpty) {
      plan = PlanPago(
        tasaInteresMensual: tasa,
        numeroCuotas: cuotas.length,
        montoPorCuota: cuotas.first.montoTotal,
        fechaPrimerVencimiento: cuotas.first.fechaVencimiento,
        cuotas: cuotas,
      );
    }
    return _mapear(row, abonos: abonos).copyWith(
      planPago: plan,
      numeroCuotas: cuotas.isEmpty ? row.numeroCuotas : cuotas.length,
      tasaInteres: tasa,
      montoInteres: row.montoInteresTotal,
    );
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
    final CobrarEstado? ce = estado != null ? _aCobrarEstado(estado) : null;
    final rows = await _dao.listarCuentas(
      estado: ce,
      clienteId: clienteId,
      fechaDesde: desde,
      fechaHasta: hasta,
      venceDesde: venceDesde,
      venceHasta: venceHasta,
      montoMinimo: montoMinimo,
      montoMaximo: montoMaximo,
    );
    return Future.wait(
      rows.map(
        (row) async => _mapear(
          row,
          abonos: await listarAbonos(row.id),
        ),
      ),
    );
  }

  @override
  Future<int> registrarAbono(AbonoCredito abono) async {
    final cuenta = await _dao.obtenerCuentaPorId(abono.cuentaId);
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
  Future<double> totalPorCobrar() => _dao.totalPorCobrar();

  @override
  Future<double> totalVencido() => _dao.totalVencido();

  @override
  Future<int> cantidadClientesConDeuda() => _dao.cantidadClientesConDeuda();

  @override
  Future<int> cantidadClientesVencidos() => _dao.cantidadClientesVencidos();

  @override
  Future<double> totalPorVencerEnRango(DateTime desde, DateTime hasta) async {
    final lista = await _dao.listarCuentas(
      venceDesde: desde,
      venceHasta: hasta,
    );
    return lista.fold<double>(0.0, (s, c) => s + c.saldoPendiente);
  }

  @override
  Future<List<CuentaPorCobrar>> listarVencidas({int? limite}) async {
    final rows = await _dao.listarVencidas(limite: limite);
    return Future.wait(
      rows.map(
        (row) async => _mapear(
          row,
          abonos: await listarAbonos(row.id),
        ),
      ),
    );
  }

  @override
  Future<List<CuentaPorCobrar>> listarProximasAVencer({
    required int diasAnticipacion,
    int? limite,
  }) async {
    final rows = await _dao.listarProximasAVencer(
      diasAnticipacion: diasAnticipacion,
      limite: limite,
    );
    return Future.wait(
      rows.map(
        (row) async => _mapear(
          row,
          abonos: await listarAbonos(row.id),
        ),
      ),
    );
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
