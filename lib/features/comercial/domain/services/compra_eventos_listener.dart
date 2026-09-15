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
    print('✅ [LISTENER] Constructor llamado — registrando escucha');
    _registrarEscuchas();
  }

  final ICompraRepository compraRepository;
  final IInventarioRepository inventarioRepository;
  final IProductoRepository productoRepository;
  final RegistrarMovimientoKardex registrarMovimientoKardex;
  final IProveedorRepository proveedorRepository;

  void _registrarEscuchas() {
    EventoBus.escuchar(EventosSistema.compraConfirmada, _alConfirmarCompra);
    print('✅ [LISTENER] Escucha registrada para: ${EventosSistema.compraConfirmada}');
  }

  Future<void> _alConfirmarCompra(Map<String, dynamic> datos) async {
    print('📥 [LISTENER] EVENTO RECIBIDO! Datos: $datos');
    try {
      final dynamic compraIdRaw = datos['compraId'];
      final String texto = compraIdRaw.toString();
      final soloDigitos = texto.replaceAll(RegExp(r'[^0-9]'), '');
      final compraId = int.tryParse(soloDigitos) ?? 0;

      print('🔍 [LISTENER] compraId extraído: $compraId');

      if (compraId == 0) {
        print('❌ [LISTENER] compraId es 0 — saliendo');
        return;
      }

      final compra = await compraRepository.obtenerCompraPorId(compraId);
      if (compra == null) {
        print('❌ [LISTENER] Compra no encontrada en BD');
        return;
      }
      print('✅ [LISTENER] Compra cargada: proveedor=${compra.proveedorId}, total=${compra.totalCompra}');

      final detalles = await compraRepository.listarDetallesDeCompra(compraId);
      print('✅ [LISTENER] Detalles cargados: ${detalles.length} líneas');

      final fechaCompra = compra.fechaConfirmacion ?? compra.fechaEmision;
      final documento = 'Compra #$compraId';
      const usuarioId = 1;

      int contadorMovimientos = 0;
      for (final linea in detalles) {
        try {
          print('➡️ [LISTENER] Procesando producto ${linea.productoId}, cant=${linea.cantidad}, costo=${linea.costoUnitario}');

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

          // ✅ TODOS LOS PARÁMETROS CON NOMBRES EXACTOS
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

          contadorMovimientos++;
          print('✅ [LISTENER] KÁRDEX REGISTRADO prod=${linea.productoId}');
        } catch (e) {
          print('❌ [LISTENER] ERROR línea prod=${linea.productoId}: $e');
        }
      }

      print('✅ [LISTENER] TOTAL MOVIMIENTOS REGISTRADOS: $contadorMovimientos');

      await proveedorRepository.registrarCompraProveedor(
        proveedorId: compra.proveedorId,
        monto: compra.totalCompra,
      );
      print('✅ [LISTENER] Compra registrada al proveedor');

    } catch (e) {
      print('❌ [LISTENER] ERROR GENERAL: $e');
    }
  }

  void dispose() {
    EventoBus.dejarDeEscuchar(EventosSistema.compraConfirmada, _alConfirmarCompra);
  }
}
