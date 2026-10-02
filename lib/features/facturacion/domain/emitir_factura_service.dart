import 'package:fiscogest_rd/features/facturacion/data/dao/secuencias_ncf_dao.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';
import 'package:fiscogest_rd/features/ventas/data/repositories/ventas_repository_impl.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';

/// Callback opcional post-NCF. Debe ser a prueba de fallos (el caller también lo envuelve).
typedef EcfePostEmisionHook = Future<void> Function({
  required Venta venta,
  required String tipoNcf,
  required String rncCliente,
});

class EmitirFacturaService {
  EmitirFacturaService({
    required this.ventasRepo,
    required this.secuenciasDao,
    this.onPostEmision,
  });

  final VentasRepositoryImpl ventasRepo;
  final SecuenciasNcfDao secuenciasDao;
  final EcfePostEmisionHook? onPostEmision;

  static String tipoNcfSugerido({
    required bool consumidorFinal,
    String rncCliente = '',
  }) {
    if (consumidorFinal) return 'B02';
    if (rncCliente.trim().isEmpty) return 'B02';
    final rnc = rncCliente.trim();
    final esRnc =
        (rnc.length == 9 || rnc.length == 11) && RegExp(r'^\d+$').hasMatch(rnc);
    return esRnc ? 'B01' : 'B02';
  }

  Future<String> emitir({
    required int ventaId,
    required String tipoNcf,
    String rncCliente = '',
  }) async {
    final venta = await ventasRepo.obtenerVentaPorId(ventaId);
    if (venta == null) {
      throw StateError('Documento no encontrado');
    }
    final ncfActual = (venta.numeroFactura ?? '').trim();
    final yaFiscal = ncfActual.startsWith('B01') || ncfActual.startsWith('B02');
    if (yaFiscal) {
      throw StateError('Ya tiene NCF fiscal: $ncfActual');
    }
    final est = venta.estadoDocumento;
    final okEstado =
        est == EstadoDocumento.cotizado ||
        est == EstadoDocumento.aprobado ||
        est == EstadoDocumento.facturado ||
        est == EstadoDocumento.enCredito;
    if (!okEstado) {
      throw StateError('Estado no válido para facturar: ${est.name}');
    }
    if (tipoNcf != 'B01' && tipoNcf != 'B02') {
      throw StateError('Tipo NCF no soportado: $tipoNcf');
    }
    if (tipoNcf == 'B01') {
      final rnc = rncCliente.trim();
      final okRnc =
          (rnc.length == 9 || rnc.length == 11) &&
          RegExp(r'^\d+$').hasMatch(rnc);
      if (!okRnc) {
        throw StateError(
          'B01 (crédito fiscal) requiere RNC (9) o cédula (11 dígitos) del cliente',
        );
      }
    }
    final ncf = await secuenciasDao.siguienteNcf(tipoNcf);
    final ventaActualizada = await ventasRepo.emitirNcfFiscal(ventaId, ncf);

    // Hook e-CF: aislado; no puede invalidar la emisión local
    final hook = onPostEmision;
    if (hook != null) {
      try {
        await hook(
          venta: ventaActualizada,
          tipoNcf: tipoNcf,
          rncCliente: rncCliente,
        );
      } catch (_) {}
    }

    return ncf;
  }
}
