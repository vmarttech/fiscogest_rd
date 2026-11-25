// [ADMIN_FASE2]
import 'package:fiscogest_rd/core/sync/supabase/supabase_rest_client.dart';

String _txt(dynamic v) => v == null ? '' : '$v';
int _ent(dynamic v) =>
    v is int ? v : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
bool _flag(dynamic v) => v == true || v == 'true';
DateTime? _fecha(dynamic v) => v == null ? null : DateTime.tryParse('$v');

/// Fila del listado (RPC admin_listar_negocios).
class AdminNegocioRow {
  const AdminNegocioRow({
    required this.id,
    required this.nombre,
    this.rnc = '',
    this.telefonoContacto = '',
    this.correoContacto = '',
    this.plan = '',
    this.estadoBruto = '',
    this.estado = '',
    this.vitalicia = false,
    this.vigenciaTipo = '',
    this.fechaInicio,
    this.fechaFin,
    this.createdAt,
    this.usuariosTotales = 0,
    this.usuariosActivos = 0,
    this.concesionActiva = '',
    this.diasRestantes,
  });

  factory AdminNegocioRow.fromMap(Map<String, dynamic> m) => AdminNegocioRow(
    id: _txt(m['id']),
    nombre: _txt(m['nombre']),
    rnc: _txt(m['rnc']),
    telefonoContacto: _txt(m['telefono_contacto']),
    correoContacto: _txt(m['correo_contacto']),
    plan: _txt(m['plan']),
    estadoBruto: _txt(m['estado_bruto']),
    estado: _txt(m['estado_derivado']),
    vitalicia: _flag(m['vitalicia']),
    vigenciaTipo: _txt(m['vigencia_tipo']),
    fechaInicio: _fecha(m['fecha_inicio']),
    fechaFin: _fecha(m['fecha_fin']),
    createdAt: _fecha(m['created_at']),
    usuariosTotales: _ent(m['usuarios_totales']),
    usuariosActivos: _ent(m['usuarios_activos']),
    concesionActiva: _txt(m['concesion_activa']),
    diasRestantes: m['dias_restantes'] == null
        ? null
        : _ent(m['dias_restantes']),
  );
  final String id;
  final String nombre;
  final String rnc;
  final String telefonoContacto;
  final String correoContacto;
  final String plan;
  final String estadoBruto;
  final String estado;
  final bool vitalicia;
  final String vigenciaTipo;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final DateTime? createdAt;
  final int usuariosTotales;
  final int usuariosActivos;
  final String concesionActiva;
  final int? diasRestantes;
}

class AdminUsuarioRow {
  const AdminUsuarioRow({
    required this.id,
    required this.username,
    this.nombre = '',
    this.rol = '',
    this.activo = true,
    this.updatedAt,
  });
  factory AdminUsuarioRow.fromMap(Map<String, dynamic> m) => AdminUsuarioRow(
    id: _txt(m['id']),
    username: _txt(m['username']),
    nombre: _txt(m['nombre']),
    rol: _txt(m['rol']),
    activo: _flag(m['activo']),
    updatedAt: _fecha(m['updated_at']),
  );
  final String id;
  final String username;
  final String nombre;
  final String rol;
  final bool activo;
  final DateTime? updatedAt;
}

class AdminConcesionRow {
  const AdminConcesionRow({
    required this.id,
    required this.tipo,
    this.fechaInicio,
    this.fechaFin,
    this.origen = '',
    this.motivo = '',
    this.createdAt,
  });
  factory AdminConcesionRow.fromMap(Map<String, dynamic> m) =>
      AdminConcesionRow(
        id: _txt(m['id']),
        tipo: _txt(m['tipo']),
        fechaInicio: _fecha(m['fecha_inicio']),
        fechaFin: _fecha(m['fecha_fin']),
        origen: _txt(m['origen']),
        motivo: _txt(m['motivo']),
        createdAt: _fecha(m['created_at']),
      );
  final String id;
  final String tipo;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String origen;
  final String motivo;
  final DateTime? createdAt;
}

class AdminBitacoraRow {
  const AdminBitacoraRow({
    required this.accion,
    this.actorId = '',
    this.motivo = '',
    this.valoresAnteriores,
    this.valoresNuevos,
    this.createdAt,
  });
  factory AdminBitacoraRow.fromMap(Map<String, dynamic> m) => AdminBitacoraRow(
    accion: _txt(m['accion']),
    actorId: _txt(m['actor_id']),
    motivo: _txt(m['motivo']),
    valoresAnteriores: m['valores_anteriores'],
    valoresNuevos: m['valores_nuevos'],
    createdAt: _fecha(m['created_at']),
  );
  final String accion;
  final String actorId;
  final String motivo;
  final dynamic valoresAnteriores;
  final dynamic valoresNuevos;
  final DateTime? createdAt;
}

