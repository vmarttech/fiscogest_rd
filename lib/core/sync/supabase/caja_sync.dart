import 'package:flutter/foundation.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/sync/supabase/negocio_local.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_rest_client.dart';

class CajaSync {
  CajaSync(this._db);
  final AppDatabase _db;

  Future<void> pushTodos() async {
    if (!SupabaseConfig.isConfigured) return;
    final negocioId = await NegocioLocal.getId();
    if (negocioId == null || negocioId.isEmpty) {
      debugPrint('CajaSync: sin negocio_id');
      return;
    }

    final sesiones = await _db.select(_db.cajaSesionesTable).get();
    if (sesiones.isNotEmpty) {
      final payload = sesiones
          .map((s) => <String, dynamic>{
                'negocio_id': negocioId,
                'id_local': s.id,
                'fecha_apertura': s.fechaApertura.toUtc().toIso8601String(),
                'fondo_inicial': s.fondoInicial,
                'usuario_id_local': s.usuarioId,
                'estado': s.estado,
                'fecha_cierre': s.fechaCierre?.toUtc().toIso8601String(),
                'saldo_teorico': s.saldoTeorico,
                'monto_contado': s.montoContado,
                'diferencia': s.diferencia,
                'observacion': s.observacion,
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              })
          .toList();
      await SupabaseRestClient().upsert(
        table: 'caja_sesiones',
        rows: payload,
        onConflict: 'negocio_id,id_local',
      );
      debugPrint('CajaSync: sesiones → ${payload.length}');
    }

    final movs = await _db.select(_db.cajaMovimientosTable).get();
    if (movs.isEmpty) {
      debugPrint('CajaSync: no hay movimientos');
      return;
    }
    final mPayload = movs
        .map((m) => <String, dynamic>{
              'negocio_id': negocioId,
              'id_local': m.id,
              'tipo': m.tipo.name,
              'referencia_tipo': m.referenciaTipo.name,
              'referencia_id': m.referenciaId,
              'monto': m.monto,
              'forma_pago': m.formaPago.name,
              'saldo_anterior': m.saldoAnterior,
              'saldo_nuevo': m.saldoNuevo,
              'fecha': m.fecha.toUtc().toIso8601String(),
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
        .toList();
    await SupabaseRestClient().upsert(
      table: 'caja_movimientos',
      rows: mPayload,
      onConflict: 'negocio_id,id_local',
    );
    debugPrint('CajaSync: movimientos → ${mPayload.length}');
  }
}
