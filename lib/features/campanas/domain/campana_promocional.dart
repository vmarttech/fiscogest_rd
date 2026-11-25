// [CAMPANAS_FASE1] Modelo de campaña promocional (oferta de plataforma).
class CampanaPromocional {

  const CampanaPromocional({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.tipo,
    required this.valor,
    required this.segmentoObjetivo,
    this.planAplicar,
    this.fechaInicio,
    this.fechaFin,
    this.limiteUsos,
    this.usosActuales = 0,
    this.activa = true,
    this.mostrarRegistro = true,
    this.mostrarPanel = true,
    this.createdAt,
  });

  factory CampanaPromocional.fromJson(Map<String, dynamic> j) {
    DateTime? dt(dynamic v) => v == null ? null : DateTime.tryParse('$v');
    return CampanaPromocional(
      id: '${j['id'] ?? ''}',
      nombre: '${j['nombre'] ?? ''}',
      descripcion: '${j['descripcion'] ?? ''}',
      tipo: '${j['tipo'] ?? 'personalizado'}',
      valor: '${j['valor'] ?? ''}',
      segmentoObjetivo: '${j['segmento_objetivo'] ?? 'todos'}',
      planAplicar: j['plan_aplicar']?.toString(),
      fechaInicio: dt(j['fecha_inicio']),
      fechaFin: dt(j['fecha_fin']),
      limiteUsos: j['limite_usos_total'] is int
          ? j['limite_usos_total'] as int
          : int.tryParse('${j['limite_usos_total'] ?? ''}'),
      usosActuales: j['usos_actuales'] is int
          ? j['usos_actuales'] as int
          : int.tryParse('${j['usos_actuales'] ?? 0}') ?? 0,
      activa: j['activa'] == true,
      mostrarRegistro: j['mostrar_en_registro'] != false,
      mostrarPanel: j['mostrar_en_panel'] != false,
      createdAt: dt(j['created_at']),
    );
  }
  final String id;
  final String nombre;
  final String descripcion;
  final String tipo;
  final String valor;
  final String segmentoObjetivo;
  final String? planAplicar;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final int? limiteUsos;
  final int usosActuales;
  final bool activa;
  final bool mostrarRegistro;
  final bool mostrarPanel;
  final DateTime? createdAt;

  bool get vigente {
    if (!activa) return false;
    final now = DateTime.now().toUtc();
    final ini = fechaInicio?.toUtc();
    final fin = fechaFin?.toUtc();
    if (ini != null && now.isBefore(ini)) return false;
    if (fin != null && now.isAfter(fin)) return false;
    return true;
  }

  int? get diasRestantes {
    final f = fechaFin?.toUtc();
    if (f == null) return null;
    final d = f.difference(DateTime.now().toUtc()).inDays;
    return d < 0 ? 0 : d;
  }

  String get estadoEtiqueta {
    if (!activa) return 'Pausada';
    if (!vigente) {
      final fin = fechaFin?.toUtc();
      final now = DateTime.now().toUtc();
      if (fin != null && now.isAfter(fin)) return 'Vencida';
      return 'Próxima';
    }
    return 'Vigente';
  }

  String get segmentoEtiqueta => switch (segmentoObjetivo) {
        'nuevas_cuentas' => 'Nuevas cuentas (registro)',
        'negocios_activos' => 'Negocios activos',
        'plan_especifico' => 'Plan específico${planAplicar == null || planAplicar!.isEmpty ? '' : ': $planAplicar'}',
        _ => 'Todos los negocios',
      };

  String get tipoEtiqueta => switch (tipo) {
        'descuento' => 'Descuento',
        'meses_gratis' => 'Meses gratis',
        'cuentas_gratis' => 'Cuentas gratis',
        _ => 'Personalizado',
      };
}
