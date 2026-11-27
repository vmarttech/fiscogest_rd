import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/nomina/domain/entities/empleado.dart';

class EmpleadoRepository {
  EmpleadoRepository(this._db);
  final AppDatabase _db;

  DateTime _parseDt(dynamic v) {
    if (v is DateTime) return v;
    return DateTime.tryParse(v?.toString() ?? '') ?? DateTime.now();
  }

  Empleado _map(Map<String, dynamic> d) {
    return Empleado(
      id: (d['id'] as num?)?.toInt(),
      nombre: d['nombre']?.toString() ?? '',
      apellido: d['apellido']?.toString() ?? '',
      cedula: d['cedula']?.toString(),
      telefono: d['telefono']?.toString(),
      email: d['email']?.toString(),
      cargo: d['cargo']?.toString(),
      salarioBase: (d['salario_base'] as num?)?.toDouble() ?? 0,
      activo: d['activo'] == true || d['activo'] == 1,
      fechaIngreso:
          d['fecha_ingreso'] == null ? null : _parseDt(d['fecha_ingreso']),
      banco: d['banco']?.toString(),
      tipoCuenta: d['tipo_cuenta']?.toString(),
      numeroCuenta: d['numero_cuenta']?.toString(),
      formaPago: d['forma_pago']?.toString() ?? 'transferencia',
      notas: d['notas']?.toString(),
      creadoEn: _parseDt(d['creado_en']),
      actualizadoEn: d['actualizado_en'] == null
          ? null
          : _parseDt(d['actualizado_en']),
    );
  }

  Future<List<Empleado>> listar({bool? soloActivos, String? busqueda}) async {
    final conditions = <String>[];
    final vars = <Variable>[];
    if (soloActivos == true) {
      conditions.add('activo = 1');
    } else if (soloActivos == false) {
      conditions.add('activo = 0');
    }
    if (busqueda != null && busqueda.trim().isNotEmpty) {
      final q = '%${busqueda.trim()}%';
      conditions.add(
        '(nombre LIKE ? OR apellido LIKE ? OR cedula LIKE ? OR cargo LIKE ? OR banco LIKE ? OR numero_cuenta LIKE ?)',
      );
      vars.addAll([
        Variable.withString(q),
        Variable.withString(q),
        Variable.withString(q),
        Variable.withString(q),
        Variable.withString(q),
        Variable.withString(q),
      ]);
    }
    final where =
        conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
    final rows = await _db
        .customSelect(
          '''
      SELECT id, nombre, apellido, cedula, telefono, email, cargo,
             salario_base, activo, fecha_ingreso,
             banco, tipo_cuenta, numero_cuenta, forma_pago,
             notas, creado_en, actualizado_en
      FROM empleados_table
      $where
      ORDER BY apellido ASC, nombre ASC, id DESC
      ''',
          variables: vars,
          readsFrom: {_db.empleadosTable},
        )
        .get();
    return rows.map((r) => _map(r.data)).toList();
  }

  Future<int> guardar(Empleado e) async {
    final now = DateTime.now();
    if (e.id == null) {
      final row = await _db.into(_db.empleadosTable).insertReturning(
            EmpleadosTableCompanion.insert(
              nombre: e.nombre,
              apellido: e.apellido,
              cedula: Value(e.cedula),
              telefono: Value(e.telefono),
              email: Value(e.email),
              cargo: Value(e.cargo),
              salarioBase: Value(e.salarioBase),
              activo: Value(e.activo),
              fechaIngreso: Value(e.fechaIngreso),
              banco: Value(e.banco),
              tipoCuenta: Value(e.tipoCuenta),
              numeroCuenta: Value(e.numeroCuenta),
              formaPago: Value(e.formaPago),
              notas: Value(e.notas),
              creadoEn: e.creadoEn ?? now,
              actualizadoEn: Value(now),
            ),
          );
      return row.id;
    }
    await (_db.update(_db.empleadosTable)..where((t) => t.id.equals(e.id!)))
        .write(
      EmpleadosTableCompanion(
        nombre: Value(e.nombre),
        apellido: Value(e.apellido),
        cedula: Value(e.cedula),
        telefono: Value(e.telefono),
        email: Value(e.email),
        cargo: Value(e.cargo),
        salarioBase: Value(e.salarioBase),
        activo: Value(e.activo),
        fechaIngreso: Value(e.fechaIngreso),
        banco: Value(e.banco),
        tipoCuenta: Value(e.tipoCuenta),
        numeroCuenta: Value(e.numeroCuenta),
        formaPago: Value(e.formaPago),
        notas: Value(e.notas),
        actualizadoEn: Value(now),
      ),
    );
    return e.id!;
  }

  Future<void> eliminar(int id) async {
    await (_db.delete(_db.empleadosTable)..where((t) => t.id.equals(id))).go();
  }
}
