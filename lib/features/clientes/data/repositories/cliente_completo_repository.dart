import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_completo.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/clientes/data/dao/cliente_dao.dart';

class ClienteCompletoRepository {
  final ClienteDao _dao = ClienteDao(AppDatabase());

  Future<List<ClienteCompleto>> obtenerClientes() async {
    final registros = await _dao.obtenerTodos();
    return registros.map((registro) => ClienteCompleto(
      id: registro.id,
      nombre: registro.nombre,
      direccion: registro.direccion,
      telefono: registro.telefono,
      correo: registro.correo,
      rncCedula: registro.rncCedula,
      activo: registro.activo,
    )).toList();
  }

  Future<void> agregarCliente(ClienteCompleto cliente) async {
    await _dao.insertarOActualizar(ClientesTableCompanion.insert(
      codigo: '',
      nombre: cliente.nombre,
      direccion: cliente.direccion,
      telefono: cliente.telefono,
      correo: cliente.correo,
      rncCedula: cliente.rncCedula,
      activo: Value(cliente.activo),
    ));
  }

  Future<void> actualizarCliente(ClienteCompleto cliente) async {
    final identificador = cliente.id;
    if (identificador == null) {
      return;
    }
    await _dao.insertarOActualizar(ClientesTableCompanion(
      id: Value(identificador),
      codigo: const Value(''),
      nombre: Value(cliente.nombre),
      direccion: Value(cliente.direccion),
      telefono: Value(cliente.telefono),
      correo: Value(cliente.correo),
      rncCedula: Value(cliente.rncCedula),
      activo: Value(cliente.activo),
    ));
  }

  Future<void> eliminarCliente(int identificador) async {
    await _dao.eliminar(identificador);
  }
}
