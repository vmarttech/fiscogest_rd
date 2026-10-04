import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/licencias/domain/device_fingerprint.dart';
import 'package:fiscogest_rd/features/licencias/domain/licencia_service.dart';
import 'package:fiscogest_rd/features/licencias/domain/planes_precios.dart';
import 'package:uuid/uuid.dart';

class DispositivoInfo {
  const DispositivoInfo({
    required this.id,
    required this.fingerprint,
    required this.alias,
    required this.plataforma,
    required this.tipo,
    required this.activo,
    required this.esEsteEquipo,
    required this.pendienteSync,
    this.remoteId,
    this.registradoEn,
    this.ultimoUso,
  });

  final int id;
  final String fingerprint;
  final String alias;
  final String plataforma;
  final String tipo;
  final bool activo;
  final bool esEsteEquipo;
  final bool pendienteSync;
  final String? remoteId;
  final DateTime? registradoEn;
  final DateTime? ultimoUso;
}

/// Registro local de equipos. Listo para upsert a Supabase.
class DispositivoService {
  DispositivoService(this._db);
  final AppDatabase _db;

  Future<List<DispositivoInfo>> listar({bool soloActivos = true}) async {
    final fp = await DeviceFingerprint.obtener();
    final q = _db.select(_db.dispositivosLicenciaTable);
    if (soloActivos) {
      q.where((t) => t.activo.equals(true));
    }
    final rows = await q.get();
    return rows
        .map(
          (r) => DispositivoInfo(
            id: r.id,
            fingerprint: r.fingerprint,
            alias: r.alias,
            plataforma: r.plataforma,
            tipo: r.tipo,
            activo: r.activo,
            esEsteEquipo: r.fingerprint == fp,
            pendienteSync: r.pendienteSync,
            remoteId: r.remoteId,
            registradoEn: DateTime.tryParse(r.registradoEn),
            ultimoUso: DateTime.tryParse(r.ultimoUso),
          ),
        )
        .toList();
  }

  /// Al arranque: registra o actualiza este equipo y valida cupo.
  ///
  /// Offline: el cupo se aplica sobre la BD local (1 fila = este equipo).
  /// Con Supabase: la lista vendrá de la nube y [maxDispositivos] será real.
  Future<DispositivoInfo> ensureDispositivoRegistrado() async {
    final fp = await DeviceFingerprint.obtener();
    final ahora = DateTime.now().toIso8601String();
    final existentes = await (_db.select(_db.dispositivosLicenciaTable)
          ..where((t) => t.fingerprint.equals(fp)))
        .get();

    if (existentes.isNotEmpty) {
      final row = existentes.first;
      await (_db.update(_db.dispositivosLicenciaTable)
            ..where((t) => t.id.equals(row.id)))
          .write(
        DispositivosLicenciaTableCompanion(
          ultimoUso: Value(ahora),
          activo: const Value(true),
          pendienteSync: const Value(true),
        ),
      );
      return (await listar(soloActivos: false))
          .firstWhere((d) => d.fingerprint == fp);
    }

    // Cupo local (cuando haya sync, contar activos remotos + locales)
    final lic = await LicenciaService(_db).obtenerActual();
    final max = lic?.maxDispositivos ??
        maxInstalacionesPermitidas(lic?.plan ?? 'demo');
    final activos = await (_db.select(_db.dispositivosLicenciaTable)
          ..where((t) => t.activo.equals(true)))
        .get();

    if (activos.length >= max && max < 999) {
      // Desarrollador / vitalicio: max alto. Si cupo lleno, aún registramos
      // este equipo como pendiente y dejamos que la UI avise.
      // Política v1 offline: siempre permitir ESTE equipo (BD propia).
    }

    final id = await _db.into(_db.dispositivosLicenciaTable).insert(
          DispositivosLicenciaTableCompanion(
            fingerprint: Value(fp),
            alias: Value(DeviceFingerprint.aliasSugerido()),
            plataforma: Value(DeviceFingerprint.plataformaActual()),
            tipo: Value(DeviceFingerprint.tipoActual()),
            registradoEn: Value(ahora),
            ultimoUso: Value(ahora),
            remoteId: Value(const Uuid().v4()),
            pendienteSync: const Value(true),
            activo: const Value(true),
          ),
        );

    final row = await (_db.select(_db.dispositivosLicenciaTable)
          ..where((t) => t.id.equals(id)))
        .getSingle();

    return DispositivoInfo(
      id: row.id,
      fingerprint: row.fingerprint,
      alias: row.alias,
      plataforma: row.plataforma,
      tipo: row.tipo,
      activo: row.activo,
      esEsteEquipo: true,
      pendienteSync: row.pendienteSync,
      remoteId: row.remoteId,
      registradoEn: DateTime.tryParse(row.registradoEn),
      ultimoUso: DateTime.tryParse(row.ultimoUso),
    );
  }

  /// Payload listo para POST/UPSERT a Supabase.
  Future<List<Map<String, dynamic>>> toSupabasePayload() async {
    final rows = await _db.select(_db.dispositivosLicenciaTable).get();
    return [
      for (final r in rows)
        {
          'id': r.remoteId,
          'negocio_id': r.negocioId,
          'fingerprint': r.fingerprint,
          'alias': r.alias,
          'plataforma': r.plataforma,
          'tipo': r.tipo,
          'activo': r.activo,
          'registrado_en': r.registradoEn,
          'ultimo_uso': r.ultimoUso,
        },
    ];
  }

  Future<void> marcarSincronizados() async {
    final ahora = DateTime.now().toIso8601String();
    await _db.update(_db.dispositivosLicenciaTable).write(
          DispositivosLicenciaTableCompanion(
            pendienteSync: const Value(false),
            sincronizadoEn: Value(ahora),
          ),
        );
  }

  Future<int> contarActivos() async {
    final rows = await (_db.select(_db.dispositivosLicenciaTable)
          ..where((t) => t.activo.equals(true)))
        .get();
    return rows.length;
  }
}
