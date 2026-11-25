// [AVISOS_FASE1] Aviso remoto (Supabase RPC). No depende de la campana local.
class AvisoRemoto {

  const AvisoRemoto({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    this.negocioId,
    this.usuarioId,
    this.prioridad = 'normal',
    this.fechaEnvio,
    this.fechaLeido,
  });

  factory AvisoRemoto.fromJson(Map<String, dynamic> j) {
    return AvisoRemoto(
      id: '${j['id'] ?? ''}',
      tipo: '${j['tipo'] ?? 'informacion'}',
      titulo: '${j['titulo'] ?? ''}',
      mensaje: '${j['mensaje'] ?? ''}',
      negocioId: j['negocio_id']?.toString(),
      usuarioId: j['usuario_id']?.toString(),
      prioridad: '${j['prioridad'] ?? 'normal'}',
      fechaEnvio: _dt(j['fecha_envio']),
      fechaLeido: _dt(j['fecha_leido']),
    );
  }
  final String id;
  final String tipo;
  final String titulo;
  final String mensaje;
  final String? negocioId;
  final String? usuarioId;
  final String prioridad;
  final DateTime? fechaEnvio;
  final DateTime? fechaLeido;

  bool get leido => fechaLeido != null;

  static DateTime? _dt(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  String get tipoEtiqueta => switch (tipo) {
        'vencimiento' => 'Vencimiento',
        'oferta' => 'Oferta / promocion',
        'suspension' => 'Suspension',
        'renovacion' => 'Renovacion',
        'sistema' => 'Sistema',
        _ => 'Informacion',
      };

  String get prioridadEtiqueta => switch (prioridad) {
        'baja' => 'Baja',
        'alta' => 'Alta',
        'urgente' => 'Urgente',
        _ => 'Normal',
      };
}
