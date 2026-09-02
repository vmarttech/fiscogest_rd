import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/conteo_fisico.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/diferencia_conteo.dart';
import 'package:fiscogest_rd/core/interfaces/inventario_fisico_repository_interface.dart';

class InventarioFisicoRepositoryImpl
    implements InventarioFisicoRepositoryInterface {
  InventarioFisicoRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<void> registrarConteo(ConteoFisico conteo) async {
    await _db
        .into(_db.conteosFisicos)
        .insert(
          ConteosFisicosCompanion.insert(
            nombreConteo: conteo.nombreConteo,
            fechaConteo: conteo.fechaConteo,
            observaciones: Value(conteo.observaciones),
            usuarioId: conteo.usuarioId,
            fechaCreacion: Value(conteo.fechaCreacion),
            estado: conteo.estado.name,
          ),
        );
  }

  @override
  Future<List<ConteoFisico>> listarConteos() async {
    final registros = await _db.select(_db.conteosFisicos).get();
    return registros
        .map(
          (r) => ConteoFisico(
            id: r.id,
            nombreConteo: r.nombreConteo,
            fechaConteo: r.fechaConteo,
            observaciones: r.observaciones,
            usuarioId: r.usuarioId,
            fechaCreacion: r.fechaCreacion,
            estado: EstadoConteo.values.byName(r.estado),
          ),
        )
        .toList();
  }

  @override
  Future<List<DiferenciaConteo>> listarDiferencias(int conteoId) async {
    final registros = await (_db.select(
      _db.diferenciasConteo,
    )..where((t) => t.conteoId.equals(conteoId))).get();
    return registros
        .map(
          (r) => DiferenciaConteo(
            id: r.id,
            conteoId: r.conteoId,
            productoId: r.productoId,
            codigoProducto: r.codigoProducto,
            nombreProducto: r.nombreProducto,
            stockSistema: r.stockSistema,
            stockFisico: r.stockFisico,
            diferencia: r.diferencia,
            motivo: r.motivo,
            estado: r.estado ?? '',
          ),
        )
        .toList();
  }

  @override
  Future<void> aprobarAjustes(int conteoId, int usuarioId) async {}

  @override
  Future<Uint8List> generarReporte(int conteoId) async => Uint8List(0);
}
