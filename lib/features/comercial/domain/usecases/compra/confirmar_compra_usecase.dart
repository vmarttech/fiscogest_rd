import 'package:fiscogest_rd/core/eventos/evento_bus.dart';
import 'package:fiscogest_rd/core/eventos/eventos_sistema.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_compra_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/calcular_costo_adquisicion.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/ejecutar_actualizaciones_comerciales.dart';
import 'package:fiscogest_rd/features/inventario/domain/enums/tipo_movimiento.dart';
import 'package:fiscogest_rd/features/inventario/domain/usecases/registrar_movimiento_kardex.dart';

class ConfirmarCompraUseCase {
  ConfirmarCompraUseCase({
    required ICompraRepository compraRepository,
    required EjecutarActualizacionesComerciales ejecutarActualizaciones,
    required RegistrarMovimientoKardex registrarMovimientoKardex,
    required CalcularCostoAdquisicion calcularCostoAdquisicion,
  }) : _compraRepository = compraRepository,
       _ejecutarActualizaciones = ejecutarActualizaciones,
       _registrarMovimientoKardex = registrarMovimientoKardex,
       _calcularCostoAdquisicion = calcularCostoAdquisicion;

  final ICompraRepository _compraRepository;
  final EjecutarActualizacionesComerciales _ejecutarActualizaciones;
  final RegistrarMovimientoKardex _registrarMovimientoKardex;
  final CalcularCostoAdquisicion _calcularCostoAdquisicion;

  Future<Compra> call(int compraId) async {
    final compra = await _compraRepository.obtenerCompraPorId(compraId);
    if (compra == null) throw StateError('Compra no encontrada: $compraId');

    final lineasDetalle = await _compraRepository.listarDetallesDeCompra(compraId);
    final fechaCompra = compra.fechaConfirmacion ?? compra.fechaEmision;
    const usuarioId = 1;

    for (final linea in lineasDetalle) {
      final idProd = linea.productoId;
      if (idProd <= 0) continue;

      final costoAdquisicion = _calcularCostoAdquisicion(
        costoUnitario: linea.costoUnitario,
        fleteUnitario: linea.fleteUnitario,
        seguroUnitario: linea.seguroUnitario,
        arancelesUnitario: linea.arancelesUnitario,
        gastosUnitario: linea.gastosUnitario,
      );

      await _ejecutarActualizaciones.ejecutarCompra(
        idProducto: idProd,
        cantidad: linea.cantidad,
        costoUnitario: costoAdquisicion,
        proveedorId: compra.proveedorId,
        montoTotal: compra.totalCompra,
        fecha: compra.fechaEmision,
      );

      try {
        final totalMovimiento = linea.cantidad * costoAdquisicion;
        await _registrarMovimientoKardex.ejecutar(
          productoId: idProd,
          tipoMovimiento: TipoMovimiento.entrada,
          cantidad: linea.cantidad,
          saldoAnterior: 0.0,
          saldoNuevo: linea.cantidad,
          costoUnitario: costoAdquisicion,
          totalMovimiento: totalMovimiento,
          fechaMovimiento: fechaCompra,
          documentoReferencia: 'Compra #$compraId',
          observacion: 'Entrada por compra',
          usuarioId: usuarioId,
        );
      } catch (e) {
        throw Exception('Error al registrar movimiento para producto $idProd: $e');
      }
    }

    final compraConfirmada = await _compraRepository.confirmarCompra(compraId);

    EventoBus.emitir(EventosSistema.compraConfirmada, {'compraId': compraId});
    return compraConfirmada;
  }
}
