import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/navigation/app_router.dart';
import 'package:fiscogest_rd/core/providers/core_providers.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/interfaces/inventario_repository_interface.dart';
import 'package:fiscogest_rd/features/inventario/data/repositories/inventario_repository_impl.dart';
import 'package:fiscogest_rd/features/inventario_fisico/data/repositories/inventario_fisico_repository_impl.dart';
import 'package:fiscogest_rd/features/inventario_fisico/presentation/providers/inventario_fisico_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ La BD se crea UNA SOLA VEZ aquí
  final db = AppDatabase();

  // ✅ Repositorios reciben la instancia única
  final InventarioRepositoryInterface inventarioRepo = InventarioRepositoryImpl(db);
  final inventarioFisicoRepo = InventarioFisicoRepositoryImpl(db);

  // ✅ Configuramos el contenedor con la instancia ya creada
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      inventarioRepositoryProvider.overrideWithValue(inventarioRepo),
      inventarioFisicoRepoProvider.overrideWithValue(inventarioFisicoRepo),
    ],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FiscoGestApp(),
    ),
  );
}

class FiscoGestApp extends ConsumerWidget {
  const FiscoGestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'FiscoGest RD 3.0',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(appRouterProvider),
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueGrey,
      ),
    );
  }
}