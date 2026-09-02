import 'package:fiscogest_rd/core/domain/eventos/evento_negocio.dart';
import 'package:fiscogest_rd/core/domain/eventos/recepcion_eventos.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/recepcion_repository_impl.dart';
import 'package:fiscogest_rd/features/inventario/data/repositories/kardex_repository_impl.dart';
import 'package:fiscogest_rd/features/inventario/data/datasources/drift_kardex_datasource.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/kardex.dart';
import 'package:fiscogest_rd/features/inventario/domain/enums/tipo_movimiento.dart';
import 'package:logger/logger.dart';

class SincronizacionService {
  SincronizacionService._interno();

  static final SincronizacionService instancia =
      SincronizacionService._interno();
  static final Logger _logger = Logger();

  void disparar(EventoNegocio evento) {
    if (evento is RecepcionConfirmada) {
      _alConfirmarRecepcion(evento);
    }
  }

  void _alConfirmarRecepcion(RecepcionConfirmada evento) {
    _actualizarInventarioPorRecepcion(evento.recepcionId);
    _actualizarCostos(evento.compraId);
    _actualizarEstadisticas(evento.tipo, evento.fecha);
    _actualizarReportes(evento.tipo, evento.fecha);
  }

  Future<void> _actualizarInventarioPorRecepcion(int recepcionId) async {
    try {
      final repo = RecepcionRepositoryImpl();
      final recepcion = await repo.obtenerPorId(recepcionId);

      if (recepcion?.detalles != null && recepcion!.detalles!.isNotEmpty) {
        final kardexRepo = KardexRepositoryImpl(
          DriftKardexDatasource(AppDatabase()),
        );

        for (final detalle in recepcion.detalles!) {
          if (detalle.productoId != null &&
              detalle.cantidadRecibida != null &&
              detalle.cantidadRecibida! > 0) {
            // Obtener saldo actual del producto
            final saldoActual = await kardexRepo.obtenerSaldoActual(
              detalle.productoId!,
            );

            // Cantidad recibida como double
            final cantidadDouble = detalle.cantidadRecibida!.toDouble();

            // Valores seguros con respaldo
            final costoSeguro = detalle.costoUnitario ?? 0.0;
            final nombreSeguro = detalle.productoNombre ?? 'Desconocido';

            // Calcular nuevo saldo
            final nuevoSaldo = saldoActual + cantidadDouble;

            // Registrar movimiento en kardex
            await kardexRepo.registrarMovimiento(
              Kardex(
                productoId: detalle.productoId!,
                tipoMovimiento: TipoMovimiento.entrada,
                cantidad: cantidadDouble,
                saldoAnterior: saldoActual,
                saldoNuevo: nuevoSaldo,
                costoUnitario: costoSeguro,
                totalMovimiento: costoSeguro * cantidadDouble,
                fechaMovimiento: DateTime.now(),
                documentoReferencia: recepcionId.toString(),
                observacion: 'Recepción confirmada - Producto: $nombreSeguro',
                usuarioId:
                    int.tryParse(recepcion.usuarioResponsable ?? '') ?? 0,
              ),
            );
          }
        }
      }
    } catch (e) {
      _logger.e('Error actualizando inventario por recepción $recepcionId: $e');
    }
  }

  Future<void> _actualizarCostos(int? documentoId) async {
    try {
      if (documentoId == null) return;
      _logger.i('Actualizando costos para documento $documentoId');
    } catch (e) {
      _logger.e('Error actualizando costos para documento $documentoId: $e');
    }
  }

  Future<void> _actualizarEstadisticas(
    String tipoEvento,
    DateTime fecha,
  ) async {
    try {
      _logger.i('Actualizando estadísticas para evento $tipoEvento en $fecha');
    } catch (e) {
      _logger.e('Error actualizando estadísticas para evento $tipoEvento: $e');
    }
  }

  Future<void> _actualizarReportes(String tipoEvento, DateTime fecha) async {
    try {
      _logger.i('Actualizando reportes para evento $tipoEvento en $fecha');
    } catch (e) {
      _logger.e('Error actualizando reportes para evento $tipoEvento: $e');
    }
  }
}
