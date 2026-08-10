import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/conteo_fisico.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/estado_conteo.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/diferencia_conteo.dart';
import 'package:fiscogest_rd/core/interfaces/inventario_fisico_repository_interface.dart';
import 'package:fiscogest_rd/features/inventario_fisico/data/datasources/inventario_fisico_database.dart';

class InventarioFisicoRepositoryImpl implements InventarioFisicoRepositoryInterface {
  InventarioFisicoRepositoryImpl(this._db);
  // ✅ CONSTRUCTOR EN PRIMER LUGAR: corrige aviso sort_constructors_first
  final InventarioFisicoDatabase _db;

  @override
  Future<void> registrarConteo(ConteoFisico conteo) async {
    await _db.into(_db.conteosFisicos).insert(
      ConteosFisicosCompanion.insert(
        nombreConteo: conteo.nombreConteo,
        fechaConteo: conteo.fechaConteo,
        observaciones: Value(conteo.observaciones),
        usuarioId: conteo.usuarioId,
        fechaCreacion: Value(conteo.fechaCreacion),
        estado: Value(conteo.estado.name),
      ),
    );
  }

  @override
  Future<List<ConteoFisico>> listarConteos() async {
    final registros = await _db.select(_db.conteosFisicos).get();
    return registros.map((r) => ConteoFisico(
      id: r.id,
      nombreConteo: r.nombreConteo,
      fechaConteo: r.fechaConteo,
      observaciones: r.observaciones ?? '',
      usuarioId: r.usuarioId,
      fechaCreacion: r.fechaCreacion,
      estado: EstadoConteo.values.byName(r.estado),
    )).toList();
  }

  // ✅ MAPEO PERFECTO, NOMBRES EXACTOS, TODOS CAMPOS OBLIGATORIOS, valores seguros nulos
  @override
  Future<List<DiferenciaConteo>> listarDiferencias(int conteoId) async {
    final registrosDrift = await (_db.select(_db.diferenciasConteo)
          ..where((tbl) => tbl.conteoId.equals(conteoId)))
        .get();

    return registrosDrift.map((registro) => DiferenciaConteo(
      id: registro.id,
      conteoId: registro.conteoId,
      codigoProducto: registro.codigoProducto,
      nombreProducto: registro.nombreProducto,
      stockSistema: registro.stockSistema,
      stockFisico: registro.stockFisico,
      diferencia: registro.diferencia,
      motivo: registro.motivo ?? '', // ✅ valor por defecto seguro String?→String
      estado: registro.estado,
    )).toList();
  }

  @override
  Future<void> aprobarAjustes(int conteoId, int usuarioId) async {
    await _db.update(_db.conteosFisicos).replace(
      ConteosFisicosCompanion(
        id: Value(conteoId),
        estado: Value(EstadoConteo.aprobado.name),
      ),
    );
  }

  @override
  Future<Uint8List> generarReporte(int conteoId) async {
    return Uint8List(0);
  }
}
