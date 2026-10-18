import 'package:fiscogest_rd/features/licencias/domain/licencia_limites_guard.dart';
import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_completo.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/clientes/data/dao/cliente_dao.dart';

class ClienteCompletoRepository {
  ClienteCompletoRepository(AppDatabase db)
      : _db = db,
        _dao = ClienteDao(db);

  final AppDatabase _db;
  final ClienteDao _dao;

  ClienteCompleto _map(ClientesTableData r) => ClienteCompleto(
        id: r.id,
        nombre: r.nombre,
        direccion: r.direccion,
        telefono: r.telefono,
        correo: r.correo,
        rncCedula: r.rncCedula,
        activo: r.activo,
        ingresoMensual: r.ingresoMensual,
        limiteCuotaMensual: r.limiteCuotaMensual,
        saldoPendiente: r.saldoPendiente,
      );

  Future<List<ClienteCompleto>> obtenerClientes() async {
    final registros = await _dao.obtenerTodos();
    return registros.map(_map).toList();
  }

  Future<ClienteCompleto?> obtenerPorId(int id) async {
    final r = await _dao.obtenerPorId(id);
    return r == null ? null : _map(r);
  }

  Future<void> agregarCliente(ClienteCompleto cliente) async {
    await LicenciaLimitesGuard(_db).assertPuedeCrearCliente();
    final codigoUnico = 'CLI-${DateTime.now().millisecondsSinceEpoch}';
    await _dao.insertarOActualizar(
      ClientesTableCompanion.insert(
        codigo: codigoUnico,
        nombre: cliente.nombre,
        direccion: cliente.direccion,
        telefono: cliente.telefono,
        correo: cliente.correo,
        rncCedula: cliente.rncCedula,
        activo: Value(cliente.activo),
        ingresoMensual: Value(cliente.ingresoMensual),
        limiteCuotaMensual: Value(cliente.limiteCuotaMensual),
        saldoPendiente: Value(cliente.saldoPendiente),
      ),
    );
  }

  Future<void> actualizarCliente(ClienteCompleto cliente) async {
    final identificador = cliente.id;
    if (identificador == null) {
      throw Exception('No se puede actualizar el cliente: ID nulo');
    }
    final filas = await _dao.actualizarPorId(
      identificador,
      ClientesTableCompanion(
        nombre: Value(cliente.nombre),
        direccion: Value(cliente.direccion),
        telefono: Value(cliente.telefono),
        correo: Value(cliente.correo),
        rncCedula: Value(cliente.rncCedula),
        activo: Value(cliente.activo),
        ingresoMensual: Value(cliente.ingresoMensual),
        limiteCuotaMensual: Value(cliente.limiteCuotaMensual),
      ),
    );
    if (filas == 0) {
      throw Exception(
        'No se encontró el cliente a actualizar (id=$identificador)',
      );
    }
  }

  Future<void> eliminarCliente(int identificador) async {
    await _dao.eliminar(identificador);
  }
}
