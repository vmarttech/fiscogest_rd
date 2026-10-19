import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/caja/domain/repositories/i_caja_repository.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/caja_movimientos_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/caja_sesiones_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

class CajaRepositoryImpl implements ICajaRepository {
  CajaRepositoryImpl({
    required this.cajaMovimientosDao,
    required this.cajaSesionesDao,
  });

  final CajaMovimientosDao cajaMovimientosDao;
  final CajaSesionesDao cajaSesionesDao;

  FormaPago _parseFormaPago(String valor) {
    final v = valor.toLowerCase().trim();
    if (v.contains('tarjeta')) return FormaPago.tarjeta;
    if (v.contains('transfer')) return FormaPago.transferencia;
    if (v.contains('credito') || v.contains('crédito')) {
      return FormaPago.credito;
    }
    if (v.contains('cheque')) return FormaPago.cheque;
    return FormaPago.efectivo;
  }

  ReferenciaTipo _parseReferenciaTipo(String referencia, String descripcion) {
    final r = referencia.toUpperCase();
    final d = descripcion.toLowerCase();
    if (r.startsWith('APERTURA')) return ReferenciaTipo.ajuste;
    if (r.startsWith('B03') || d.contains('factura') || d.contains('cobro')) {
      return ReferenciaTipo.cobro;
    }
    if (r.startsWith('C-') || r.startsWith('CR-') || d.contains('venta')) {
      return ReferenciaTipo.venta;
    }
    if (d.contains('proveedor') || d.contains('compra')) {
      return ReferenciaTipo.pago;
    }
    if (d.contains('apartado')) return ReferenciaTipo.apartado;
    if (d.contains('devol')) return ReferenciaTipo.devolucion;
    if (d.contains('pago')) return ReferenciaTipo.pago;
    return ReferenciaTipo.cobro;
  }

  CajaMovimientoResumen _mapMov(CajaMovimientoData m) => CajaMovimientoResumen(
        id: m.id,
        tipo: m.tipo.name,
        monto: m.monto,
        formaPago: m.formaPago.name,
        saldoNuevo: m.saldoNuevo,
        fecha: m.fecha,
        referenciaTipo: m.referenciaTipo.name,
        referenciaId: m.referenciaId,
        sesionId: m.sesionId,
      );

  /// Efectivo del cajón de la sesión = fondo + ingresos EFECTIVO − egresos EFECTIVO.
  /// No incluye tarjeta, transferencia, cheque ni crédito.
  Future<double> _efectivoEsperadoSesion({
    required double fondoInicial,
    required List<CajaMovimientoData> movs,
  }) async {
    var ingresosEf = 0.0;
    var egresosEf = 0.0;
    for (final m in movs) {
      if (m.formaPago != FormaPago.efectivo) continue;
      if (m.tipo == MovimientoCaja.ingreso) {
        ingresosEf += m.monto;
      } else {
        egresosEf += m.monto;
      }
    }
    return fondoInicial + ingresosEf - egresosEf;
  }

  ResumenSesionCaja _resumenFrom({
    required int sesionId,
    required double fondoInicial,
    required List<CajaMovimientoData> movs,
  }) {
    var ingEf = 0.0, egrEf = 0.0;
    var ingTar = 0.0, ingTrf = 0.0, ingChq = 0.0, ingCre = 0.0;
    var totalIng = 0.0, totalEgr = 0.0;

    for (final m in movs) {
      if (m.tipo == MovimientoCaja.ingreso) {
        totalIng += m.monto;
        switch (m.formaPago) {
          case FormaPago.efectivo:
            ingEf += m.monto;
          case FormaPago.tarjeta:
            ingTar += m.monto;
          case FormaPago.transferencia:
            ingTrf += m.monto;
          case FormaPago.cheque:
            ingChq += m.monto;
          case FormaPago.credito:
            ingCre += m.monto;
        }
      } else {
        totalEgr += m.monto;
        if (m.formaPago == FormaPago.efectivo) {
          egrEf += m.monto;
        }
      }
    }

    return ResumenSesionCaja(
      sesionId: sesionId,
      fondoInicial: fondoInicial,
      ingresosEfectivo: ingEf,
      egresosEfectivo: egrEf,
      efectivoEsperado: fondoInicial + ingEf - egrEf,
      ingresosTarjeta: ingTar,
      ingresosTransferencia: ingTrf,
      ingresosCheque: ingChq,
      ingresosCredito: ingCre,
      totalIngresos: totalIng,
      totalEgresos: totalEgr,
    );
  }

  @override
  Future<double?> obtenerSaldoActual() async {
    final sesion = await cajaSesionesDao.obtenerSesionAbierta();
    if (sesion == null) return null;
    final movs = await cajaMovimientosDao.obtenerPorSesion(sesion.id);
    return _efectivoEsperadoSesion(
      fondoInicial: sesion.fondoInicial,
      movs: movs,
    );
  }

