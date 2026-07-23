import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';

/// Proveedor global del núcleo de base de datos (Single Source of Truth para persistencia)
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  
  // Asegura el cierre de la base de datos cuando se deseche el contenedor
  ref.onDispose(() {
    database.close();
  });

  return database;
});