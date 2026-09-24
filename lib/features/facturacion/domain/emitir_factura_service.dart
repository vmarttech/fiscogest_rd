import 'package:fiscogest_rd/features/facturacion/data/dao/secuencias_ncf_dao.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';
import 'package:fiscogest_rd/features/ventas/data/repositories/ventas_repository_impl.dart';

class EmitirFacturaService {
  EmitirFacturaService({
    required this.ventasRepo,
    required this.secuenciasDao,
  });

  final VentasRepositoryImpl ventasRepo;
  final SecuenciasNcfDao secuenciasDao;

  static String tipoNcfSugerido({
    required bool consumidorFinal,
    String rncCliente = '',
  }) {
    if (consumidorFinal) return 'B02';
    if (rncCliente.trim().isEmpty) return 'B02';
    final rnc = rncCliente.trim();
    final esRnc = rnc.length == 9 && RegExp(r'^\d+$').hasMatch(rnc);
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
    if (ncfActual.isNotEmpty) {
      throw StateError('Ya tiene NCF: $ncfActual');
    }
    final est = venta.estadoDocumento;
    if (est != EstadoDocumento.cotizado && est != EstadoDocumento.aprobado) {
      throw StateError('Estado no válido para facturar: ${est.name}');
    }
    if (tipoNcf != 'B01' && tipoNcf != 'B02') {
      throw StateError('Tipo NCF no soportado: $tipoNcf');
    }
    if (tipoNcf == 'B01') {
      final rnc = rncCliente.trim();
      final okRnc = rnc.length == 9 && RegExp(r'^\d+$').hasMatch(rnc);
      if (!okRnc) {
        throw StateError(
          'B01 (crédito fiscal) requiere RNC de 9 dígitos del cliente',
        );
      }
    }

    final ncf = await secuenciasDao.siguienteNcf(tipoNcf);
    await ventasRepo.emitirNcfFiscal(ventaId, ncf);
    return ncf;
  }
}
