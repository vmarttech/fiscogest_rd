/// Control de flujo interno de vistas dentro del contenedor único de ventas
/// Alineado con Diseño Nuevo: Vacío → Inventario → Detalle
enum VistaActual {
  inicio,
  inventario,
  detalle,
}

/// Modo de operación comercial. MISMA interfaz, DIFERENTE comportamiento al guardar
/// Alineado con Fase 4: Ventas / Cotizaciones / Apartados
enum ModoOperacion {
  venta,
  cotizacion,
  apartado,
}

/// Categoría de productos para filtro en barra inferior fija
enum CategoriaProducto {
  productos,
  manufactura,
  servicios,
  scanner,
}
