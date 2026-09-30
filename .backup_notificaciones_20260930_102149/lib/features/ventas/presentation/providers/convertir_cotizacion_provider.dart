import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';
import 'package:fiscogest_rd/features/ventas/domain/usecases/convertir_cotizacion_a_venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final convertirCotizacionAVentaProvider = Provider<ConvertirCotizacionAVenta>((ref) {
  final IVentasRepository repositorio = ref.watch(ventasRepositoryProvider);
  return ConvertirCotizacionAVenta(repositorio);
});

final cotizacionAprobacionProvider = Provider<CotizacionAprobacionServicio>((ref) {
  final repositorio = ref.watch(ventasRepositoryProvider);
  return CotizacionAprobacionServicio(repositorio);
});

class CotizacionAprobacionServicio {
  CotizacionAprobacionServicio(this._repositorio);
  final IVentasRepository _repositorio;

  Future<void> enviarAprobacion(int cotizacionId) async {
    await _repositorio.cambiarEstadoDocumento(
      cotizacionId,
      EstadoDocumento.enCredito,
    );
  }

  Future<void> aprobarCredito(int cotizacionId) async {
    await _repositorio.cambiarEstadoDocumento(
      cotizacionId,
      EstadoDocumento.aprobado,
    );
  }

  Future<void> rechazarCredito(int cotizacionId) async {
    await _repositorio.cambiarEstadoDocumento(
      cotizacionId,
      EstadoDocumento.anulado,
    );
  }
}