class AdminNegocioDetalle {
  const AdminNegocioDetalle({
    required this.negocio,
    required this.estadoDerivado,
    required this.usuarios,
    required this.concesiones,
    required this.bitacora,
  });

  factory AdminNegocioDetalle.fromJson(Map<String, dynamic> json) {
    final neg = (json['negocio'] as Map?) ?? const {};
    List<T> mapear<T>(dynamic lista, T Function(Map<String, dynamic>) cb) =>
        (lista is List ? lista : const <dynamic>[])
            .map((e) => cb(Map<String, dynamic>.from(e as Map)))
            .toList();
    return AdminNegocioDetalle(
      negocio: Map<String, dynamic>.from(neg),
      estadoDerivado: _txt(json['estado_derivado']),
      usuarios: mapear(json['usuarios'], AdminUsuarioRow.fromMap),
      concesiones: mapear(json['concesiones'], AdminConcesionRow.fromMap),
      bitacora: mapear(json['bitacora'], AdminBitacoraRow.fromMap),
    );
  }
  final Map<String, dynamic> negocio;
  final String estadoDerivado;
  final List<AdminUsuarioRow> usuarios;
  final List<AdminConcesionRow> concesiones;
  final List<AdminBitacoraRow> bitacora;

  String get id => _txt(negocio['id']);
  String get nombre => _txt(negocio['nombre']);
  String get rnc => _txt(negocio['rnc']);
  String get plan => _txt(negocio['plan']);
  String get vigenciaTipo => _txt(negocio['vigencia_tipo']);
  bool get vitalicia => _flag(negocio['vitalicia']);
  String get telefono => _txt(negocio['telefono_contacto']);
  String get correo => _txt(negocio['correo_contacto']);
  DateTime? get fechaInicio => _fecha(negocio['fecha_inicio']);
  DateTime? get fechaFin => _fecha(negocio['fecha_fin']);
}

/// Cliente de las RPC administrativas (autorización en servidor, nunca en app).
class AdminNegociosRemote {
  AdminNegociosRemote([SupabaseRestClient? api])
    : _api = api ?? SupabaseRestClient();
  final SupabaseRestClient _api;

  Future<List<AdminNegocioRow>> listar({
    String busqueda = '',
    String? estado,
    String? plan,
    String orden = 'reciente',
    int limite = 20,
    int offset = 0,
  }) async {
    final res = await _api.rpc('admin_listar_negocios', {
      'p_busqueda': busqueda.trim().isEmpty ? null : busqueda.trim(),
      'p_filtro_estado': (estado == null || estado.isEmpty) ? null : estado,
      'p_filtro_plan': (plan == null || plan.isEmpty) ? null : plan,
      'p_orden': orden,
      'p_limite': limite,
      'p_desplazamiento': offset,
    });
    final lista = res is List ? res : const <dynamic>[];
    return lista
        .map(
          (e) => AdminNegocioRow.fromMap(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<AdminNegocioDetalle> detalle(String negocioId) async {
    final res = await _api.rpc('admin_detalle_negocio', {
      'p_negocio_id': negocioId,
    });
    if (res is! Map) throw Exception('Respuesta de detalle inválida');
    return AdminNegocioDetalle.fromJson(Map<String, dynamic>.from(res));
  }

  Future<void> _accion(String fn, Map<String, dynamic> params) =>
      _api.rpc(fn, params);

  Future<void> activar(String id, {String? motivo}) => _accion(
    'admin_activar_negocio',
    {'p_negocio_id': id, 'p_motivo': motivo},
  );

  Future<void> suspender(String id, String motivo) => _accion(
    'admin_suspender_negocio',
    {'p_negocio_id': id, 'p_motivo': motivo},
  );

  Future<void> renovar(
    String id,
    DateTime fechaFin, {
    String? plan,
    String? vigenciaTipo,
    String? motivo,
  }) => _accion('admin_renovar_negocio', {
    'p_negocio_id': id,
    'p_fecha_fin': fechaFin.toUtc().toIso8601String(),
    'p_plan': plan,
    'p_vigencia_tipo': vigenciaTipo,
    'p_motivo': motivo,
  });

  Future<void> registrarConcesion({
    required String id,
    required String tipo,
    required DateTime inicio,
    required DateTime fin,
    String origen = 'manual',
    String? motivo,
  }) => _accion('admin_registrar_concesion', {
    'p_negocio_id': id,
    'p_tipo': tipo,
    'p_fecha_inicio': inicio.toIso8601String().substring(0, 10),
    'p_fecha_fin': fin.toIso8601String().substring(0, 10),
    'p_origen': origen,
    'p_motivo': motivo,
  });

  Future<void> actualizarContacto(
    String id, {
    String? telefono,
    String? correo,
  }) => _accion('admin_actualizar_contacto', {
    'p_negocio_id': id,
    'p_telefono': telefono,
    'p_correo': correo,
  });
}
