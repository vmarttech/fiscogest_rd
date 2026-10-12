import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/e_cf/domain/entities/ecfe_config.dart';
import 'package:fiscogest_rd/features/e_cf/domain/entities/ecfe_documento.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/ambiente_dgii.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/estado_ecf_interno.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/tipo_ecf.dart';
import 'dart:convert';
import 'package:fiscogest_rd/features/e_cf/domain/entities/ecfe_spec_version.dart';
import 'package:fiscogest_rd/features/e_cf/domain/entities/ecfe_checklist_item.dart';
import 'package:fiscogest_rd/features/e_cf/domain/services/ecfe_checklist_catalog.dart';

class EcfeRepository {
  EcfeRepository(this._db);
  final AppDatabase _db;

  AmbienteDgii _amb(String s) {
    return AmbienteDgii.values.firstWhere(
      (a) => a.name == s,
      orElse: () => AmbienteDgii.deshabilitado,
    );
  }

  EstadoEcfInterno _est(String s) {
    return EstadoEcfInterno.values.firstWhere(
      (e) => e.name == s,
      orElse: () => EstadoEcfInterno.borrador,
    );
  }

  EcfeDocumento _mapDoc(EcfeDocumentosTableData r) {
    final tipo = TipoEcf.fromCodigo(r.tipoEcf) ?? TipoEcf.facturaConsumo;
    return EcfeDocumento(
      id: r.id,
      ventaId: r.ventaId,
      tipoEcf: tipo,
      encf: r.encf,
      estado: _est(r.estado),
      trackId: r.trackId,
      codigoRespuesta: r.codigoRespuesta,
      mensajeDgii: r.mensajeDgii,
      ultimoError: r.ultimoError,
      codigoSeguridad: r.codigoSeguridad,
      encfReferencia: r.encfReferencia,
      motivoAnulacion: r.motivoAnulacion,
      creadoEn: r.creadoEn,
      actualizadoEn: r.actualizadoEn,
    );
  }

  Future<EcfeConfig> obtenerConfig() async {
    final rows = await _db.select(_db.ecfeConfigTable).get();
    if (rows.isEmpty) return const EcfeConfig();
    final r = rows.first;
    return EcfeConfig(
      id: r.id,
      habilitado: r.habilitado,
      ambiente: _amb(r.ambiente),
      rncEmisor: r.rncEmisor,
      razonSocialEmisor: r.razonSocialEmisor,
      rutaCertificado: r.rutaCertificado,
      aliasCertificado: r.aliasCertificado,
      claveCertificado: r.claveCertificado,
      xsdVersion: r.xsdVersion,
    );
  }

