enum FormaPago { Efectivo, Tarjeta, Transferencia, Credito, Cheque }
enum VentaEstado { Borrador, Confirmada, Anulada }
enum CotizacionEstado { Pendiente, Aceptada, Rechazada, Vencida, Convertida }
enum ApartadoEstado { Reservado, Parcial, Pagado, Vencido, Cancelado, Convertido }
enum DevolucionTipo { Parcial, Total }
enum DevolucionEstado { Registrada, Procesada, Rechazada }
enum CobrarEstado { Pendiente, Parcial, Pagado, Vencido }
enum PagarEstado { Pendiente, Parcial, Pagado, Vencido }
enum TipoGasto { Compra, Servicio, Impuesto, Nomina, Otro }
enum DescuentoTipo { Porcentaje, Monto }
enum AplicaA { Todo, Categoria, Producto, Cliente }
enum RegistroEstado { Vigente, Vencido, Inactivo }
enum MovimientoInventario { Entrada, Salida, Ajuste, Devolucion }
enum ReferenciaTipo { Compra, Venta, Ajuste, Devolucion, Apartado, Cobro, Pago }
enum MovimientoCaja { INGRESO, EGRESO }
