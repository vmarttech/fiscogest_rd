import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/caja/domain/repositories/i_caja_repository.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/caja_movimientos_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

class CajaRepositoryImpl implements ICajaRepository {
  CajaRepositoryImpl({required this.cajaMovimientosDao});
  final CajaMovimientosDao cajaMovimientosDao;

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
    if (v.contains('credito') || v.contains('crédito')) return FormaPago.credito;
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
}
