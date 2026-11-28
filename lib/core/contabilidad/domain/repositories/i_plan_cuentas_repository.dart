import 'package:fiscogest_rd/core/contabilidad/domain/entities/plan_cuenta.dart';

abstract class IPlanCuentasRepository {
  Future<List<PlanCuenta>> obtenerArbolCompleto();
  Future<PlanCuenta?> obtenerPorId(int cuentaId);
  Future<PlanCuenta?> obtenerPorCodigo(String codigo);
  Future<List<PlanCuenta>> obtenerHijas(int padreId);
  Future<List<PlanCuenta>> obtenerCuentasConMovimiento();
  Future<int> insertar(PlanCuenta cuenta);
  Future<bool> actualizar(PlanCuenta cuenta);
  Future<bool> desactivar(int cuentaId);
  Future<bool> activar(int cuentaId);
  Future<void> inicializarPlan(List<PlanCuenta> planCuentas);
}
