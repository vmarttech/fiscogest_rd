import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';
import 'package:fiscogest_rd/core/sync/supabase/sync_engine.dart';

/// Reintenta subida a Supabase cada [intervalo].
class SyncScheduler {
  SyncScheduler(this._db, {this.intervalo = const Duration(minutes: 5)});

  final AppDatabase _db;
  final Duration intervalo;
  Timer? _timer;
  bool _corriendo = false;

  void start() {
    if (!SupabaseConfig.isConfigured) {
      debugPrint('SyncScheduler: omitido (sin Supabase)');
      return;
    }
    stop();
    // Primera pasada un poco después del arranque (main ya hizo push)
    _timer = Timer.periodic(intervalo, (_) => tick());
    debugPrint('SyncScheduler: cada ${intervalo.inMinutes} min');
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> tick() async {
    if (_corriendo) return;
    if (!SupabaseConfig.isConfigured) return;
    _corriendo = true;
    try {
      await SyncEngine(_db).pushAll();
      debugPrint('SyncScheduler: tick OK');
    } catch (e, st) {
      debugPrint('SyncScheduler: $e');
      debugPrint('$st');
    } finally {
      _corriendo = false;
    }
  }
}
