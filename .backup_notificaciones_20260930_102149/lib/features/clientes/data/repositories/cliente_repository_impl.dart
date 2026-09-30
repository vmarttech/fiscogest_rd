import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/clientes/domain/interfaces/i_cliente_repository.dart';
import 'package:fiscogest_rd/features/clientes/data/dao/cliente_dao.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_entity.dart';

class ClienteRepositoryImpl implements IClienteRepository {
  ClienteRepositoryImpl(this._clienteDao);
  final ClienteDao _clienteDao;

  ClienteEntity _mapearEntidad(ClientesTableData tabla) {
    return ClienteEntity(
      id: tabla.id,
      codigo: tabla.codigo,
      nombre: tabla.nombre,
      rncCedula: tabla.rncCedula,
      telefono: tabla.telefono,
      correo: tabla.correo,
      direccion: tabla.direccion,
      activo: tabla.activo,
      saldoPendiente: tabla.saldoPendiente,
    );
  }

  ClientesTableCompanion _mapearTabla(ClienteEntity entidad) {
    return ClientesTableCompanion(
      id: entidad.id != null
          ? Value<int>(entidad.id!)
          : const Value<int>.absent(),
      codigo: Value<String>(entidad.codigo),
      nombre: Value<String>(entidad.nombre),
      rncCedula: Value<String>(entidad.rncCedula),
      telefono: Value<String>(entidad.telefono),
      correo: Value<String>(entidad.correo),
      direccion: Value<String>(entidad.direccion),
      activo: Value<bool>(entidad.activo),
      saldoPendiente: Value<double>(entidad.saldoPendiente),
    );
  }

  @override
  Future<List<ClienteEntity>> obtenerClientes() async {
    final registros = await _clienteDao.obtenerTodos();
    return registros.map((r) => _mapearEntidad(r)).toList();
  }

  @override
  Future<ClienteEntity?> obtenerClientePorId(int id) async {
    final registro = await _clienteDao.obtenerPorId(id);
    if (registro == null) return null;
    return _mapearEntidad(registro);
  }

  @override
  Future<int> guardarCliente(ClienteEntity cliente) async {
    return _clienteDao.insertarOActualizar(_mapearTabla(cliente));
  }

  @override
  Future<bool> eliminarCliente(int id) async {
    return _clienteDao.eliminar(id);
  }

  @override
  Future<void> actualizarSaldo(
    int clienteId,
    double monto,
    bool esCargo,
  ) async {
    await _clienteDao.actualizarSaldo(clienteId, monto, esCargo);
  }

  @override
  Future<double?> obtenerSaldo(int clienteId) async {
    return _clienteDao.obtenerSaldo(clienteId);
  }
}
