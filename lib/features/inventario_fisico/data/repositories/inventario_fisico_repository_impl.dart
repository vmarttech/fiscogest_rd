import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/interfaces/inventario_fisico_repository_interface.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/conteo_fisico.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/diferencia_conteo.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/estado_conteo.dart';

class InventarioFisicoRepositoryImpl
    implements InventarioFisicoRepositoryInterface {
  InventarioFisicoRepositoryImpl(this._db);
  final AppDatabase _db;

  EstadoConteo _parseEstado(String raw) {
    final k = raw.toLowerCase();
    return EstadoConteo.values.firstWhere(
      (e) => e.name.toLowerCase() == k,
      orElse: () => EstadoConteo.pendiente,
    );
  }

  Future<EstadoConteo?> _estadoConteo(int conteoId) async {
    final row = await (_db.select(
      _db.conteosFisicos,
    )..where((t) => t.id.equals(conteoId))).getSingleOrNull();
    if (row == null) return null;
    return _parseEstado(row.estado);
  }

  @override
  Future<int> registrarConteo(ConteoFisico conteo) async {
    final id = await _db
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
    return id;
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
            estado: _parseEstado(r.estado),
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
            estado: r.estado ?? 'pendiente',
          ),
        )
        .toList();
  }

  @override
  Future<void> guardarDiferencia(DiferenciaConteo dif) async {
    final est = await _estadoConteo(dif.conteoId);
    if (est == EstadoConteo.aprobado || est == EstadoConteo.cancelado) {
      throw StateError(
        'El conteo está ${est?.etiqueta ?? est?.name} y no admite más líneas.',
      );
    }

    final existing =
        await (_db.select(_db.diferenciasConteo)..where(
              (t) =>
                  t.conteoId.equals(dif.conteoId) &
                  t.productoId.equals(dif.productoId),
            ))
            .getSingleOrNull();

    if (existing == null) {
      await _db
          .into(_db.diferenciasConteo)
          .insert(
            DiferenciasConteoCompanion.insert(
              conteoId: dif.conteoId,
              productoId: dif.productoId,
              codigoProducto: dif.codigoProducto,
              nombreProducto: dif.nombreProducto,
              stockSistema: dif.stockSistema,
              stockFisico: dif.stockFisico,
              diferencia: dif.diferencia,
              motivo: Value(dif.motivo),
              estado: Value(dif.estado.isEmpty ? 'pendiente' : dif.estado),
            ),
          );
    } else {
      if (existing.estado == 'aprobado') {
        throw StateError('Esta línea ya fue aprobada.');
      }
      await (_db.update(
        _db.diferenciasConteo,
      )..where((t) => t.id.equals(existing.id))).write(
        DiferenciasConteoCompanion(
          stockSistema: Value(dif.stockSistema),
          stockFisico: Value(dif.stockFisico),
          diferencia: Value(dif.diferencia),
          motivo: Value(dif.motivo),
          estado: Value(dif.estado.isEmpty ? 'pendiente' : dif.estado),
        ),
      );
    }

    await actualizarEstadoConteo(dif.conteoId, EstadoConteo.enProceso);
  }

  @override
  Future<void> actualizarEstadoConteo(int conteoId, EstadoConteo estado) async {
    await (_db.update(_db.conteosFisicos)..where((t) => t.id.equals(conteoId)))
        .write(ConteosFisicosCompanion(estado: Value(estado.name)));
  }

  @override
  Future<void> aprobarAjustes(int conteoId, int usuarioId) async {
    final est = await _estadoConteo(conteoId);
    if (est == EstadoConteo.aprobado) {
      throw StateError('Este conteo ya fue aprobado.');
    }

    final difs = await listarDiferencias(conteoId);
    if (difs.isEmpty) {
      throw StateError('No hay líneas de conteo para aprobar.');
    }

    await _db.transaction(() async {
      final ahora = DateTime.now().millisecondsSinceEpoch;

      for (final d in difs) {
        if (d.estado == 'aprobado') continue;

        final saldoAnterior = d.stockSistema;
        final saldoNuevo = d.stockFisico;
        final cantidad = (saldoNuevo - saldoAnterior).abs();

        // 1) Stock
        await (_db.update(_db.productosTable)
              ..where((t) => t.id.equals(d.productoId)))
            .write(ProductosTableCompanion(stock: Value(saldoNuevo)));

        // 2) Kardex (ajuste)
        double costo = 0.0;
        final prod = await (_db.select(
          _db.productosTable,
        )..where((t) => t.id.equals(d.productoId))).getSingleOrNull();
        if (prod != null) {
          costo = prod.precioCompra ?? 0.0;
        }

        await _db
            .into(_db.kardexTable)
            .insert(
              KardexTableCompanion(
                productoId: Value(d.productoId),
                tipoMovimiento: const Value('ajuste'),
                cantidad: Value(cantidad),
                saldoAnterior: Value(saldoAnterior),
                saldoNuevo: Value(saldoNuevo),
                costoUnitario: Value(costo),
                totalMovimiento: Value(costo * cantidad),
                fechaMovimiento: Value(ahora),
                documentoReferencia: Value('CONTEO-$conteoId'),
                observacion: Value(
                  'Conteo físico #${d.conteoId}: '
                  '${d.nombreProducto} '
                  '(${saldoAnterior.toStringAsFixed(2)} → '
                  '${saldoNuevo.toStringAsFixed(2)})',
                ),
                usuarioId: Value(usuarioId),
                motivo: const Value('Inventario físico'),
                referenciaId: Value(conteoId),
              ),
            );

        // 3) Lista de ajustes (auditoría)
        if (d.diferencia != 0) {
          final tipo = d.diferencia > 0 ? 'entrada' : 'salida';
          await _db
              .into(_db.ajusteInventarioTable)
              .insert(
                AjusteInventarioTableCompanion.insert(
                  productoId: d.productoId,
                  tipoAjuste: tipo,
                  cantidad: d.diferencia.abs(),
                  motivo: 'Conteo físico #$conteoId',
                  observaciones: const Value(
                    '\${d.nombreProducto}: '
                    '\${d.stockSistema.toStringAsFixed(2)} → '
                    '\${d.stockFisico.toStringAsFixed(2)}',
                  ),
                  usuarioId: usuarioId,
                  fechaCreacion: ahora,
                ),
              );
        }

        // 4) Línea aprobada
        await (_db.update(_db.diferenciasConteo)
              ..where((t) => t.id.equals(d.id)))
            .write(const DiferenciasConteoCompanion(estado: Value('aprobado')));
      }

      await (_db.update(
        _db.conteosFisicos,
      )..where((t) => t.id.equals(conteoId))).write(
        ConteosFisicosCompanion(estado: Value(EstadoConteo.aprobado.name)),
      );
    });
  }

  @override
  Future<Uint8List> generarReporte(int conteoId) async {
    final conteos = await listarConteos();
    final cab = conteos.where((c) => c.id == conteoId).firstOrNull;
    final difs = await listarDiferencias(conteoId);

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          pw.Text(
            'REPORTE CONTEO FÍSICO #$conteoId',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          if (cab != null) ...[
            pw.Text('Nombre: ${cab.nombreConteo}'),
            pw.Text('Estado: ${cab.estado.etiqueta}'),
            pw.Text('Fecha: ${cab.fechaConteo}'),
            if (cab.observaciones != null && cab.observaciones!.isNotEmpty)
              pw.Text('Obs: ${cab.observaciones}'),
          ],
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Código',
              'Producto',
              'Sistema',
              'Físico',
              'Dif',
              'Estado',
            ],
            data: [
              for (final d in difs)
                [
                  d.codigoProducto,
                  d.nombreProducto,
                  d.stockSistema.toStringAsFixed(2),
                  d.stockFisico.toStringAsFixed(2),
                  d.diferencia.toStringAsFixed(2),
                  d.estado,
                ],
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
          ),
          pw.SizedBox(height: 12),
          pw.Text('Total líneas: ${difs.length}'),
          pw.Text(
            'Con diferencia: ${difs.where((d) => d.diferencia != 0).length}',
          ),
        ],
      ),
    );
    return doc.save();
  }
}
