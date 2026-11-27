import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/plan_cuenta.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/repositories/i_plan_cuentas_repository.dart';

/// Implementacion local (Drift) de [IPlanCuentasRepository].
/// Estilo tomado de GastosRepository: AppDatabase inyectado por constructor,
/// sin DAO aparte. Se usa el DSL de drift (no SQL crudo) porque la columna
/// `tipo` lleva TypeConverter y las filas llegan con [TipoCuenta] tipado.
class PlanCuentasRepositoryImpl implements IPlanCuentasRepository {
  PlanCuentasRepositoryImpl(this._db);

  final AppDatabase _db;

  PlanCuenta _aEntidad(PlanCuentasTableData r) => PlanCuenta(
        id: r.id,
        codigo: r.codigo,
        nombre: r.nombre,
        tipo: r.tipo,
        padreId: r.padreId,
        nivel: r.nivel,
        permiteMovimiento: r.permiteMovimiento,
        activo: r.activo,
        descripcion: r.descripcion,
        creadoEn: r.creadoEn,
        actualizadoEn: r.actualizadoEn,
      );

  @override
  Future<List<PlanCuenta>> obtenerArbolCompleto() async {
    final filas = await (_db.select(_db.planCuentasTable)
          ..orderBy([(t) => OrderingTerm.asc(t.codigo)]))
        .get();
    return filas.map(_aEntidad).toList();
  }

  @override
  Future<PlanCuenta?> obtenerPorId(int cuentaId) async {
    if (cuentaId <= 0) return null;
    final fila = await (_db.select(_db.planCuentasTable)
          ..where((t) => t.id.equals(cuentaId)))
        .getSingleOrNull();
    return fila == null ? null : _aEntidad(fila);
  }

  @override
  Future<PlanCuenta?> obtenerPorCodigo(String codigo) async {
    final normalizado = codigo.trim();
    if (normalizado.isEmpty) return null;
    final fila = await (_db.select(_db.planCuentasTable)
          ..where((t) => t.codigo.equals(normalizado)))
        .getSingleOrNull();
    return fila == null ? null : _aEntidad(fila);
  }

  @override
  Future<List<PlanCuenta>> obtenerHijas(int padreId) async {
    if (padreId <= 0) return [];
    final filas = await (_db.select(_db.planCuentasTable)
          ..where((t) => t.padreId.equals(padreId))
          ..orderBy([(t) => OrderingTerm.asc(t.codigo)]))
        .get();
    return filas.map(_aEntidad).toList();
  }

  @override
  Future<List<PlanCuenta>> obtenerCuentasConMovimiento() async {
    // IDs de cuenta distintos directamente en SQLite; no se cargan todas
    // las lineas a memoria y se evita el limite de parametros de SQLite.
    final consulta = _db.selectOnly(_db.lineasAsientoTable, distinct: true)
      ..addColumns([_db.lineasAsientoTable.cuentaId]);
    final filasLinea = await consulta.get();
    final ids = filasLinea
        .map((r) => r.read(_db.lineasAsientoTable.cuentaId))
        .whereType<int>()
        .toSet()
        .toList();
    if (ids.isEmpty) return [];
    final filas = await (_db.select(_db.planCuentasTable)
          ..where((t) => t.id.isIn(ids)))
        .get();
    filas.sort((a, b) => a.codigo.compareTo(b.codigo));
    return filas.map(_aEntidad).toList();
  }

  @override
  Future<int> insertar(PlanCuenta cuenta) async {
    if (!cuenta.esValida || !cuenta.esConsistente) return -1;

    // Rechazo preventivo de codigo duplicado: la tabla ya impone UNIQUE,
    // pero asi evitamos una SqliteException cruda y devolvemos un -1 limpio.
    final codigo = cuenta.codigo.trim();
    final existente = await obtenerPorCodigo(codigo);
    if (existente != null) return -1;

    try {
      final fila = await _db
          .into(_db.planCuentasTable)
          .insertReturning(PlanCuentasTableCompanion.insert(
            codigo: codigo,
            nombre: cuenta.nombre.trim(),
            tipo: cuenta.tipo,
            nivel: cuenta.nivel,
            padreId: Value(cuenta.padreId),
            permiteMovimiento: Value(cuenta.permiteMovimiento),
            activo: Value(cuenta.activo),
            descripcion: Value(cuenta.descripcion),
            creadoEn: Value(cuenta.creadoEn),
            actualizadoEn: Value(cuenta.actualizadoEn),
          ));
      return fila.id;
    } catch (_) {
      // Conflicto de unicidad o error de SQLite: no romper al caller.
      return -1;
    }
  }

