import 'package:fiscogest_rd/features/creditos/domain/entities/referencia_solicitante.dart';

/// Expediente del solicitante (datos personales + referencias).
class SolicitudCreditoExpediente {
  const SolicitudCreditoExpediente({
    this.id,
    required this.ventaId,
    this.nombreCompleto = '',
    this.cedula = '',
    this.fechaNacimiento,
    this.estadoCivil = '',
    this.telefono = '',
    this.celular = '',
    this.email = '',
    this.direccion = '',
    this.sector = '',
    this.ciudad = '',
    this.tiempoResidencia = '',
    this.empresa = '',
    this.cargo = '',
    this.telefonoTrabajo = '',
    this.ingresoMensual = 0,
    this.tiempoLaborando = '',
    this.tipoVivienda = '',
    this.dependientes = 0,
    this.notasAnalista = '',
    this.usuarioId = 1,
    this.referencias = const [],
  });

  final int? id;
  final int ventaId;
  final String nombreCompleto;
  final String cedula;
  final DateTime? fechaNacimiento;
  final String estadoCivil;
  final String telefono;
  final String celular;
  final String email;
  final String direccion;
  final String sector;
  final String ciudad;
  final String tiempoResidencia;
  final String empresa;
  final String cargo;
  final String telefonoTrabajo;
  final double ingresoMensual;
  final String tiempoLaborando;
  final String tipoVivienda;
  final int dependientes;
  final String notasAnalista;
  final int usuarioId;
  final List<ReferenciaSolicitante> referencias;

  SolicitudCreditoExpediente copyWith({
    int? id,
    int? ventaId,
    String? nombreCompleto,
    String? cedula,
    DateTime? fechaNacimiento,
    String? estadoCivil,
    String? telefono,
    String? celular,
    String? email,
    String? direccion,
    String? sector,
    String? ciudad,
    String? tiempoResidencia,
    String? empresa,
    String? cargo,
    String? telefonoTrabajo,
    double? ingresoMensual,
    String? tiempoLaborando,
    String? tipoVivienda,
    int? dependientes,
    String? notasAnalista,
    int? usuarioId,
    List<ReferenciaSolicitante>? referencias,
  }) {
    return SolicitudCreditoExpediente(
      id: id ?? this.id,
      ventaId: ventaId ?? this.ventaId,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      cedula: cedula ?? this.cedula,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      estadoCivil: estadoCivil ?? this.estadoCivil,
      telefono: telefono ?? this.telefono,
      celular: celular ?? this.celular,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion,
      sector: sector ?? this.sector,
      ciudad: ciudad ?? this.ciudad,
      tiempoResidencia: tiempoResidencia ?? this.tiempoResidencia,
      empresa: empresa ?? this.empresa,
      cargo: cargo ?? this.cargo,
      telefonoTrabajo: telefonoTrabajo ?? this.telefonoTrabajo,
      ingresoMensual: ingresoMensual ?? this.ingresoMensual,
      tiempoLaborando: tiempoLaborando ?? this.tiempoLaborando,
      tipoVivienda: tipoVivienda ?? this.tipoVivienda,
      dependientes: dependientes ?? this.dependientes,
      notasAnalista: notasAnalista ?? this.notasAnalista,
      usuarioId: usuarioId ?? this.usuarioId,
      referencias: referencias ?? this.referencias,
    );
  }

  /// Campos mínimos para análisis / aprobación.
  List<String> get camposFaltantes {
    final f = <String>[];
    if (nombreCompleto.trim().isEmpty) f.add('Nombre completo');
    if (cedula.trim().length < 5) f.add('Cédula / RNC');
    if (celular.trim().isEmpty && telefono.trim().isEmpty) {
      f.add('Teléfono o celular');
    }
    if (direccion.trim().isEmpty) f.add('Dirección');
    if (ingresoMensual <= 0) f.add('Ingreso mensual');
    if (empresa.trim().isEmpty) f.add('Empresa / ocupación');
    final refsOk = referencias
        .where((r) => r.nombre.trim().isNotEmpty && r.telefono.trim().isNotEmpty)
        .length;
    if (refsOk < 2) f.add('Al menos 2 referencias (nombre y teléfono)');
    return f;
  }

  bool get estaCompleto => camposFaltantes.isEmpty;
}
