/// Control de flujo interno de vistas dentro del contenedor único de ventas
enum VistaActual { inicio, inventario, detalle, historial }

/// Modo de operación comercial. MISMA interfaz, DIFERENTE comportamiento al guardar
enum ModoOperacion { venta, cotizacion, apartado, cobrar }

/// Categoría de productos para filtro en barra inferior fija
enum CategoriaProducto { productos, manufactura, servicios, scanner }
