// Interfaz base y repositorio genérico para operaciones CRUD, filtros y paginación
abstract class IBaseRepository<T, ID> {
  Future<List<T>> getAll();
  Future<T?> getById(ID id);
  Future<ID> insert(T entity);
  Future<bool> update(T entity);
  Future<bool> delete(ID id);

  // Consultas avanzadas, filtros y paginación base
  Future<List<T>> getPaged({
    required int limit,
    required int offset,
    String? filter,
  });
}
