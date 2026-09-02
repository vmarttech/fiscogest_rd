/// Tipo de descuento aplicable
enum TipoDescuento { porProducto, porFactura }

/// Estado de autorización del descuento
enum EstadoAutorizacion { autorizado, requierePermiso, denegado }

/// Entidad que representa un descuento comercial
class Descuento {
  const Descuento({
    required this.id,
    required this.tipo,
    required this.valor,
    required this.motivo,
    required this.estadoAutorizacion,
    this.autorizadoPor,
    required this.fechaRegistro,
    this.fechaAutorizacion,
    this.productoId,
    this.esPorcentaje = false,
    this.activo = true,
  });

  final int id;
  final TipoDescuento tipo;
  final double valor;
  final String motivo;
  final EstadoAutorizacion estadoAutorizacion;
  final String? autorizadoPor;
  final DateTime fechaRegistro;
  final DateTime? fechaAutorizacion;
  final int? productoId;
  final bool esPorcentaje;
  final bool activo;
}
