import 'package:drift/drift.dart' as drift;
// ✅ CORREGIDO: IMPORTAR app_database.dart PRINCIPAL, NO el archivo .g.dart
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/clientes/data/dao/cliente_dao.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_entity.dart';
import 'package:fiscogest_rd/features/clientes/domain/interfaces/i_cliente_repository.dart';

class ClienteRepositoryImpl implements IClienteRepository {
  ClienteRepositoryImpl(this._clienteDao);

  final ClienteDao _clienteDao;

  @override
  Future<List<ClienteEntity>> obtenerClientes() async {
    final resultados = await _clienteDao.obtenerTodos();
    return resultados
        .map((row) => ClienteEntity(
              id: row.id,
              codigo: row.codigo,
              nombre: row.nombre,
              rncCedula: row.rncCedula,
              telefono: row.telefono,
              correo: row.correo,
              direccion: row.direccion,
              activo: row.activo,
            ))
        .toList();
  }

  @override
  Future<ClienteEntity?> obtenerClientePorId(int id) async {
    final row = await _clienteDao.obtenerPorId(id);
    if (row == null) return null;
    return ClienteEntity(
      id: row.id,
      codigo: row.codigo,
      nombre: row.nombre,
      rncCedula: row.rncCedula,
      telefono: row.telefono,
      correo: row.correo,
      direccion: row.direccion,
      activo: row.activo,
    );
  }

  @override
  Future<int> guardarCliente(ClienteEntity cliente) async {
    final companion = ClientesTableCompanion(
      id: cliente.id != null
          ? drift.Value(cliente.id!)
          : const drift.Value<int>.absent(),
      codigo: drift.Value(cliente.codigo),
      nombre: drift.Value(cliente.nombre),
      rncCedula: drift.Value(cliente.rncCedula),
      telefono: drift.Value(cliente.telefono),
      correo: drift.Value(cliente.correo),
      direccion: drift.Value(cliente.direccion),
      activo: drift.Value(cliente.activo),
    );
    return await _clienteDao.insertarOActualizar(companion);
  }

  @override
  Future<bool> eliminarCliente(int id) async {
    return await _clienteDao.eliminar(id);
  }
}
