import 'package:fiscogest_rd/core/contabilidad/domain/config/contabilidad_pais_config.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/config/cuenta_rol.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/config/plantilla_contrapartida.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/plan_cuenta.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/enums/tipo_cuenta.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/repositories/i_plan_cuentas_repository.dart';

/// Seed del plan mínimo según país activo (DO / MX / PR).
/// Idempotente: no re-siembra si ya hay cuentas.
class PlanCuentasRdSeed {
  PlanCuentasRdSeed(this._repo);

  final IPlanCuentasRepository _repo;

  Future<void> asegurarPlanMinimo({String? paisCodigo}) async {
    final existentes = await _repo.obtenerArbolCompleto();
    if (existentes.isNotEmpty) return;

    final pais = (paisCodigo ?? ContabilidadPaisConfig.paisCodigo).toUpperCase();
    final plantilla = PlantillasContrapartida.porPais(pais);
    final ahora = DateTime.now();

    Future<int> grupo({
      required String codigo,
      required String nombre,
      required TipoCuenta tipo,
      int nivel = 1,
      int? padreId,
    }) async {
      final id = await _repo.insertar(PlanCuenta(
        id: 0,
        codigo: codigo,
        nombre: nombre,
        tipo: tipo,
        padreId: padreId,
        nivel: nivel,
        permiteMovimiento: false,
        activo: true,
        creadoEn: ahora,
      ));
      if (id <= 0) throw StateError('acct_error_seed_group_failed:$codigo');
      return id;
    }

    Future<void> hoja({
      required String codigo,
      required String nombre,
      required TipoCuenta tipo,
      required int padreId,
      required int nivel,
    }) async {
      final id = await _repo.insertar(PlanCuenta(
        id: 0,
        codigo: codigo,
        nombre: nombre,
        tipo: tipo,
        padreId: padreId,
        nivel: nivel,
        permiteMovimiento: true,
        activo: true,
        creadoEn: ahora,
      ));
      if (id <= 0) throw StateError('acct_error_seed_leaf_failed:$codigo');
    }

    String c(CuentaRol r) => plantilla.codigo(r);

    // Grupos genéricos (códigos de agrupación internos; no los usa el listener).
    final activo = await grupo(codigo: '1', nombre: 'ACTIVO', tipo: TipoCuenta.activo);
    final pasivo = await grupo(codigo: '2', nombre: 'PASIVO', tipo: TipoCuenta.pasivo);
    final ingresos = await grupo(codigo: '4', nombre: 'INGRESOS', tipo: TipoCuenta.ingreso);
    final costos = await grupo(codigo: '5', nombre: 'COSTOS', tipo: TipoCuenta.costo);

    await hoja(codigo: c(CuentaRol.caja), nombre: 'Caja general', tipo: TipoCuenta.activo, padreId: activo, nivel: 2);
    await hoja(codigo: c(CuentaRol.cxc), nombre: 'Cuentas por cobrar', tipo: TipoCuenta.activo, padreId: activo, nivel: 2);
    await hoja(codigo: c(CuentaRol.impuestoCredito), nombre: '${plantilla.etiquetaImpuesto} crédito fiscal', tipo: TipoCuenta.activo, padreId: activo, nivel: 2);
    await hoja(codigo: c(CuentaRol.inventario), nombre: 'Inventario de mercancías', tipo: TipoCuenta.activo, padreId: activo, nivel: 2);

    await hoja(codigo: c(CuentaRol.cxp), nombre: 'Cuentas por pagar', tipo: TipoCuenta.pasivo, padreId: pasivo, nivel: 2);
    await hoja(codigo: c(CuentaRol.impuestoPorPagar), nombre: '${plantilla.etiquetaImpuesto} por pagar', tipo: TipoCuenta.pasivo, padreId: pasivo, nivel: 2);

    await hoja(codigo: c(CuentaRol.ingresosVentas), nombre: 'Ingresos por ventas', tipo: TipoCuenta.ingreso, padreId: ingresos, nivel: 2);
    await hoja(codigo: c(CuentaRol.costoVentas), nombre: 'Costo de mercancías vendidas', tipo: TipoCuenta.costo, padreId: costos, nivel: 2);
  }
}
