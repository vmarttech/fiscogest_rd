/// Empleado de nomina.
class Empleado {
  Empleado({
    this.id,
    required this.nombre,
    required this.apellido,
    this.cedula,
    this.telefono,
    this.email,
    this.cargo,
    this.salarioBase = 0,
    this.activo = true,
    this.fechaIngreso,
    this.banco,
    this.tipoCuenta,
    this.numeroCuenta,
    this.formaPago = 'transferencia',
    this.notas,
    this.creadoEn,
    this.actualizadoEn,
  });

  final int? id;
  final String nombre;
  final String apellido;
  final String? cedula;
  final String? telefono;
  final String? email;
  final String? cargo;
  final double salarioBase;
  final bool activo;
  final DateTime? fechaIngreso;
  final String? banco;
  final String? tipoCuenta;
  final String? numeroCuenta;
  final String formaPago;
  final String? notas;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  String get nombreCompleto => ('$nombre $apellido').trim();

  bool get tieneDatosBancarios =>
      (banco != null && banco!.trim().isNotEmpty) ||
      (numeroCuenta != null && numeroCuenta!.trim().isNotEmpty);

  Empleado copyWith({
    int? id,
    String? nombre,
    String? apellido,
    String? cedula,
    String? telefono,
    String? email,
    String? cargo,
    double? salarioBase,
    bool? activo,
    DateTime? fechaIngreso,
    String? banco,
    String? tipoCuenta,
    String? numeroCuenta,
    String? formaPago,
    String? notas,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
  }) {
    return Empleado(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      cedula: cedula ?? this.cedula,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      cargo: cargo ?? this.cargo,
      salarioBase: salarioBase ?? this.salarioBase,
      activo: activo ?? this.activo,
      fechaIngreso: fechaIngreso ?? this.fechaIngreso,
      banco: banco ?? this.banco,
      tipoCuenta: tipoCuenta ?? this.tipoCuenta,
      numeroCuenta: numeroCuenta ?? this.numeroCuenta,
      formaPago: formaPago ?? this.formaPago,
      notas: notas ?? this.notas,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }
}
