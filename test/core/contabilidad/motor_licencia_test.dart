import 'package:flutter_test/flutter_test.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/asiento_contable.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/linea_asiento.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/plan_cuenta.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/enums/estado_asiento.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/enums/tipo_cuenta.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/repositories/i_asiento_repository.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/repositories/i_plan_cuentas_repository.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/services/motor_partida_doble.dart';

class _FakeAsientoRepo implements IAsientoRepository {
  int _seq = 1;
  final Map<int, AsientoContable> _cab = {};
  final Map<int, List<LineaAsiento>> _lin = {};

  @override
  Future<AsientoContable> registrar(
    AsientoContable asiento,
    List<LineaAsiento> lineas,
  ) async {
    final id = _seq++;
    final saved = asiento.copyWith(id: id);
    _cab[id] = saved;
    _lin[id] = lineas;
    return saved;
  }

  @override
  Future<AsientoContable?> obtenerPorId(int asientoId) async => _cab[asientoId];

  @override
  Future<List<LineaAsiento>> obtenerLineas(int asientoId) async =>
      _lin[asientoId] ?? [];

  @override
  Future<String> obtenerSiguienteNumero() async =>
      'AS-${_seq.toString().padLeft(4, '0')}';

  @override
  Future<bool> anular(int asientoId, String motivo) async {
    final a = _cab[asientoId];
    if (a == null) return false;
    _cab[asientoId] = a.copyWith(estado: EstadoAsiento.anulado);
    return true;
  }

  @override
  Future<List<AsientoContable>> listar({
    DateTime? desde,
    DateTime? hasta,
    int? cuentaId,
    int limite = 50,
    int offset = 0,
  }) async {
    var list = _cab.values.toList();
    if (desde != null) {
      list = list.where((a) => !a.fecha.isBefore(desde)).toList();
    }
    if (hasta != null) {
      list = list.where((a) => !a.fecha.isAfter(hasta)).toList();
    }
    if (offset > 0 && offset < list.length) {
      list = list.sublist(offset);
    } else if (offset >= list.length) {
      list = [];
    }
    if (list.length > limite) {
      list = list.take(limite).toList();
    }
    return list;
  }
}

class _FakePlanRepo implements IPlanCuentasRepository {
  static final _creado = DateTime(2026, 1, 1);

  final Map<int, PlanCuenta> _m = {
    1: PlanCuenta(
      id: 1,
      codigo: '1101',
      nombre: 'Caja',
      tipo: TipoCuenta.activo,
      nivel: 2,
      permiteMovimiento: true,
      activo: true,
      creadoEn: _creado,
    ),
    2: PlanCuenta(
      id: 2,
      codigo: '4101',
      nombre: 'Ingresos',
      tipo: TipoCuenta.ingreso,
      nivel: 2,
      permiteMovimiento: true,
      activo: true,
      creadoEn: _creado,
    ),
  };

  @override
  Future<PlanCuenta?> obtenerPorId(int cuentaId) async => _m[cuentaId];

  @override
  Future<PlanCuenta?> obtenerPorCodigo(String codigo) async {
    for (final c in _m.values) {
      if (c.codigo == codigo) return c;
    }
    return null;
  }

  @override
  Future<List<PlanCuenta>> obtenerArbolCompleto() async => _m.values.toList();

  @override
  Future<List<PlanCuenta>> obtenerHijas(int padreId) async =>
      _m.values.where((c) => c.padreId == padreId).toList();

  @override
  Future<List<PlanCuenta>> obtenerCuentasConMovimiento() async =>
      _m.values.where((c) => c.permiteMovimiento).toList();

  @override
  Future<int> insertar(PlanCuenta cuenta) async => 0;

  @override
  Future<bool> actualizar(PlanCuenta cuenta) async => true;

  @override
  Future<bool> desactivar(int cuentaId) async => true;

  @override
  Future<void> inicializarPlan(List<PlanCuenta> planCuentas) async {}
}

AsientoContable _borrador() => AsientoContable(
      numeroAsiento: '',
      fecha: DateTime(2026, 6, 15),
      concepto: 'Prueba licencia',
      estado: EstadoAsiento.borrador,
      creadoEn: DateTime(2026, 6, 15),
    );

List<LineaAsiento> _lineasCuadradas() => const [
      LineaAsiento(cuentaId: 1, debeCents: 10000, haberCents: 0),
      LineaAsiento(cuentaId: 2, debeCents: 0, haberCents: 10000),
    ];

void main() {
  test('P-L1 sin callback → acct_error_license_inactive', () async {
    final motor = MotorPartidaDoble(
      _FakeAsientoRepo(),
      planCuentas: _FakePlanRepo(),
    );
    expect(
      () => motor.registrar(asiento: _borrador(), lineas: _lineasCuadradas()),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'msg',
          contains('acct_error_license_inactive'),
        ),
      ),
    );
  });

  test('P-L2 callback false → acct_error_license_inactive', () async {
    final motor = MotorPartidaDoble(
      _FakeAsientoRepo(),
      planCuentas: _FakePlanRepo(),
      verificarLicencia: () async => false,
    );
    expect(
      () => motor.registrar(asiento: _borrador(), lineas: _lineasCuadradas()),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'msg',
          contains('acct_error_license_inactive'),
        ),
      ),
    );
  });

  test('P-L3 callback true → registra', () async {
    final motor = MotorPartidaDoble(
      _FakeAsientoRepo(),
      planCuentas: _FakePlanRepo(),
      verificarLicencia: () async => true,
    );
    final reg = await motor.registrar(
      asiento: _borrador(),
      lineas: _lineasCuadradas(),
    );
    expect(reg.id, greaterThan(0));
    expect(reg.estado, EstadoAsiento.contabilizado);
    expect(reg.numeroAsiento, isNotEmpty);
  });

  test('P-L4 anular sin licencia → bloqueado', () async {
    final repo = _FakeAsientoRepo();
    final motorOk = MotorPartidaDoble(
      repo,
      planCuentas: _FakePlanRepo(),
      verificarLicencia: () async => true,
    );
    final reg = await motorOk.registrar(
      asiento: _borrador(),
      lineas: _lineasCuadradas(),
    );

    final motorNo = MotorPartidaDoble(
      repo,
      planCuentas: _FakePlanRepo(),
      verificarLicencia: () async => false,
    );
    expect(
      () => motorNo.anular(reg.id, 'motivo test'),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'msg',
          contains('acct_error_license_inactive'),
        ),
      ),
    );
  });
}
