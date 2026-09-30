import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/creditos/data/dao/solicitudes_credito_table.dart';
import 'package:fiscogest_rd/features/creditos/data/dao/referencias_credito_table.dart';

part 'solicitud_credito_dao.g.dart';

@DriftAccessor(tables: [SolicitudesCreditoTable, ReferenciasCreditoTable])
class SolicitudCreditoDao extends DatabaseAccessor<AppDatabase>
    with _$SolicitudCreditoDaoMixin {
  SolicitudCreditoDao(super.db);

  Future<SolicitudCreditoData?> porVentaId(int ventaId) {
    return (select(
      solicitudesCreditoTable,
    )..where((t) => t.ventaId.equals(ventaId))).getSingleOrNull();
  }

  Future<SolicitudCreditoData> obtenerOCrearPorVenta({
    required int ventaId,
    String nombreInicial = '',
    int usuarioId = 1,
  }) async {
    final actual = await porVentaId(ventaId);
    if (actual != null) return actual;
    final id = await into(solicitudesCreditoTable).insert(
      SolicitudesCreditoTableCompanion.insert(
        ventaId: ventaId,
        nombreCompleto: Value(nombreInicial),
        usuarioId: Value(usuarioId),
      ),
    );
    return (select(
      solicitudesCreditoTable,
    )..where((t) => t.id.equals(id))).getSingle();
  }

  Future<void> actualizarSolicitud(
    SolicitudesCreditoTableCompanion data,
  ) async {
    if (!data.id.present) {
      throw Exception('actualizarSolicitud requiere id');
    }
    await (update(solicitudesCreditoTable)
          ..where((t) => t.id.equals(data.id.value)))
        .write(data.copyWith(actualizadoEn: Value(DateTime.now())));
  }

  Future<List<ReferenciaCreditoData>> listarReferencias(int solicitudId) {
    return (select(referenciasCreditoTable)
          ..where((t) => t.solicitudId.equals(solicitudId))
          ..orderBy([(t) => OrderingTerm.asc(t.orden)]))
        .get();
  }

  Future<void> reemplazarReferencias({
    required int solicitudId,
    required List<ReferenciasCreditoTableCompanion> refs,
  }) async {
    await (delete(
      referenciasCreditoTable,
    )..where((t) => t.solicitudId.equals(solicitudId))).go();
    for (var i = 0; i < refs.length; i++) {
      final r = refs[i];
      await into(referenciasCreditoTable).insert(
        r.copyWith(solicitudId: Value(solicitudId), orden: Value(i + 1)),
      );
    }
  }
}
