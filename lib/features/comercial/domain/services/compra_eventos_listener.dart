import 'package:fiscogest_rd/core/eventos/evento_bus.dart';
import 'package:fiscogest_rd/core/eventos/eventos_sistema.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_compra_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_inventario_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_producto_repository.dart';
import 'package:fiscogest_rd/features/proveedores/domain/repositories/i_proveedor_repository.dart';

class CompraEventosListener {
  CompraEventosListener(
    this.compraRepository,
    this.inventarioRepository,
    this.productoRepository,
    this.proveedorRepository,
  ) {
    _registrarEscuchas();
  }

  final ICompraRepository compraRepository;
  final IInventarioRepository inventarioRepository;
  final IProductoRepository productoRepository;
  final IProveedorRepository proveedorRepository;

  void _registrarEscuchas() {
    EventoBus.escuchar(EventosSistema.compraConfirmada, _alConfirmarCompra);
  }

  Future<void> _alConfirmarCompra(Map<String, dynamic> datos) async {
    final dynamic compraIdRaw = datos['compraId'];
    final String texto = compraIdRaw.toString();
    final soloDigitos = texto.replaceAll(RegExp(r'[^0-9]'), '');
    final compraId = int.tryParse(soloDigitos) ?? 0;

    if (compraId == 0) {
      throw FormatException(
        'No se pudo extraer identificador numérico desde: $texto',
      );
    }

    final compra = await compraRepository.obtenerCompraPorId(compraId);
    if (compra == null) return;

    final detalles = await compraRepository.listarDetallesDeCompra(compraId);
    for (final linea in detalles) {
      await inventarioRepository.aumentarExistencias(
        productoId: linea.productoId,
        cantidad: linea.cantidad,
      );
      await productoRepository.actualizarCostoProducto(
        productoId: linea.productoId,
        costoUnitario: linea.costoUnitario,
        cantidadAnterior: 0,
        cantidadMovimiento: linea.cantidad,
      );
    }

    await proveedorRepository.registrarCompraProveedor(
      proveedorId: compra.proveedorId,
      monto: compra.totalCompra,
    );
  }

  void dispose() {
    EventoBus.dejarDeEscuchar(
      EventosSistema.compraConfirmada,
      _alConfirmarCompra,
    );
  }
}
