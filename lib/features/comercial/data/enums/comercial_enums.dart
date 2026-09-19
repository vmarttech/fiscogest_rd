enum FormaPago { efectivo, tarjeta, transferencia, credito, cheque }

enum VentaEstado { borrador, confirmada, anulada }

enum CotizacionEstado { pendiente, aceptada, rechazada, vencida, convertida }

enum ApartadoEstado {
  reservado,
  parcial,
  pagado,
  vencido,
  cancelado,
  convertido,
}

enum DevolucionTipo { parcial, total }

enum DevolucionEstado { registrada, procesada, rechazada }

enum CobrarEstado { pendiente, parcial, pagado, vencido }

enum PagarEstado { pendiente, parcial, pagado, vencido }

enum EstadoCompra {
  borrador,
  registrada,
  confirmada,
  recibida,
  pagada,
  vencida,
  anulada,
}

enum TipoGasto { compra, servicio, impuesto, nomina, otro }

enum DescuentoTipo { porcentaje, monto }

enum AplicaA { todo, categoria, producto, cliente }

enum RegistroEstado { vigente, vencido, inactivo }

enum MovimientoInventario { entrada, salida, ajuste, devolucion }

enum ReferenciaTipo { compra, venta, ajuste, devolucion, apartado, cobro, pago }

enum MovimientoCaja { ingreso, egreso }
