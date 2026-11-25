import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'package:fiscogest_rd/core/sync/supabase/roles_acceso_sync.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/providers/core_providers.dart';
import 'package:fiscogest_rd/core/dependency_injection/repository_injection.dart';
import 'package:fiscogest_rd/features/licencias/domain/licencia_service.dart';
import 'package:fiscogest_rd/features/licencias/domain/dispositivo_service.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';
import 'package:fiscogest_rd/core/sync/supabase/renovar_token.dart';
import 'package:fiscogest_rd/core/sync/supabase/sync_scheduler.dart';

/// Inicializa los servicios compartidos por FiscoGest RD.
///
/// Cada aplicación puede aportar sus propios providers adicionales
/// sin cargar dependencias exclusivas de la otra aplicación.
Future<ProviderContainer> initializeAppCore({
  List<Override> Function(AppDatabase db)? additionalOverrides,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  await RolesAccesoSync.cargarDesdePrefsOFallback();

  if (Platform.isAndroid) {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
  }

  await initializeDateFormatting('es_DO', null);

  final db = AppDatabase();
  await RepositoryInjection.initialize(db);

  // Recupera una licencia concedida y prepara la identidad del dispositivo.
  try {
    final licenciaSvc = LicenciaService(db);
    await licenciaSvc.ensureLicenciaInicial();
    await DispositivoService(db).ensureDispositivoRegistrado();

    debugPrint(
      'Supabase configurado: ${SupabaseConfig.isConfigured} '
      'urlLen=${SupabaseConfig.url.length} '
      'keyLen=${SupabaseConfig.anonKey.length}',
    );

    if (SupabaseConfig.isConfigured) {
      unawaited(() async {
        try {
          final ok = await SupabaseConfig.hayRed();
          debugPrint(
            'Wake Supabase: ${ok ? "OK / despierto" : "sin respuesta"}',
          );
        } catch (e) {
          debugPrint('Wake Supabase: $e');
        }
      }());

      unawaited(() async {
        try {
          await RenovarToken.asegurar();
          debugPrint('main: push al entrar o cada 5 min');
        } catch (e, st) {
          debugPrint('Sync nube: $e');
          debugPrint('$st');
        }
      }());

      SyncScheduler(db).start();
    } else {
      debugPrint(
        'DispositivoSync: OMITIDO — falta --dart-define '
        'SUPABASE_URL y SUPABASE_ANON_KEY',
      );
    }

    await licenciaSvc.expirarPedidosVencidos();
  } catch (e, st) {
    debugPrint('Licencia ensure: $e');
    debugPrint('$st');
  }

  final overrides = <Override>[
    databaseProvider.overrideWithValue(db),
    ventasRepositoryProvider.overrideWithValue(
      RepositoryInjection.instance.ventasRepository,
    ),
    if (additionalOverrides != null) ...additionalOverrides(db),
  ];

  return ProviderContainer(overrides: overrides);
}