  Future<void> guardarConfig(EcfeConfig c) async {
    final existing = await _db.select(_db.ecfeConfigTable).get();
    if (existing.isEmpty) {
      await _db
          .into(_db.ecfeConfigTable)
          .insert(
            EcfeConfigTableCompanion.insert(
              habilitado: Value(c.habilitado),
              ambiente: Value(c.ambiente.name),
              rncEmisor: Value(c.rncEmisor),
              razonSocialEmisor: Value(c.razonSocialEmisor),
              rutaCertificado: Value(c.rutaCertificado),
              aliasCertificado: Value(c.aliasCertificado),
              claveCertificado: Value(c.claveCertificado),
              xsdVersion: Value(c.xsdVersion),
            ),
          );
    } else {
      await (_db.update(
        _db.ecfeConfigTable,
      )..where((t) => t.id.equals(existing.first.id))).write(
        EcfeConfigTableCompanion(
          habilitado: Value(c.habilitado),
          ambiente: Value(c.ambiente.name),
          rncEmisor: Value(c.rncEmisor),
          razonSocialEmisor: Value(c.razonSocialEmisor),
          rutaCertificado: Value(c.rutaCertificado),
          aliasCertificado: Value(c.aliasCertificado),
          claveCertificado: Value(c.claveCertificado),
          xsdVersion: Value(c.xsdVersion),
          actualizadoEn: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<List<EcfeDocumento>> listarDocumentos({
    int limit = 200,
    List<String>? estados,
  }) async {
    final q = _db.select(_db.ecfeDocumentosTable)
      ..orderBy([(t) => OrderingTerm.desc(t.id)])
      ..limit(limit);
    if (estados != null && estados.isNotEmpty) {
      q.where((t) => t.estado.isIn(estados));
    }
    final rows = await q.get();
    return rows.map(_mapDoc).toList();
  }

  Future<EcfeDocumento?> obtenerPorId(int id) async {
    final row = await (_db.select(
      _db.ecfeDocumentosTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapDoc(row);
  }

  Future<List<EcfeDocumento>> listarPorVentaId(int ventaId) async {
    final rows = await (_db.select(
      _db.ecfeDocumentosTable,
    )..where((t) => t.ventaId.equals(ventaId))).get();
    return [for (final row in rows) _mapDoc(row)];
  }

  Future<EcfeDocumento?> buscarPorVentaId(int ventaId) async {
    final row =
        await (_db.select(_db.ecfeDocumentosTable)
              ..where((t) => t.ventaId.equals(ventaId))
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _mapDoc(row);
  }

  Future<int> insertarDocumento({
    required int ventaId,
    required TipoEcf tipoEcf,
    required EstadoEcfInterno estado,
    String? ncfLocal,
    String? ultimoError,
    String? encfReferencia,
  }) async {
    final now = DateTime.now();
    return _db
        .into(_db.ecfeDocumentosTable)
        .insert(
          EcfeDocumentosTableCompanion.insert(
            ventaId: Value(ventaId),
            tipoEcf: tipoEcf.codigo,
            encf: const Value(null), // e-NCF se asigna al generar XML
            encfReferencia: Value(encfReferencia),
            estado: Value(estado.name),
            ultimoError: Value(ultimoError),
            creadoEn: now,
            actualizadoEn: Value(now),
          ),
        );
  }

  Future<void> actualizarEstado({
    required int id,
    required EstadoEcfInterno estado,
    String? ultimoError,
    String? trackId,
    String? codigoRespuesta,
    String? mensajeDgii,
  }) async {
    await (_db.update(
      _db.ecfeDocumentosTable,
    )..where((t) => t.id.equals(id))).write(
      EcfeDocumentosTableCompanion(
        estado: Value(estado.name),
        ultimoError: Value(ultimoError),
        trackId: trackId != null ? Value(trackId) : const Value.absent(),
        codigoRespuesta: codigoRespuesta != null
            ? Value(codigoRespuesta)
            : const Value.absent(),
        mensajeDgii: mensajeDgii != null
            ? Value(mensajeDgii)
            : const Value.absent(),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
  }

  Future<void> registrarEvento({
    required int documentoId,
    required String paso,
    required bool ok,
    String? detalle,
  }) async {
    await _db
        .into(_db.ecfeEventosTable)
        .insert(
          EcfeEventosTableCompanion.insert(
            documentoId: documentoId,
            paso: paso,
            detalle: Value(detalle),
            ok: Value(ok),
            creadoEn: DateTime.now(),
          ),
        );
  }

  Future<List<({String paso, bool ok, String? detalle, DateTime creadoEn})>>
  listarEventos(int documentoId) async {
    final rows =
        await (_db.select(_db.ecfeEventosTable)
              ..where((t) => t.documentoId.equals(documentoId))
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
    return rows
        .map(
          (r) => (
            paso: r.paso,
            ok: r.ok,
            detalle: r.detalle,
            creadoEn: r.creadoEn,
          ),
        )
        .toList();
  }

  Future<void> guardarXml({
    required int id,
    required String xmlSinFirma,
    required String encf,
    required EstadoEcfInterno estado,
    String? ultimoError,
  }) async {
    await (_db.update(
      _db.ecfeDocumentosTable,
    )..where((t) => t.id.equals(id))).write(
      EcfeDocumentosTableCompanion(
        xmlSinFirma: Value(xmlSinFirma),
        encf: Value(encf),
        estado: Value(estado.name),
        ultimoError: Value(ultimoError),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
  }

  Future<String?> obtenerXmlSinFirma(int id) async {
    final row = await (_db.select(
      _db.ecfeDocumentosTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.xmlSinFirma;
  }

  Future<void> guardarXmlFirmado({
    required int id,
    required String xmlFirmado,
    required EstadoEcfInterno estado,
    String? ultimoError,
    String? codigoSeguridad,
  }) async {
    await (_db.update(
      _db.ecfeDocumentosTable,
    )..where((t) => t.id.equals(id))).write(
      EcfeDocumentosTableCompanion(
        xmlFirmado: Value(xmlFirmado),
        estado: Value(estado.name),
        ultimoError: Value(ultimoError),
        codigoSeguridad: codigoSeguridad != null
            ? Value(codigoSeguridad)
            : const Value.absent(),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
  }

  Future<String?> obtenerXmlFirmado(int id) async {
    final row = await (_db.select(
      _db.ecfeDocumentosTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.xmlFirmado;
  }

  // ── Spec version + checklist ─────────────────────────────

  EcfeSpecVersion _mapSpec(EcfeSpecVersionTableData r) {
    return EcfeSpecVersion(
      id: r.id,
      codigo: r.codigo,
      nombre: r.nombre,
      circularDgii: r.circularDgii,
      xsdVersion: r.xsdVersion,
      notas: r.notas,
      activaPrecert: r.activaPrecert,
      activaCert: r.activaCert,
      activaProduccion: r.activaProduccion,
      checklistJson: r.checklistJson,
      creadoEn: r.creadoEn,
      activadoEn: r.activadoEn,
    );
  }

  Future<List<EcfeSpecVersion>> listarSpecVersions() async {
    final rows = await (_db.select(
      _db.ecfeSpecVersionTable,
    )..orderBy([(t) => OrderingTerm.desc(t.creadoEn)])).get();
    return rows.map(_mapSpec).toList();
  }

  Future<EcfeSpecVersion?> obtenerSpecPorId(int id) async {
    final r = await (_db.select(
      _db.ecfeSpecVersionTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : _mapSpec(r);
  }

  /// Spec activa para el ambiente actual de config (si ninguna, null).
  Future<EcfeSpecVersion?> obtenerSpecActivaParaAmbiente(
    String ambienteName,
  ) async {
    final rows = await _db.select(_db.ecfeSpecVersionTable).get();
    for (final r in rows) {
      if (ambienteName == 'precertificacion' && r.activaPrecert) {
        return _mapSpec(r);
      }
      if (ambienteName == 'certificacion' && r.activaCert) return _mapSpec(r);
      if (ambienteName == 'produccion' && r.activaProduccion) {
        return _mapSpec(r);
      }
    }
    return null;
  }

  Future<int> insertarSpecVersion({
    required String codigo,
    required String nombre,
    String? circularDgii,
    String xsdVersion = '',
    String? notas,
    List<EcfeChecklistItem>? checklist,
  }) async {
    final items = checklist ?? EcfeChecklistCatalog.plantillaBase();
    final json = jsonEncode(items.map((e) => e.toJson()).toList());
    return _db
        .into(_db.ecfeSpecVersionTable)
        .insert(
          EcfeSpecVersionTableCompanion.insert(
            codigo: codigo,
            nombre: nombre,
            circularDgii: Value(circularDgii),
            xsdVersion: Value(xsdVersion),
            notas: Value(notas),
            checklistJson: Value(json),
            creadoEn: DateTime.now(),
          ),
        );
  }

  Future<void> asegurarSpecDefault() async {
    final existing = await _db.select(_db.ecfeSpecVersionTable).get();
    if (existing.isNotEmpty) return;
    await insertarSpecVersion(
      codigo: '1.0',
      nombre: 'e-CF base (FiscoGest fases 1–4 + RI)',
      circularDgii: 'Especificación técnica DGII e-CF v1.0 (referencia local)',
      xsdVersion: '1.0',
      notas:
          'XML 31/32/34, firma RSA-SHA256, recepción/consulta, RI/QR, RFCE < 250000.',
    );
  }

  Future<void> activarSpec({
    required int id,
    required bool precert,
    required bool cert,
    required bool produccion,
  }) async {
    final all = await _db.select(_db.ecfeSpecVersionTable).get();
    for (final r in all) {
      final isTarget = r.id == id;
      var ap = r.activaPrecert;
      var ac = r.activaCert;
      var apo = r.activaProduccion;
      if (precert) {
        ap = isTarget;
      }
      if (cert) {
        ac = isTarget;
      }
      if (produccion) {
        apo = isTarget;
      }
      await (_db.update(
        _db.ecfeSpecVersionTable,
      )..where((t) => t.id.equals(r.id))).write(
        EcfeSpecVersionTableCompanion(
          activaPrecert: Value(ap),
          activaCert: Value(ac),
          activaProduccion: Value(apo),
          activadoEn: isTarget ? Value(DateTime.now()) : const Value.absent(),
        ),
      );
    }
  }

  List<EcfeChecklistItem> parseChecklist(String json) {
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map(
            (e) =>
                EcfeChecklistItem.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } catch (_) {
      return EcfeChecklistCatalog.plantillaBase();
    }
  }

  Future<void> actualizarChecklistItem({
    required int specId,
    required String itemId,
    required bool done,
  }) async {
    final row = await (_db.select(
      _db.ecfeSpecVersionTable,
    )..where((t) => t.id.equals(specId))).getSingleOrNull();
    if (row == null) return;
    final items = parseChecklist(row.checklistJson);
    final out = <EcfeChecklistItem>[];
    for (final it in items) {
      if (it.id == itemId) {
        out.add(it.copyWith(done: done, doneAt: done ? DateTime.now() : null));
      } else {
        out.add(it);
      }
    }
    await (_db.update(
      _db.ecfeSpecVersionTable,
    )..where((t) => t.id.equals(specId))).write(
      EcfeSpecVersionTableCompanion(
        checklistJson: Value(jsonEncode(out.map((e) => e.toJson()).toList())),
      ),
    );
  }

  Future<void> resetChecklist(int specId) async {
    final items = EcfeChecklistCatalog.plantillaBase();
    await (_db.update(
      _db.ecfeSpecVersionTable,
    )..where((t) => t.id.equals(specId))).write(
      EcfeSpecVersionTableCompanion(
        checklistJson: Value(jsonEncode(items.map((e) => e.toJson()).toList())),
      ),
    );
  }

  Future<void> guardarCodigoSeguridad({
    required int id,
    required String codigoSeguridad,
  }) async {
    final c = codigoSeguridad.trim().toUpperCase();
    if (c.isEmpty) return;
    await (_db.update(
      _db.ecfeDocumentosTable,
    )..where((t) => t.id.equals(id))).write(
      EcfeDocumentosTableCompanion(
        codigoSeguridad: Value(c),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
  }

  /// Productos cuyo impuesto es ITBIS 0 % y no está marcado exento.
  Future<Set<int>> productosGravadosCero(Iterable<int> ids) async {
    final lista = ids.where((id) => id > 0).toSet();
    if (lista.isEmpty) return {};
    final impuestos = await _db.select(_db.impuestosTable).get();
    final cero = <int>{};
    for (final i in impuestos) {
      final tipo = i.tipo.toLowerCase();
      final exento = i.esExento;
      if (!exento && tipo != 'exento' && i.porcentaje.abs() < 0.001) {
        cero.add(i.id);
      }
    }
    if (cero.isEmpty) return {};
    final productos = await (_db.select(
      _db.productosTable,
    )..where((t) => t.id.isIn(lista))).get();
    return {
      for (final p in productos)
        if (p.impuestoId != null && cero.contains(p.impuestoId)) p.id,
    };
  }

  Future<DateTime?> fechaVentaPorEncf(String encf) async {
    final doc =
        await (_db.select(_db.ecfeDocumentosTable)
              ..where((t) => t.encf.equals(encf.trim().toUpperCase())))
            .getSingleOrNull();
    final ventaId = doc?.ventaId;
    if (ventaId == null) return null;
    final venta = await (_db.select(
      _db.ventasTable,
    )..where((t) => t.id.equals(ventaId))).getSingleOrNull();
    return venta?.fecha;
  }

  Future<String?> codigoSeguridadPorVenta(int ventaId) async {
    final rows = await (_db.select(
      _db.ecfeDocumentosTable,
    )..where((t) => t.ventaId.equals(ventaId))).get();
    if (rows.isEmpty) return null;
    final codigo = (rows.first.codigoSeguridad ?? '').trim();
    return codigo.isEmpty ? null : codigo;
  }

  Future<void> anularDocumento({
    required int id,
    required String motivo,
  }) async {
    final m = motivo.trim();
    if (m.isEmpty) throw ArgumentError('Indica el motivo de anulación');
    await (_db.update(
      _db.ecfeDocumentosTable,
    )..where((t) => t.id.equals(id))).write(
      EcfeDocumentosTableCompanion(
        estado: Value(EstadoEcfInterno.anulado.name),
        motivoAnulacion: Value(m),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
  }

  Future<void> guardarEncfReferencia({
    required int id,
    required String encfReferencia,
  }) async {
    await (_db.update(
      _db.ecfeDocumentosTable,
    )..where((t) => t.id.equals(id))).write(
      EcfeDocumentosTableCompanion(
        encfReferencia: Value(encfReferencia.trim().toUpperCase()),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
  }
}
