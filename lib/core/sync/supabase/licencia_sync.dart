import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/sync/supabase/negocio_local.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_rest_client.dart';
import 'package:fiscogest_rd/features/licencias/domain/planes_precios.dart';

/// Licencia del negocio: public.negocios ↔ SQLite local.
class LicenciaSync {
  LicenciaSync(this._db);
  final AppDatabase _db;
  final _client = SupabaseRestClient();

  Future<bool> pullDesdeNegocio() async {
    if (!SupabaseConfig.isConfigured) return false;
    final negocioId = await NegocioLocal.getId();
    if (negocioId == null || negocioId.isEmpty) {
      debugPrint('LicenciaSync.pull: sin negocio_id');
      return false;
    }

    // PostgREST: "select" es query param de columnas, NO filtro eq.
    final rows = await _client.select(
      table: 'negocios',
      filters: {
        'id': 'eq.$negocioId',
        'select':
            'id,plan,estado,max_dispositivos,max_cajas,ecf_habilitado,'
            'vitalicia,vigencia_tipo,fecha_inicio,fecha_fin,updated_at',
        'limit': '1',
      },
    );
    if (rows.isEmpty) {
      debugPrint('LicenciaSync.pull: negocio no encontrado ($negocioId)');
      return false;
    }
    await _aplicarRemoto(rows.first);
    final r = rows.first;
    debugPrint(
      'LicenciaSync.pull: plan=${r['plan']} estado=${r['estado']} '
      'vitalicia=${r['vitalicia']} fin=${r['fecha_fin']}',
    );
    return true;
  }

  /// Sube licencia local → negocios.
  /// Nunca sobrescribe un plan de pago/vitalicia en nube con demo/gratis local.
  Future<void> pushAlNegocio() async {
    if (!SupabaseConfig.isConfigured) return;
    final negocioId = await NegocioLocal.getId();
    if (negocioId == null || negocioId.isEmpty) {
      debugPrint('LicenciaSync.push: sin negocio_id');
      return;
    }

    final locales = await _db.select(_db.licenciasTable).get();
    if (locales.isEmpty) {
      debugPrint('LicenciaSync.push: sin licencia local');
      return;
    }
    locales.sort((a, b) => b.id.compareTo(a.id));
    final dev =
        locales.where((r) => r.plan == 'desarrollador' || r.vitalicia);
    final lic = dev.isNotEmpty ? dev.first : locales.first;
    final planLocal = lic.plan.toLowerCase();

    // Protección: no pisar la nube con demo si es reinstalación fresca
    if (planLocal == 'demo' || planLocal == 'gratis') {
      try {
        final remote = await _client.select(
          table: 'negocios',
          filters: {
            'id': 'eq.$negocioId',
            'select': 'id,plan,vitalicia,estado',
            'limit': '1',
          },
        );
        if (remote.isNotEmpty) {
          final rp = (remote.first['plan'] as String?)?.toLowerCase() ?? '';
          final rv = remote.first['vitalicia'] == true;
          if (rv ||
              (rp.isNotEmpty && rp != 'demo' && rp != 'gratis')) {
            debugPrint(
              'LicenciaSync.push: omitido (local=$planLocal, nube=$rp vitalicia=$rv)',
            );
            return;
          }
        }
      } catch (e) {
        debugPrint('LicenciaSync.push: check remoto $e');
      }
    }

    final body = <String, dynamic>{
      'plan': lic.plan,
      'estado': lic.estado,
      'max_dispositivos': lic.maxDispositivos,
      'max_cajas': lic.maxCajas,
      'ecf_habilitado': lic.ecfHabilitado,
      'vitalicia': lic.vitalicia,
      'vigencia_tipo': lic.vigenciaTipo,
      'fecha_inicio': lic.fechaInicio,
      'fecha_fin': lic.fechaFin,
    };

    await _client.patch(
      table: 'negocios',
      filters: {'id': 'eq.$negocioId'},
      body: body,
    );
    debugPrint('LicenciaSync.push: OK plan=${lic.plan}');
  }

  Future<void> _aplicarRemoto(Map<String, dynamic> r) async {
    final plan = (r['plan'] as String?)?.trim().toLowerCase() ?? 'gratis';
    final estado = (r['estado'] as String?)?.trim() ?? 'activa';
    final vitalicia = r['vitalicia'] == true;
    final maxDisp = (r['max_dispositivos'] as num?)?.toInt() ??
        maxInstalacionesPermitidas(plan);
    final maxCajas =
        (r['max_cajas'] as num?)?.toInt() ?? (kMaxCajasPorPlan[plan] ?? 1);
    final ecf = r['ecf_habilitado'] == true || planIncluyeEcf(plan);

    String fechaInicio;
    final fi = r['fecha_inicio'];
    if (fi != null && '$fi'.isNotEmpty) {
      fechaInicio = DateTime.tryParse('$fi')?.toIso8601String() ??
          DateTime.now().toIso8601String();
    } else {
      fechaInicio = DateTime.now().toIso8601String();
    }

    String? fechaFin;
    final ff = r['fecha_fin'];
    if (ff != null && '$ff'.isNotEmpty) {
      fechaFin = DateTime.tryParse('$ff')?.toIso8601String();
    }

    final vigencia = (r['vigencia_tipo'] as String?)?.trim().isNotEmpty == true
        ? (r['vigencia_tipo'] as String).trim()
        : (vitalicia ? 'vitalicia' : 'mensual');

    final actualizado = DateTime.now().toIso8601String();

    final locales = await _db.select(_db.licenciasTable).get();
    locales.sort((a, b) => b.id.compareTo(a.id));
    final prefer =
        locales.where((x) => x.plan == 'desarrollador' || x.vitalicia);
    final row = prefer.isNotEmpty
        ? prefer.first
        : (locales.isNotEmpty ? locales.first : null);

    if (row == null) {
      await _db.into(_db.licenciasTable).insert(
            LicenciasTableCompanion.insert(
              plan: plan,
              vigenciaTipo: vigencia,
              fechaInicio: fechaInicio,
              fechaFin: Value(fechaFin),
              maxDispositivos: Value(maxDisp),
              maxCajas: Value(maxCajas),
              ecfHabilitado: Value(ecf),
              vitalicia: Value(vitalicia),
              estado: estado,
              actualizadoEn: actualizado,
            ),
          );
    } else {
      await (_db.update(_db.licenciasTable)..where((t) => t.id.equals(row.id)))
          .write(
        LicenciasTableCompanion(
          plan: Value(plan),
          vigenciaTipo: Value(vigencia),
          fechaInicio: Value(fechaInicio),
          fechaFin: Value(fechaFin),
          maxDispositivos: Value(maxDisp),
          maxCajas: Value(maxCajas),
          ecfHabilitado: Value(ecf),
          vitalicia: Value(vitalicia),
          estado: Value(estado),
          actualizadoEn: Value(actualizado),
        ),
      );
    }

    if (plan != 'demo') {
      final demos = await (_db.select(_db.licenciasTable)
            ..where((t) => t.plan.equals('demo')))
          .get();
      for (final d in demos) {
        if (row != null && d.id == row.id) continue;
        await (_db.update(_db.licenciasTable)..where((t) => t.id.equals(d.id)))
            .write(
          LicenciasTableCompanion(
            estado: const Value('reemplazada'),
            actualizadoEn: Value(actualizado),
          ),
        );
      }
    }
  }
}
