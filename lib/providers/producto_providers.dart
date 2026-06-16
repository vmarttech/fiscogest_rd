import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/producto.dart';

// Notificador
class ProductoNotifier extends StateNotifier<List<Producto>> {
  ProductoNotifier() : super([]);

  // Cargar datos (simulado, igual que clientes)
  Future<void> cargarTodos() async {
    await Future.delayed(const Duration(milliseconds: 300));
    state = []; // Aquí iría lectura de base de datos
  }

  // Guardar / Actualizar
  Future<void> guardar(Producto producto) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (producto.id != null) {
      // Actualizar
      state = state.map((p) => p.id == producto.id ? producto : p).toList();
    } else {
      // Nuevo
      final nuevo = Producto(
        id: DateTime.now().millisecondsSinceEpoch,
        codigo: producto.codigo,
        nombre: producto.nombre,
        precioCompra: producto.precioCompra,
        precioVenta: producto.precioVenta,
        margenGanancia: producto.margenGanancia,
        valorITBIS: producto.valorITBIS,
        porcentajeImpuesto: producto.porcentajeImpuesto,
        aplicaImpuesto: producto.aplicaImpuesto,
        stockActual: producto.stockActual,
        stockMinimo: producto.stockMinimo,
        unidadMedida: producto.unidadMedida,
        fechaRegistro: producto.fechaRegistro,
      );
      state = [...state, nuevo];
    }
  }

  // Eliminar
  Future<void> eliminar(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    state = state.where((p) => p.id != id).toList();
  }
}

// ✅ NOMBRE EXACTO QUE BUSCAN LOS OTROS ARCHIVOS
final productoNotifierProvider = StateNotifierProvider<ProductoNotifier, List<Producto>>((ref) {
  return ProductoNotifier();
});