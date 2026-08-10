import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/salida.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_salida_repository.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_producto_repository.dart';

class OperacionesSalidaService {
  // ✅ Constructor primero (cumple regla orden linter)
  OperacionesSalidaService({
    required this.salidaRepository,
    required this.productoRepository,
    required this.db,
  });

  final ISalidaRepository salidaRepository;
  final IProductoRepository productoRepository;
  // ✅ Tipo confirmado y funcional: AppDatabase
  final AppDatabase db;

  // ✅ LÓGICA FASE 3.3 COMPLETA: REGISTRAR + VALIDAR STOCK + ACTUALIZAR
  Future<void> registrarSalida({
    required int productoId,
    required double cantidad,
    required String motivo,
    required int usuarioId,
  }) async {
    // 🛑 PASO 1: CARGAR PRODUCTO Y COMPROBAR DISPONIBILIDAD
    final producto = await productoRepository.obtenerProductoPorId(productoId);
    if (producto == null) {
      throw Exception('Producto no encontrado, no se puede procesar salida');
    }
    if (producto.stock < cantidad) {
      throw Exception('Stock insuficiente: Disponible: ${producto.stock}, Solicitado: $cantidad');
    }

    // 📝 PASO 2: CREAR REGISTRO DE SALIDA (campos exactos igual a tu entidad)
    final salida = Salida(
      productoId: productoId,
      cantidad: cantidad,
      motivo: motivo,
      usuarioId: usuarioId,
      fecha: DateTime.now(),
    );

    // 💾 PASO 3: GUARDAR MOVIMIENTO EN HISTORIAL
    await salidaRepository.registrarSalida(salida);

    // 📉 PASO 4: DESCONTAR CANTIDAD Y ACTUALIZAR EXISTENCIAS
    final productoActualizado = producto.copyWith(
      stock: producto.stock - cantidad,
    );
    await productoRepository.actualizarProducto(productoActualizado);
  }

  // ✅ Método adaptado al controlador: conversión segura String → int
  Future<void> registrarSalidaConValidacionStock({
    required int productoId,
    required double cantidad,
    required String motivo,
    required String usuarioId,
  }) async {
    final int idUsuarioNum = int.tryParse(usuarioId) ?? 0;
    await registrarSalida(
      productoId: productoId,
      cantidad: cantidad,
      motivo: motivo,
      usuarioId: idUsuarioNum,
    );
  }
}
