import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';

final bitacoraOperacionesServiceProvider = Provider<BitacoraOperacionesService>(
  (ref) => BitacoraOperacionesService(ref.watch(databaseProvider)),
);

class BitacoraOperacionesService {
  const BitacoraOperacionesService(this._db);

  final AppDatabase _db;

  Future<void> registrar({
    required String accion,
    required String entidad,
    int? entidadId,
    int? usuarioId,
    required String resumen,
    Map<String, Object?> datos = const {},
  }) async {
    final fecha = DateTime.now().toIso8601String();
    final payload = jsonEncode({
      'fecha': fecha,
      'usuarioId': usuarioId,
      'accion': accion,
      'entidad': entidad,
      'entidadId': entidadId,
      'resumen': resumen,
      'datos': datos,
    });
    await _db.transaction(() async {
      await _db.customStatement(
        '''
        INSERT INTO bitacora_operaciones
          (fecha, usuario_id, accion, entidad, entidad_id, resumen, datos)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          fecha,
          usuarioId ?? 0,
          accion,
          entidad,
          entidadId ?? 0,
          resumen,
          jsonEncode(datos),
        ],
      );
      await _db.customStatement(
        '''
        INSERT INTO cola_sincronizacion
          (fecha_creacion, entidad, entidad_id, accion, payload)
        VALUES (?, ?, ?, ?, ?)
        ''',
        [fecha, entidad, entidadId ?? 0, accion, payload],
      );
    });
  }

  Future<List<Map<String, Object?>>> listarRecientes({int limite = 100}) async {
    final filas = await _db
        .customSelect(
          '''
          SELECT id, fecha, usuario_id, accion, entidad, entidad_id, resumen, datos
          FROM bitacora_operaciones
          ORDER BY id DESC
          LIMIT ?
          ''',
          variables: [Variable.withInt(limite.clamp(1, 500).toInt())],
        )
        .get();
    return filas.map((fila) => fila.data).toList(growable: false);
  }

  Future<List<Map<String, Object?>>> listarPendientesSync({
    int limite = 100,
  }) async {
    final filas = await _db
        .customSelect(
          '''
          SELECT id, fecha_creacion, entidad, entidad_id, accion, payload, intentos
          FROM cola_sincronizacion
          WHERE estado = 'pendiente'
          ORDER BY id ASC
          LIMIT ?
          ''',
          variables: [Variable.withInt(limite.clamp(1, 500).toInt())],
        )
        .get();
    return filas.map((fila) => fila.data).toList(growable: false);
  }

  Future<void> marcarSyncCompleto(int eventoId) async {
    await _db.customStatement(
      "UPDATE cola_sincronizacion SET estado = 'sincronizado', ultimo_error = NULL WHERE id = ?",
      [eventoId],
    );
  }

  Future<void> registrarFalloSync(int eventoId, String error) async {
    await _db.customStatement(
      '''
      UPDATE cola_sincronizacion
      SET intentos = intentos + 1, ultimo_error = ?
      WHERE id = ? AND estado = 'pendiente'
      ''',
      [error, eventoId],
    );
  }
}