  @override
  Future<bool> actualizar(PlanCuenta cuenta) async {
    if (cuenta.id <= 0 || !cuenta.esValida || !cuenta.esConsistente) {
      return false;
    }

    int nivel = cuenta.nivel;
    if (cuenta.padreId != null) {
      // Ciclo directo: una cuenta no puede tener de padre a si misma.
      if (cuenta.padreId == cuenta.id) return false;
      final padre = await obtenerPorId(cuenta.padreId!);
      if (padre == null) return false;
      // Ciclo indirecto: el padre no puede ser un descendiente de la cuenta.
      if (await _esDescendiente(padre.id, cuenta.id)) return false;
      // El nivel se deriva del padre; no se confia en el caller.
      nivel = padre.nivel + 1;
    } else {
      nivel = 1; // Raiz
    }

    try {
      final afectadas = await (_db.update(_db.planCuentasTable)
            ..where((t) => t.id.equals(cuenta.id)))
          .write(PlanCuentasTableCompanion(
        codigo: Value(cuenta.codigo.trim()),
        nombre: Value(cuenta.nombre.trim()),
        tipo: Value(cuenta.tipo),
        padreId: Value(cuenta.padreId),
        nivel: Value(nivel),
        permiteMovimiento: Value(cuenta.permiteMovimiento),
        activo: Value(cuenta.activo),
        descripcion: Value(cuenta.descripcion),
        actualizadoEn: Value(DateTime.now()),
      ));
      return afectadas > 0;
    } catch (_) {
      return false;
    }
  }

  // Devuelve true si [posibleHijo] esta bajo [ancestroId] en la jerarquia.
  Future<bool> _esDescendiente(int posibleHijo, int ancestroId) async {
    final hijas = await obtenerHijas(ancestroId);
    for (final hija in hijas) {
      if (hija.id == posibleHijo) return true;
      if (await _esDescendiente(posibleHijo, hija.id)) return true;
    }
    return false;
  }

  @override
  Future<bool> desactivar(int cuentaId) async {
    if (cuentaId <= 0) return false;

    // No se desactiva una cuenta con hijas activas (la jerarquia quedaria rota).
    final hijasActivas = await (_db.select(_db.planCuentasTable)
          ..where((t) => t.padreId.equals(cuentaId) & t.activo.equals(true)))
        .get();
    if (hijasActivas.isNotEmpty) return false;

    // No se desactiva una cuenta con movimientos registrados: el libro y los
    // saldos deben poder reconstruirse con esa cuenta.
    if (await _tieneMovimientos(cuentaId)) return false;

    try {
      final afectadas = await (_db.update(_db.planCuentasTable)
            ..where((t) => t.id.equals(cuentaId)))
          .write(PlanCuentasTableCompanion(
        activo: const Value(false),
        actualizadoEn: Value(DateTime.now()),
      ));
      return afectadas > 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _tieneMovimientos(int cuentaId) async {
    final consulta = _db.selectOnly(_db.lineasAsientoTable)
      ..addColumns([_db.lineasAsientoTable.id])
      ..where(_db.lineasAsientoTable.cuentaId.equals(cuentaId))
      ..limit(1);
    return (await consulta.get()).isNotEmpty;
  }

  @override
  Future<void> inicializarPlan(List<PlanCuenta> planCuentas) async {
    if (planCuentas.isEmpty) return;
    final existentes = await _db.select(_db.planCuentasTable).get();
    if (existentes.isNotEmpty) return; // Idempotente: no re-sembrar.
    await _db.batch((b) {
      for (final c in planCuentas) {
        b.insert(
          _db.planCuentasTable,
          PlanCuentasTableCompanion.insert(
            codigo: c.codigo.trim(),
            nombre: c.nombre.trim(),
            tipo: c.tipo,
            nivel: c.nivel,
            padreId: Value(c.padreId),
            permiteMovimiento: Value(c.permiteMovimiento),
            activo: Value(c.activo),
            descripcion: Value(c.descripcion),
            creadoEn: Value(c.creadoEn),
          ),
        );
      }
    });
  }
}
