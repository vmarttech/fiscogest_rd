# Etapa 10 · Pruebas integrales FiscoGest Gastronomía RD

> Perfil: negocio pequeño sin web. Catálogo web / pedidos en línea: **fuera de alcance**.
> Cerrar cada casilla en dispositivo real (Android). Marcar [x] solo tras prueba manual.

## 0. Precondiciones
- [ ] 0.1 `dart analyze lib/features/gastronomia` sin errores (info toleradas, pero que no crezcan).
- [ ] 0.2 Caja con sesión abierta antes de vender.
- [ ] 0.3 Plan con `permiteGastronomia` (básico en adelante); demo también prueba.
- [ ] 0.4 Al menos 1 sector con tarifa y 1 umbral de envío gratis; 1 repartidor activo.

## 1. Catálogo gastronómico (sección 2-A del alcance)
- [ ] 1.1 Activar producto como gastronómico y ver foto local (cámara/galería).
- [ ] 1.2 Categoría con meta visible en menú; ocultar categoría y desaparece del menú.
- [ ] 1.3 Producto destacado aparece primero en Venta Rápida.
- [ ] 1.4 Búsqueda rápida por nombre filtra el menú.
- [ ] 1.5 Extra global y extra por producto; suma precio en carrito y ticket.
- [ ] 1.6 Desactivar disponibilidad (`disponibleMenu`) y el producto no se vende.
- [ ] 1.7 Compartir menú por texto/WhatsApp (sustituto del catálogo web).

## 2. Venta rápida (prioridad máxima, sección 2-B)
- [ ] 2.1 Selección por foto/nombre; carrito con cantidad y extras.
- [ ] 2.2 Total = subtotal − descuento + ITBIS 18%; descuento no excede subtotal.
- [ ] 2.3 Formas de pago: efectivo / tarjeta / transferencia reflejadas en caja.
- [ ] 2.4 Se crea venta comercial + movimiento de caja (ingreso referenciado a la venta).
- [ ] 2.5 H4: el stock del producto baja y queda movimiento en kárdex (salida).
- [ ] 2.6 Producto sin stock no se puede vender (o avisa) — verificar regla del módulo tradicional.
- [ ] 2.7 Ticket PDF 80 mm generado y compartido; fallback de texto si falla el PDF.
- [ ] 2.8 Botón WhatsApp/menú funciona; pedido local queda con `ventaId` vinculado.

## 3. Delivery por barrios (sección 2-C)
- [ ] 3.1 Pedido por teléfono/WhatsApp/presencial con nombre, teléfono, sector y referencia.
- [ ] 3.2 Tarifa de sector aplicada al total; ITBIS solo sobre productos.
- [ ] 3.3 H1: compra ≥ `montoMinimoEnvioGratis` del sector → costo de envío RD$0.00.
- [ ] 3.4 Compra menor al umbral → tarifa normal cobrada.
- [ ] 3.5 Asignar repartidor → estado `en_camino`; botón WhatsApp al cliente.
- [ ] 3.6 Flujo de estados: pendiente → en_camino → entregado.
- [ ] 3.7 H2: botón Cobrar en pedido pendiente de cobro crea venta, mueve caja y vincula `ventaId`.
- [ ] 3.8 No se puede cobrar dos veces el mismo pedido (mensaje de vinculado).
- [ ] 3.9 H3: sección Efectivo por repartidor muestra entregados/cobrados/pendientes.
- [ ] 3.10 Repartidor con pendiente muestra aviso; al cobrar desaparece.

## 4. Sync, offline y licencias (secciones 5–6)
- [ ] 4.1 Cada pedido nuevo lleva UUID único; no se duplica en push.
- [ ] 4.2 Payloads con `negocio_id` + `id_local`; `GastronomiaSync` ≠ `PedidoSync` de licencias.
- [ ] 4.3 Offline: vender y crear pedidos sin red; al volver a red, `pushPendientes` sube filas.
- [ ] 4.4 Fotos no se guardan en SQLite: ruta local / clave remota en meta aparte.
- [ ] 4.5 Gates: plan gratis sin módulo; básico = venta visual; simplificado/pro = delivery.
- [ ] 4.6 No se crean productos/clientes/ventas duplicados: meta gastro separada.

## 5. Regresión del módulo tradicional (no debe cambiar)
- [ ] 5.1 Venta de mostrador tradicional factura normal.
- [ ] 5.2 Caja: apertura/cierre y movimientos coinciden con ventas.
- [ ] 5.3 Fiao/abonos y crédito siguen igual.
- [ ] 5.4 Kárdex e inventario global no se corrompen por ventas gastro.
- [ ] 5.5 Sincronización de ventas, clientes y productos tradicionales intacta.

## 6. Cierre del documento de alcance
- [ ] 6.1 Etapas 1–7 y 9 verificadas contra este checklist.
- [ ] 6.2 Etapa 8 (catálogo web) marcada explícitamente como fuera de alcance.
- [ ] 6.3 Etapa 10 completa con evidencia (capturas o anotaciones por caso).
