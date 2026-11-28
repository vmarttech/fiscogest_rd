import 'package:flutter_test/flutter_test.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/asiento_contable.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/linea_asiento.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/plan_cuenta.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/enums/estado_asiento.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/enums/tipo_cuenta.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/services/validador_asientos.dart';
import 'package:fiscogest_rd/core/contabilidad/data/seed/tasas_impuesto_seed.dart';

AsientoContable _borrador() => AsientoContable(
      numeroAsiento: '',
      fecha: DateTime(2026, 6, 15),
      concepto: 'Prueba',
      estado: EstadoAsiento.borrador,
      creadoEn: DateTime(2026, 6, 15),
    );

PlanCuenta _hoja(int id, {bool activa = true, bool movimiento = true}) =>
    PlanCuenta(
      id: id,
      codigo: '$id',
      nombre: 'C$id',
      tipo: TipoCuenta.activo,
      nivel: 2,
      padreId: 1,
      permiteMovimiento: movimiento,
      activo: activa,
      creadoEn: DateTime(2026, 1, 1),
    );

void main() {
  final v = ValidadorAsientos();

  // P1
  test('P1 asiento balanceado válido', () {
    final lineas = [
      LineaAsiento(cuentaId: 1, debeCents: 10000),
      LineaAsiento(cuentaId: 2, haberCents: 10000),
    ];
    expect(v.validar(_borrador(), lineas), isEmpty);
  });

  // P2
  test('P2 desbalanceado → acct_error_unbalanced', () {
    final lineas = [
      LineaAsiento(cuentaId: 1, debeCents: 10000),
      LineaAsiento(cuentaId: 2, haberCents: 9000),
    ];
    final e = v.validar(_borrador(), lineas);
    expect(e.any((x) => x.startsWith('acct_error_unbalanced')), isTrue);
  });

  // P3
  test('P3 debe y haber en misma línea inválida', () {
    final mala = LineaAsiento(cuentaId: 1, debeCents: 100, haberCents: 100);
    expect(mala.esValida, isFalse);
  });

  // P4 / P5
  test('P4 cuenta no hoja rechazada', () {
    final lineas = [
      LineaAsiento(cuentaId: 1, debeCents: 500),
      LineaAsiento(cuentaId: 2, haberCents: 500),
    ];
    final plan = {
      1: _hoja(1, movimiento: false),
      2: _hoja(2),
    };
    final e = v.validar(_borrador(), lineas, cuentasPorId: plan);
    expect(e.any((x) => x.startsWith('acct_error_account_not_leaf')), isTrue);
  });

  test('P5 cuenta inactiva rechazada', () {
    final lineas = [
      LineaAsiento(cuentaId: 1, debeCents: 500),
      LineaAsiento(cuentaId: 2, haberCents: 500),
    ];
    final plan = {
      1: _hoja(1, activa: false),
      2: _hoja(2),
    };
    final e = v.validar(_borrador(), lineas, cuentasPorId: plan);
    expect(e.any((x) => x.startsWith('acct_error_account_inactive')), isTrue);
  });

  // P10 redondeo ITBIS
  test('P10 ITBIS 18% centavos', () {
    // 100.00 * 18% = 18.00
    expect(TasasImpuestoSeedCatalogo.montoCents(10000, 1800), 1800);
    // 33.33 * 18% = 5.9994 → 6.00 con +5000
    expect(TasasImpuestoSeedCatalogo.montoCents(3333, 1800), 600);
  });
}
