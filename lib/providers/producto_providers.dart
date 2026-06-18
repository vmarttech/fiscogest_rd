import 'package:flutter_riverpod/flutter_riverpod.dart';
// ✅ IMPORT OBLIGATORIO - CORRIGE EL ERROR DE TIPO
import '../models/producto.dart';
import '../repositories/producto_repository.dart';
import 'producto_notifier.dart';

// ✅ Proveedor de repositorio
final productoRepositoryProvider = Provider((ref) => ProductoRepository());

// ✅ Proveedor principal, tipado correctamente
final productoNotifierProvider = StateNotifierProvider<ProductoNotifier, List<Producto>>((ref) {
  final repo = ref.watch(productoRepositoryProvider);
  return ProductoNotifier(repo);
});