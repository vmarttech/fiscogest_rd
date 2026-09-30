import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/proveedores/domain/entities/proveedor.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';

class ProveedorNotifier extends StateNotifier<AsyncValue<List<Proveedor>>> {

  ProveedorNotifier(this._ref) : super(const AsyncValue.loading()) {
    _cargarTodos();
  }
  final Ref _ref;

  Future<void> _cargarTodos() async {
    try {
      final db = _ref.read(appDatabaseProvider);
      final filas = await db.select(db.proveedoresTable).get();
      final lista = filas.map((fila) => Proveedor(
        id: fila.id,
        nombreEmpresa: fila.nombreEmpresa,
        nombreContacto: fila.nombreContacto,
        rnc: fila.rnc,
        telefono: fila.telefono,
        celular: fila.celular,
        whatsApp: fila.whatsApp,
        email: fila.email,
        direccion: fila.direccion,
        ciudad: fila.ciudad,
        provincia: fila.provincia,
        limiteCredito: fila.limiteCredito,
        diasCredito: fila.diasCredito,
        condicionesNota: fila.condicionesNota,
        estado: fila.estado,
        fechaCreacion: fila.fechaCreacion,
        fechaActualizacion: fila.fechaActualizacion,
      )).toList();
      state = AsyncValue.data(lista);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> guardar(Proveedor proveedor) async {
    try {
      final db = _ref.read(appDatabaseProvider);
      final listaActual = state.valueOrNull ?? [];

      final existeDuplicado = listaActual.any((p) =>
          p.rnc?.trim() != null &&
          proveedor.rnc?.trim() != null &&
          p.rnc!.trim() == proveedor.rnc!.trim());

      if (existeDuplicado) {
        throw Exception('Ya existe un proveedor registrado con ese RNC.');
      }

      await db.into(db.proveedoresTable).insert(
        ProveedoresTableCompanion(
          nombreEmpresa: Value(proveedor.nombreEmpresa),
          nombreContacto: Value(proveedor.nombreContacto),
          rnc: Value(proveedor.rnc),
          telefono: Value(proveedor.telefono),
          celular: Value(proveedor.celular),
          whatsApp: Value(proveedor.whatsApp),
          email: Value(proveedor.email),
          direccion: Value(proveedor.direccion),
          ciudad: Value(proveedor.ciudad),
          provincia: Value(proveedor.provincia),
          limiteCredito: Value(proveedor.limiteCredito),
          diasCredito: Value(proveedor.diasCredito),
          condicionesNota: Value(proveedor.condicionesNota),
          estado: Value(proveedor.estado),
          fechaCreacion: Value(proveedor.fechaCreacion ?? DateTime.now()),
          fechaActualizacion: Value(proveedor.fechaActualizacion),
        ),
      );

      await _cargarTodos();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> actualizar(Proveedor proveedor) async {
    try {
      final db = _ref.read(appDatabaseProvider);
      final listaActual = state.valueOrNull ?? [];

      final duplicado = listaActual.any((p) =>
          p.id != proveedor.id &&
          p.rnc?.trim() != null &&
          proveedor.rnc?.trim() != null &&
          p.rnc!.trim() == proveedor.rnc!.trim());

      if (duplicado) {
        throw Exception('Ya existe otro proveedor registrado con ese RNC.');
      }

      await db.update(db.proveedoresTable).replace(
        ProveedoresTableData(
          id: proveedor.id!,
          nombreEmpresa: proveedor.nombreEmpresa,
          nombreContacto: proveedor.nombreContacto,
          rnc: proveedor.rnc,
          telefono: proveedor.telefono,
          celular: proveedor.celular,
          whatsApp: proveedor.whatsApp,
          email: proveedor.email,
          direccion: proveedor.direccion,
          ciudad: proveedor.ciudad,
          provincia: proveedor.provincia,
          limiteCredito: proveedor.limiteCredito,
          diasCredito: proveedor.diasCredito,
          condicionesNota: proveedor.condicionesNota,
          estado: proveedor.estado,
          fechaCreacion: proveedor.fechaCreacion ?? DateTime.now(),
          fechaActualizacion: proveedor.fechaActualizacion ?? DateTime.now(),
        ),
      );

      await _cargarTodos();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> eliminar(int id) async {
    try {
      final db = _ref.read(appDatabaseProvider);
      await (db.delete(db.proveedoresTable)..where((t) => t.id.equals(id))).go();
      await _cargarTodos();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final proveedorControllerProvider =
    StateNotifierProvider<ProveedorNotifier, AsyncValue<List<Proveedor>>>((ref) {
  return ProveedorNotifier(ref);
});
