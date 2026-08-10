/// Interfaz abstracta Repositorio Existencias • Etapa 3.1
/// Define operaciones obligatorias, desacopla dominio de capa datos
import 'package:fiscogest_rd/features/inventario/domain/entities/existencia.dart';

abstract class IExistenciaRepository {
  /// Consultar registro de existencias por identificador de producto
  Future<Existencia?> obtenerPorProducto(int idProducto);

  /// Crear nuevo registro inicial de existencias con validaciones
  Future<int> crear(Existencia existencia);

  /// Actualizar cantidades, aplica reglas: >=0 y disponible ≤ actual
  Future<bool> actualizar(Existencia existencia);

  /// Listar todos los registros de existencias
  Future<List<Existencia>> obtenerTodas();
}
