import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/interfaces/inventario_repository_interface.dart';
import 'package:fiscogest_rd/core/interfaces/inventario_fisico_repository_interface.dart';

// ✅ Opcional válido: el usuario puede no estar autenticado
final usuarioAutenticadoProvider = Provider<int?>((ref) => null);

// ✅ OBLIGATORIO POR ARQUITECTURA: No nulo, exige inicialización explícita en main.dart
final inventarioRepositoryProvider = Provider<InventarioRepositoryInterface>((ref) {
  throw StateError('Inicializa inventarioRepositoryProvider en main.dart mediante overrideWithValue');
});

// ✅ MISMA REGLA: No nulo, inicialización controlada en el arranque
final inventarioFisicoRepositoryProvider = Provider<InventarioFisicoRepositoryInterface>((ref) {
  throw StateError('Inicializa inventarioFisicoRepositoryProvider en main.dart mediante overrideWithValue');
});