  @override
  Future<void> registrarMovimiento({
    required String referencia,
    required double monto,
    required String tipo,
    required String descripcion,
    String formaPago = 'efectivo',
  }) async {
    if (monto <= 0) {
      throw Exception('El monto del movimiento debe ser mayor a cero');
    }

    final sesion = await cajaSesionesDao.obtenerSesionAbierta();
    if (sesion == null) {
      throw Exception(
        'No hay caja abierta. Abra un turno antes de registrar movimientos.',
      );
    }

    // Ledger global solo como traza; no define el cuadre del turno.
    final saldoAnterior =
        await cajaMovimientosDao.obtenerSaldoLedgerGlobal() ?? 0.0;
    final esIngreso = tipo == 'ingreso' || tipo == 'entrada';
    final saldoNuevo =
        esIngreso ? saldoAnterior + monto : saldoAnterior - monto;

    final refTipo = _parseReferenciaTipo(referencia, descripcion);
    final refId =
        int.tryParse(referencia.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    // Idempotencia: no registrar dos veces el mismo cobro/egreso en la sesión
    if (refId > 0) {
      final existente = await cajaMovimientosDao.obtenerPorReferenciaEnSesion(
        sesionId: sesion.id,
        referenciaId: refId,
        referenciaTipoName: refTipo.name,
      );
      if (existente != null &&
          existente.tipo ==
              (esIngreso ? MovimientoCaja.ingreso : MovimientoCaja.egreso) &&
          (existente.monto - monto).abs() < 0.01) {
        // Ya registrado en este turno → no-op
        return;
      }
    }

    await cajaMovimientosDao.registrarMovimiento(
      CajaMovimientosTableCompanion(
        sesionId: Value(sesion.id),
        tipo: Value(esIngreso ? MovimientoCaja.ingreso : MovimientoCaja.egreso),
        referenciaTipo: Value(refTipo),
        referenciaId: Value(refId),
        monto: Value(monto),
        formaPago: Value(_parseFormaPago(formaPago)),
        saldoAnterior: Value(saldoAnterior),
        saldoNuevo: Value(saldoNuevo),
      ),
    );
  }

  @override
  Future<CajaSesionResumen?> obtenerSesionAbierta() async {
    final s = await cajaSesionesDao.obtenerSesionAbierta();
    if (s == null) return null;
    return CajaSesionResumen(
      id: s.id,
      fechaApertura: s.fechaApertura,
      fondoInicial: s.fondoInicial,
      usuarioId: s.usuarioId,
      estado: s.estado,
      fechaCierre: s.fechaCierre,
      saldoTeorico: s.saldoTeorico,
      montoContado: s.montoContado,
    );
  }

  @override
  Future<int> abrirSesion({
    required double fondoInicial,
    int usuarioId = 1,
  }) async {
    if (fondoInicial < 0) {
      throw Exception('El fondo inicial no puede ser negativo');
    }
    final abierta = await cajaSesionesDao.obtenerSesionAbierta();
    if (abierta != null) {
      throw Exception(
        'Ya hay una caja abierta (sesión #${abierta.id}). Cierre esa sesión primero.',
      );
    }

    // Solo graba sesión. El fondo NO se registra como ingreso sobre el ledger
    // global: el efectivo del turno parte de fondoInicial en la sesión.
    final id = await cajaSesionesDao.abrirSesion(
      fondoInicial: fondoInicial,
      usuarioId: usuarioId,
    );
    return id;
  }

  @override
  Future<ResumenSesionCaja> obtenerResumenSesion(int sesionId) async {
    final s = await cajaSesionesDao.obtenerPorId(sesionId);
    if (s == null) {
      throw Exception('Sesión #$sesionId no encontrada');
    }
    final movs = await cajaMovimientosDao.obtenerPorSesion(sesionId);
    return _resumenFrom(
      sesionId: sesionId,
      fondoInicial: s.fondoInicial,
      movs: movs,
    );
  }

  @override
  Future<List<CajaMovimientoResumen>> listarMovimientosPorSesion(
    int sesionId,
  ) async {
    final filas = await cajaMovimientosDao.obtenerPorSesion(sesionId);
    return filas.map(_mapMov).toList();
  }

  @override
  Future<List<CajaMovimientoResumen>> listarMovimientosDesde(
    DateTime desde,
  ) async {
    // Preferir sesión abierta si existe
    final abierta = await cajaSesionesDao.obtenerSesionAbierta();
    if (abierta != null) {
      return listarMovimientosPorSesion(abierta.id);
    }
    final hasta = DateTime.now().add(const Duration(days: 1));
    final filas = await cajaMovimientosDao.obtenerPorRango(desde, hasta);
    return filas.map(_mapMov).toList();
  }

  @override
  Future<bool> cerrarSesion({
    required int sesionId,
    required double saldoTeorico,
    required double montoContado,
    String? observacion,
  }) async {
    // Siempre recalcular efectivo de la sesión (no confiar en saldo global).
    final resumen = await obtenerResumenSesion(sesionId);
    final teorico = resumen.efectivoEsperado;
    return cajaSesionesDao.cerrarSesion(
      sesionId: sesionId,
      saldoTeorico: teorico,
      montoContado: montoContado,
      observacion: observacion,
    );
  }

  @override
  Future<CajaSesionResumen?> obtenerUltimaSesionCerrada() async {
    final s = await cajaSesionesDao.obtenerUltimaSesionCerrada();
    if (s == null) return null;
    return CajaSesionResumen(
      id: s.id,
      fechaApertura: s.fechaApertura,
      fondoInicial: s.fondoInicial,
      usuarioId: s.usuarioId,
      estado: s.estado,
      fechaCierre: s.fechaCierre,
      saldoTeorico: s.saldoTeorico,
      montoContado: s.montoContado,
    );
  }

}
