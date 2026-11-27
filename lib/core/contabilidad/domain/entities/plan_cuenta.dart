import 'package:fiscogest_rd/core/contabilidad/domain/enums/tipo_cuenta.dart';

/// Entidad de dominio: Cuenta del plan contable (jerarquia de mayor a subcuenta).
class PlanCuenta {
  const PlanCuenta({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.tipo,
    this.padreId,
    required this.nivel,
    this.permiteMovimiento = false,
    this.activo = true,
    this.descripcion,
    required this.creadoEn,
    this.actualizadoEn,
  });

  final int id;
  final String codigo;
  final String nombre;
  final TipoCuenta tipo;
  final int? padreId;
  final int nivel;

  // Las cuentas de movimiento (hojas) reciben asientos; las de agrupacion no.
  final bool permiteMovimiento;
  final bool activo;
  final String? descripcion;
  final DateTime creadoEn;
  final DateTime? actualizadoEn;

  bool get esRaiz => padreId == null;

  bool get esValidaParaMovimiento => activo && permiteMovimiento;

  // Validacion minima de dominio: codigo y nombre presentes y nivel valido.
  bool get esValida =>
      codigo.trim().isNotEmpty &&
      nombre.trim().isNotEmpty &&
      nivel >= 1 &&
      (padreId == null || padreId! > 0);

  bool get esAgrupadora => !permiteMovimiento;

  bool get esHoja => permiteMovimiento;

  // Consistencia estructural: una hoja (cuenta de movimiento) debe tener
  // padre; una raiz debe estar en el nivel 1; las agrupadoras van bajo la raiz.
  bool get esConsistente {
    if (esRaiz) return nivel == 1;
    if (permiteMovimiento) return padreId != null && padreId! > 0;
    return nivel >= 2;
  }

  PlanCuenta conActivo(bool valor) => copyWith(activo: valor);

  PlanCuenta copyWith({
    int? id,
    String? codigo,
    String? nombre,
    TipoCuenta? tipo,
    int? padreId,
    int? nivel,
    bool? permiteMovimiento,
    bool? activo,
    String? descripcion,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
  }) {
    return PlanCuenta(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      padreId: padreId ?? this.padreId,
      nivel: nivel ?? this.nivel,
      permiteMovimiento: permiteMovimiento ?? this.permiteMovimiento,
      activo: activo ?? this.activo,
      descripcion: descripcion ?? this.descripcion,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }
}
