import 'package:fiscogest_rd/core/contabilidad/domain/config/contabilidad_pais_config.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/config/cuenta_rol.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/config/plantilla_contrapartida.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/plan_cuenta.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/enums/tipo_cuenta.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/repositories/i_plan_cuentas_repository.dart';

/// Seed del plan mínimo según plantilla del país (DO / MX / PR / JSON).
/// - Si no hay cuentas: crea grupos + hojas.
/// - Si ya hay plan: solo inserta hojas de roles que falten (por código).
class PlanCuentasRdSeed {
  PlanCuentasRdSeed(this._repo);

  final IPlanCuentasRepository _repo;

  Future<void> asegurarPlanMinimo({String? paisCodigo}) async {
    final pais = (paisCodigo ?? ContabilidadPaisConfig.paisCodigo).toUpperCase();
    // Preferir plantilla ya cargada (JSON); si el país coincide.
    final plantilla = ContabilidadPaisConfig.paisCodigo.toUpperCase() == pais
        ? ContabilidadPaisConfig.plantilla
        : PlantillasContrapartida.porPais(pais);

    final existentes = await _repo.obtenerArbolCompleto();
    if (existentes.isEmpty) {
      await _sembrarCompleto(plantilla);
      return;
    }
    await _asegurarHojasRoles(plantilla, existentes);
  }

  Future<void> _sembrarCompleto(PlantillaContrapartida plantilla) async {
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

    String c(CuentaRol r) => plantilla.codigo(r);
    final etiq = plantilla.etiquetaImpuesto;

    final activo =
        await grupo(codigo: '1', nombre: 'ACTIVO', tipo: TipoCuenta.activo);
    final pasivo =
        await grupo(codigo: '2', nombre: 'PASIVO', tipo: TipoCuenta.pasivo);
    final ingresos =
        await grupo(codigo: '4', nombre: 'INGRESOS', tipo: TipoCuenta.ingreso);
    final costos =
        await grupo(codigo: '5', nombre: 'COSTOS', tipo: TipoCuenta.costo);

    await _hoja(
      codigo: c(CuentaRol.caja),
      nombre: 'Caja general',
      tipo: TipoCuenta.activo,
      padreId: activo,
      nivel: 2,
      ahora: ahora,
    );
    await _hoja(
      codigo: c(CuentaRol.cxc),
      nombre: 'Cuentas por cobrar',
      tipo: TipoCuenta.activo,
      padreId: activo,
      nivel: 2,
      ahora: ahora,
    );
    await _hoja(
      codigo: c(CuentaRol.impuestoCredito),
      nombre: '$etiq crédito fiscal',
      tipo: TipoCuenta.activo,
      padreId: activo,
      nivel: 2,
      ahora: ahora,
    );
    await _hoja(
      codigo: c(CuentaRol.inventario),
      nombre: 'Inventario de mercancías',
      tipo: TipoCuenta.activo,
      padreId: activo,
      nivel: 2,
      ahora: ahora,
    );
    await _hoja(
      codigo: c(CuentaRol.cxp),
      nombre: 'Cuentas por pagar',
      tipo: TipoCuenta.pasivo,
      padreId: pasivo,
      nivel: 2,
      ahora: ahora,
    );
    await _hoja(
      codigo: c(CuentaRol.impuestoPorPagar),
      nombre: '$etiq por pagar',
      tipo: TipoCuenta.pasivo,
      padreId: pasivo,
      nivel: 2,
      ahora: ahora,
    );
    await _hoja(
      codigo: c(CuentaRol.ingresosVentas),
      nombre: 'Ingresos por ventas',
      tipo: TipoCuenta.ingreso,
      padreId: ingresos,
      nivel: 2,
      ahora: ahora,
    );
    await _hoja(
      codigo: c(CuentaRol.costoVentas),
      nombre: 'Costo de mercancías vendidas',
      tipo: TipoCuenta.costo,
      padreId: costos,
      nivel: 2,
      ahora: ahora,
    );
  }

  /// Inserta solo códigos de rol que no existan (cambio DO→MX sin borrar DO).
  Future<void> _asegurarHojasRoles(
    PlantillaContrapartida plantilla,
    List<PlanCuenta> existentes,
  ) async {
    final codigos = {for (final c in existentes) c.codigo};
    final ahora = DateTime.now();
    final etiq = plantilla.etiquetaImpuesto;

    Future<int> padreDe(TipoCuenta tipo) async {
      // Buscar grupo nivel 1 del tipo; si no, primera agrupadora
      for (final c in existentes) {
        if (!c.permiteMovimiento && c.nivel == 1 && c.tipo == tipo) {
          return c.id;
        }
      }
      for (final c in existentes) {
        if (!c.permiteMovimiento && c.tipo == tipo) return c.id;
      }
      // Crear grupo mínimo
      final codigoGrupo = switch (tipo) {
        TipoCuenta.activo => '1',
        TipoCuenta.pasivo => '2',
        TipoCuenta.ingreso => '4',
        TipoCuenta.costo => '5',
        _ => '9',
      };
      if (codigos.contains(codigoGrupo)) {
        final g = existentes.firstWhere((e) => e.codigo == codigoGrupo);
        return g.id;
      }
      final id = await _repo.insertar(PlanCuenta(
        id: 0,
        codigo: codigoGrupo,
        nombre: tipo.name.toUpperCase(),
        tipo: tipo,
        nivel: 1,
        permiteMovimiento: false,
        activo: true,
        creadoEn: ahora,
      ));
      return id;
    }

    final defs = <(CuentaRol, String, TipoCuenta)>[
      (CuentaRol.caja, 'Caja general', TipoCuenta.activo),
      (CuentaRol.cxc, 'Cuentas por cobrar', TipoCuenta.activo),
      (CuentaRol.impuestoCredito, '$etiq crédito fiscal', TipoCuenta.activo),
      (CuentaRol.inventario, 'Inventario de mercancías', TipoCuenta.activo),
      (CuentaRol.cxp, 'Cuentas por pagar', TipoCuenta.pasivo),
      (CuentaRol.impuestoPorPagar, '$etiq por pagar', TipoCuenta.pasivo),
      (CuentaRol.ingresosVentas, 'Ingresos por ventas', TipoCuenta.ingreso),
      (CuentaRol.costoVentas, 'Costo de mercancías vendidas', TipoCuenta.costo),
    ];

    for (final (rol, nombre, tipo) in defs) {
      final codigo = plantilla.codigo(rol);
      if (codigos.contains(codigo)) continue;
      final padreId = await padreDe(tipo);
      await _hoja(
        codigo: codigo,
        nombre: nombre,
        tipo: tipo,
        padreId: padreId,
        nivel: 2,
        ahora: ahora,
      );
      codigos.add(codigo);
    }
  }

  Future<void> _hoja({
    required String codigo,
    required String nombre,
    required TipoCuenta tipo,
    required int padreId,
    required int nivel,
    required DateTime ahora,
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
}
