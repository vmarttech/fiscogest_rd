class LicenciaInfo {
  const LicenciaInfo({
    required this.id,
    required this.plan,
    required this.vigenciaTipo,
    required this.fechaInicio,
    this.fechaFin,
    required this.maxDispositivos,
    required this.maxCajas,
    required this.ecfHabilitado,
    required this.vitalicia,
    required this.estado,
    this.fingerprint,
    this.codigoActivacion,
  });

  final int id;
  final String plan;
  final String vigenciaTipo;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final int maxDispositivos;
  final int maxCajas;
  final bool ecfHabilitado;
  final bool vitalicia;
  final String estado;
  final String? fingerprint;
  final String? codigoActivacion;

  bool get esDesarrollador => plan == 'desarrollador' || vitalicia;

  bool get puedeEscribir {
    if (esDesarrollador) return true;
    return estado == 'activa' || estado == 'gracia';
  }

  int? get diasRestantes {
    if (esDesarrollador || fechaFin == null) return null;
    return fechaFin!.difference(DateTime.now()).inDays;
  }
}
