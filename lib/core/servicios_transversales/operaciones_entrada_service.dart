import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/entrada.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_entrada_repository.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_producto_repository.dart';

class OperacionesEntradaService {
  // ✅ Constructor primero (cumple regla orden linter)
  OperacionesEntradaService({
    required this.entradaRepository,
    required this.productoRepository,
    required this.db,
  });

  final IEntradaRepository entradaRepository;
  final IProductoRepository productoRepository;
  // ✅ TIPO + IMPORT EXACTOS según lo encontrado por grep
  final AppDatabase db;

  // ✅ Parámetros iguales a Entidad Entrada: productoId
  Future<void> registrarEntrada({
    required int productoId,
    required double cantidad,
    required String motivo,
    required int usuarioId,
  }) async {
    final entrada = Entrada(
      productoId: productoId,
      cantidad: cantidad,
      motivo: motivo,
      usuarioId: usuarioId,
      fecha: DateTime.now(),
    );

    // ✅ Método EXACTO de interfaz: registrarEntrada
    await entradaRepository.registrarEntrada(entrada);

    // ✅ Actualizar existencias respetando métodos existentes del repositorio
    final producto = await productoRepository.obtenerProductoPorId(productoId);
    if (producto != null) {
      final productoActualizado = producto.copyWith(
        stock: producto.stock + cantidad,
      );
      await productoRepository.actualizarProducto(productoActualizado);
    }
  }

  // ✅ Método completo, conversión segura String → int
  Future<void> registrarEntradaConAjusteStock({
    required int productoId,
    required double cantidad,
    required String motivo,
    required String usuarioId,
  }) async {
    final int idUsuarioNum = int.tryParse(usuarioId) ?? 0;
    await registrarEntrada(
      productoId: productoId,
      cantidad: cantidad,
      motivo: motivo,
      usuarioId: idUsuarioNum,
    );
  }
}
