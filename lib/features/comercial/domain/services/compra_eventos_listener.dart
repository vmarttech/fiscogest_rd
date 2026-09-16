import 'package:fiscogest_rd/core/eventos/evento_bus.dart';
import 'package:fiscogest_rd/core/eventos/eventos_sistema.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_compra_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_inventario_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_producto_repository.dart';
import 'package:fiscogest_rd/features/inventario/domain/enums/tipo_movimiento.dart';
import 'package:fiscogest_rd/features/inventario/domain/usecases/registrar_movimiento_kardex.dart';
import 'package:fiscogest_rd/features/proveedores/domain/repositories/i_proveedor_repository.dart';

class CompraEventosListener {
  CompraEventosListener(
    this.compraRepository,
    this.inventarioRepository,
    this.productoRepository,
    this.registrarMovimientoKardex,
    this.proveedorRepository,
  ) {
    _registrarEscuchas();
  }

  final ICompraRepository compraRepository;
  final IInventarioRepository inventarioRepository;
  final IProductoRepository productoRepository;
  final RegistrarMovimientoKardex registrarMovimientoKardex;
  final IProveedorRepository proveedorRepository;

  void _registrarEscuchas() {
    EventoBus.escuchar(EventosSistema.compraConfirmada, _alConfirmarCompra);
  }

  Future<void> _alConfirmarCompra(Map<String, dynamic> datos) async {
    try {
      final dynamic compraIdRaw = datos['compraId'];
      final texto = compraIdRaw.toString();
      final soloDigitos = texto.replaceAll(RegExp(r'[^0-9]'), '');
      final compraId = int.tryParse(soloDigitos) ?? 0;

      if (compraId == 0) return;

      final compra = await compraRepository.obtenerCompraPorId(compraId);
      if (compra == null) return;

      final detalles = await compraRepository.listarDetallesDeCompra(compraId);
      final fechaCompra = compra.fechaConfirmacion ?? compra.fechaEmision;
      final documento = 'Compra #$compraId';
      const usuarioId = 1;

      for (final linea in detalles) {
        try {
          final cantidadAnterior = await inventarioRepository.obtenerStockActual(linea.productoId) ?? 0.0;
          final cantidadNueva = cantidadAnterior + linea.cantidad;

          await inventarioRepository.aumentarExistencias(
            productoId: linea.productoId,
            cantidad: linea.cantidad,
          );

          await productoRepository.actualizarCostoProducto(
            productoId: linea.productoId,
            costoUnitario: linea.costoUnitario,
            cantidadAnterior: cantidadAnterior,
            cantidadMovimiento: linea.cantidad,
          );

          await registrarMovimientoKardex.ejecutar(
            productoId: linea.productoId,
            tipoMovimiento: TipoMovimiento.entrada,
            cantidad: linea.cantidad,
            saldoAnterior: cantidadAnterior,
            saldoNuevo: cantidadNueva,
            costoUnitario: linea.costoUnitario,
            totalMovimiento: linea.cantidad * linea.costoUnitario,
            fechaMovimiento: fechaCompra,
            documentoReferencia: documento,
            observacion: 'Entrada por compra',
            usuarioId: usuarioId,
          );
        } catch (e) {
          throw Exception('Error procesando producto ${linea.productoId}: $e');
        }
      }

      await proveedorRepository.registrarCompraProveedor(
        proveedorId: compra.proveedorId,
        monto: compra.totalCompra,
      );
    } catch (e) {
      throw Exception('Error en procesamiento de compra: $e');
    }
  }

  void dispose() {
    EventoBus.dejarDeEscuchar(EventosSistema.compraConfirmada, _alConfirmarCompra);
  }
}
