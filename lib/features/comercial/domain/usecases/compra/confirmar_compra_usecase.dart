import 'package:fiscogest_rd/core/eventos/evento_bus.dart';
import 'package:fiscogest_rd/core/eventos/eventos_sistema.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_compra_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/ejecutar_actualizaciones_comerciales.dart';
import 'package:fiscogest_rd/features/inventario/domain/enums/tipo_movimiento.dart';
import 'package:fiscogest_rd/features/inventario/domain/usecases/registrar_movimiento_kardex.dart';

class ConfirmarCompraUseCase {
  ConfirmarCompraUseCase({
    required ICompraRepository compraRepository,
    required EjecutarActualizacionesComerciales ejecutarActualizaciones,
    required RegistrarMovimientoKardex registrarMovimientoKardex,
  }) : _compraRepository = compraRepository,
       _ejecutarActualizaciones = ejecutarActualizaciones,
       _registrarMovimientoKardex = registrarMovimientoKardex;

  final ICompraRepository _compraRepository;
  final EjecutarActualizacionesComerciales _ejecutarActualizaciones;
  final RegistrarMovimientoKardex _registrarMovimientoKardex;

  Future<Compra> call(int compraId) async {
    print('🔵 Confirmando compraId=$compraId');

    final compra = await _compraRepository.obtenerCompraPorId(compraId);
    if (compra == null) throw StateError('Compra no encontrada: $compraId');

    final lineasDetalle = await _compraRepository.listarDetallesDeCompra(compraId);
    print('🔵 Líneas a procesar: ${lineasDetalle.length}');

    final fechaCompra = compra.fechaConfirmacion ?? compra.fechaEmision;
    const usuarioId = 1;

    for (final linea in lineasDetalle) {
      final idProd = linea.productoId;
      if (idProd <= 0) continue;

      // ✅ Actualiza existencias y costos
      await _ejecutarActualizaciones.ejecutarCompra(
        idProducto: idProd,
        cantidad: linea.cantidad,
        costoUnitario: linea.costoUnitario,
        proveedorId: compra.proveedorId,
        montoTotal: compra.totalCompra,
        fecha: compra.fechaEmision,
      );

      // ✅ REGISTRAMOS KARDEX usando el CASO DE USO que ya existe
      try {
        print('🔵 Kardex prod=$idProd: cant=${linea.cantidad}, costo=${linea.costoUnitario}');

        await _registrarMovimientoKardex.ejecutar(
          productoId: idProd,
          tipoMovimiento: TipoMovimiento.entrada,
          cantidad: linea.cantidad,
          saldoAnterior: 0.0, // ⚠️ Lo corregimos luego, por ahora pasa
          saldoNuevo: linea.cantidad,
          costoUnitario: linea.costoUnitario,
          totalMovimiento: linea.cantidad * linea.costoUnitario,
          fechaMovimiento: fechaCompra,
          documentoReferencia: 'Compra #$compraId',
          observacion: 'Entrada por compra',
          usuarioId: usuarioId,
        );
        print('✅ Kardex registrado prod=$idProd');
      } catch (e) {
        print('❌ ERROR Kardex prod=$idProd: $e');
      }
    }

    final compraConfirmada = await _compraRepository.confirmarCompra(compraId);
    EventoBus.emitir(EventosSistema.compraConfirmada, {'compraId': compraId});
    print('✅ Compra confirmada y Kardex procesado');

    return compraConfirmada;
  }
}
