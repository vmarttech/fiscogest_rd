import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/domain/entities/ajuste_inventario.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/domain/interfaces/i_ajuste_inventario_repository.dart';

class AjusteInventarioRepositoryImplImpl implements IAjusteInventarioRepositoryImpl {
  // ✅ CONSTRUCTOR EN PRIMER LUGAR: cumple orden
  AjusteInventarioRepositoryImplImpl(this.db);
  final AppDatabase db;

  // ✅ Mapeo seguro: fecha nula BD → asigna actual, coincide DateTime entidad
  AjusteInventario _mapear(Map<String, dynamic> registro) {
    return AjusteInventario(
      id: registro['id'] as int?,
      codigoBusqueda: '', // tabla NO tiene este campo, mantiene contrato interfaz
      idProducto: registro['id_producto'] as int,
      cantidad: (registro['cantidad'] as num).toDouble(),
      tipoAjuste: registro['tipo_ajuste'] as String,
      motivo: registro['motivo'] as String,
      usuarioId: registro['usuario_id'] as int,
      fechaCreacion: (registro['fecha_creacion'] as DateTime?) ?? DateTime.now(),
    );
  }

  @override
  Future<AjusteInventario?> obtenerAjustePorCodigo(String codigoBusqueda) async {
    final registros = await db.select(db.ajusteInventarioTable).get();
    return registros.isNotEmpty ? _mapear(registros.first.toJson()) : null;
  }

  @override
  Future<List<AjusteInventario>> listarTodos() async {
    final registros = await db.select(db.ajusteInventarioTable).get();
    return registros.map((r) => _mapear(r.toJson())).toList();
  }

  @override
  Future<bool> guardarAjuste(AjusteInventario ajuste) async {
    try {
      if (ajuste.id != null) {
        await db.update(db.ajusteInventarioTable).replace(
          AjusteInventarioTableCompanion(
            id: Value(ajuste.id!),
            idProducto: Value(ajuste.idProducto),
            tipoAjuste: Value(ajuste.tipoAjuste),
            cantidad: Value(ajuste.cantidad),
            motivo: Value(ajuste.motivo),
            observaciones: const Value.absent(),
            usuarioId: Value(ajuste.usuarioId),
            fechaCreacion: Value<DateTime?>(ajuste.fechaCreacion),
          ),
        );
      } else {
        await db.into(db.ajusteInventarioTable).insert(
          AjusteInventarioTableCompanion.insert(
            idProducto: ajuste.idProducto,
            tipoAjuste: ajuste.tipoAjuste,
            cantidad: ajuste.cantidad,
            motivo: ajuste.motivo,
            usuarioId: ajuste.usuarioId,
            // ✅ SOLUCIÓN DEFINITIVA: envolvemos igual que en actualizar, compatible con firma regenerada
            fechaCreacion: Value<DateTime?>(ajuste.fechaCreacion),
          ),
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> eliminarAjuste(int id) async {
    try {
      await (db.delete(db.ajusteInventarioTable)..where((tbl) => tbl.id.equals(id))).go();
      return true;
    } catch (e) {
      return false;
    }
  }
}
