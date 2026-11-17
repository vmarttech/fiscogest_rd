
class ExtraGastronomico {
  ExtraGastronomico({required this.id, required this.nombre, required this.precio, this.activo = true});
  final int id; final String nombre; final double precio; final bool activo;
}

class SectorDelivery {
  SectorDelivery({required this.id, required this.nombre, required this.tarifaEnvio,
    this.montoMinimoEnvioGratis = 0, this.orden = 0, this.activo = true});
  final int id; final String nombre; final double tarifaEnvio;
  final double montoMinimoEnvioGratis; final int orden; final bool activo;
}

class Repartidor {
  Repartidor({required this.id, required this.nombre, this.telefono = '', this.activo = true});
  final int id; final String nombre; final String telefono; final bool activo;
}

class ProductoGastroMeta {
  ProductoGastroMeta({required this.productoId, this.fotoPath = '',
    this.esGastronomico = false, this.destacado = false, this.disponibleMenu = true,
    this.fotoRemotaKey, this.fotoSincronizado = false, this.fotoActualizadoEn});
  final int productoId; final String fotoPath; final bool esGastronomico;
  final bool destacado; final bool disponibleMenu;
  final String? fotoRemotaKey; final bool fotoSincronizado; final DateTime? fotoActualizadoEn;
}

class LineaCarritoGastro {
  LineaCarritoGastro({required this.productoId, required this.nombre,
    required this.precioUnitario, this.cantidad = 1, this.extras = const [], this.notas = ''});
  final int productoId; final String nombre; final double precioUnitario;
  double cantidad; final List<ExtraGastronomico> extras; String notas;
  double get precioExtras => extras.fold(0, (s, e) => s + e.precio);
  double get subtotal => (precioUnitario + precioExtras) * cantidad;
}

class PedidoGastronomia {
  PedidoGastronomia({this.id, this.tipo = 'local', this.estado = 'pendiente',
    this.clienteId, this.nombreCliente = 'Consumidor Final', this.telefono = '',
    this.sectorId, this.direccionReferencia = '', this.costoEnvio = 0, this.subtotal = 0,
    this.itbis = 0, this.descuento = 0, this.total = 0, this.formaPago = 'efectivo', this.propina = 0,
    this.ventaId, this.repartidorId, this.notas = '', this.usuarioId});
  final int? id; final String tipo; final String estado; final int? clienteId;
  final String nombreCliente; final String telefono; final int? sectorId;
  final String direccionReferencia; final double costoEnvio; final double subtotal;
  final double itbis; final double descuento; final double total; final String formaPago;
  final double propina;
  final int? ventaId; final int? repartidorId; final String notas; final int? usuarioId;
}

/// H3: resumen de efectivo de un repartidor (solo lectura, calculado desde pedidos).
class ResumenRepartidor {
  ResumenRepartidor({
    required this.id,
    required this.nombre,
    this.telefono = '',
    this.pedidosEntregados = 0,
    this.pedidosCobrados = 0,
    this.montoEntregado = 0,
    this.montoCobrado = 0,
    this.montoPendiente = 0,
  });
  final int id;
  final String nombre;
  final String telefono;
  final int pedidosEntregados;
  final int pedidosCobrados;
  final double montoEntregado;
  final double montoCobrado;
  final double montoPendiente;
}
