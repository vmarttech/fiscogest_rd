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

  @override
  Future<double?> obtenerSaldoActual() async {
    final ultimo = await cajaMovimientosDao.obtenerUltimoMovimiento();
    if (ultimo != null) {
      return ultimo.saldoNuevo;
    }
    return 0.0;
  }

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
    if (r.startsWith('B03') || d.contains('factura') || d.contains('cobro')) {
      return ReferenciaTipo.cobro;
    }
    if (r.startsWith('C-') || r.startsWith('CR-') || d.contains('venta')) {
      return ReferenciaTipo.venta;
    }
    if (d.contains('compra')) return ReferenciaTipo.compra;
    if (d.contains('apartado')) return ReferenciaTipo.apartado;
    if (d.contains('devol')) return ReferenciaTipo.devolucion;
    if (d.contains('pago')) return ReferenciaTipo.pago;
    return ReferenciaTipo.compra;
  }

  @override
  Future<void> registrarMovimiento({
    required String referencia,
    required double monto,
    required String tipo,
    required String descripcion,
    String formaPago = 'efectivo',
  }) async {
    final saldoAnterior = await obtenerSaldoActual() ?? 0.0;
    late double saldoNuevo;
    late MovimientoCaja tipoMovimiento;
    if (tipo == 'ingreso' || tipo == 'entrada') {
      saldoNuevo = saldoAnterior + monto;
      tipoMovimiento = MovimientoCaja.ingreso;
    } else {
      saldoNuevo = saldoAnterior - monto;
      tipoMovimiento = MovimientoCaja.egreso;
    }
    await cajaMovimientosDao.registrarMovimiento(
      CajaMovimientosTableCompanion(
        tipo: Value(tipoMovimiento),
        referenciaTipo: Value(_parseReferenciaTipo(referencia, descripcion)),
        referenciaId: Value(
          int.tryParse(referencia.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
        ),
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
    );
  }

  @override
  Future<int> abrirSesion({
    required double fondoInicial,
    int usuarioId = 1,
  }) async {
    final abierta = await cajaSesionesDao.obtenerSesionAbierta();
    if (abierta != null) {
      throw Exception(
        'Ya hay una caja abierta (sesión #${abierta.id}). Cierre esa sesión primero.',
      );
    }
    final id = await cajaSesionesDao.abrirSesion(
      fondoInicial: fondoInicial,
      usuarioId: usuarioId,
    );
    // Fondo inicial como ingreso en movimientos (saldo base del turno)
    if (fondoInicial > 0) {
      await registrarMovimiento(
        referencia: 'APERTURA-$id',
        monto: fondoInicial,
        tipo: 'ingreso',
        descripcion: 'Fondo inicial apertura caja sesión #$id',
        formaPago: 'efectivo',
      );
    }
    return id;
  }


  @override
  Future<List<CajaMovimientoResumen>> listarMovimientosDesde(
    DateTime desde,
  ) async {
    final hasta = DateTime.now().add(const Duration(days: 1));
    final filas = await cajaMovimientosDao.obtenerPorRango(desde, hasta);
    return filas
        .map(
          (m) => CajaMovimientoResumen(
            id: m.id,
            tipo: m.tipo.name,
            monto: m.monto,
            formaPago: m.formaPago.name,
            saldoNuevo: m.saldoNuevo,
            fecha: m.fecha,
            referenciaTipo: m.referenciaTipo.name,
            referenciaId: m.referenciaId,
          ),
        )
        .toList();
  }

  @override
  Future<bool> cerrarSesion({
    required int sesionId,
    required double saldoTeorico,
    required double montoContado,
    String? observacion,
  }) {
    return cajaSesionesDao.cerrarSesion(
      sesionId: sesionId,
      saldoTeorico: saldoTeorico,
      montoContado: montoContado,
      observacion: observacion,
    );
  }
}
