import 'package:flutter_riverpod/flutter_riverpod.dart';
// ✅ IMPORT OBLIGATORIO - CORRIGE EL ERROR DE TIPO
import 'package:fiscogestrd/models/producto.dart';
import 'package:fiscogestrd/repositories/producto_repository.dart';
import 'package:fiscogestrd/providers/producto_notifier.dart';

// ✅ Proveedor de repositorio
final productoRepositoryProvider = Provider((ref) => ProductoRepository());

// ✅ Proveedor principal, tipado correctamente
final productoNotifierProvider =
    StateNotifierProvider<ProductoNotifier, List<Producto>>((ref) {
      final repo = ref.watch(productoRepositoryProvider);
      return ProductoNotifier(repo);
    });
