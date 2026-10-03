# Guía de uso — e-CF (FiscoGest)

Facturación electrónica ante la DGII sin cambiar el flujo de ventas ni de caja.
El cajero cobra como siempre; el módulo e-CF prepara, firma y envía el comprobante.

## 1. Quién usa qué

- **Cajero:** solo vende. Si el módulo está activo, la venta puede encolar un e-CF sola.
- **Administrador / contador:** configura, revisa la Cola, consulta estados, reimprime RI, anula internos.
- **Implementador:** primera activación, TesteCF, checklist y paso a producción.

Menú: **e-CF · DGII** (pestañas Cola, Configuración, Guía).

## 2. Configuración (una vez por ambiente)

1. Abra e-CF → Configuración.
2. Habilite el módulo.
3. Elija ambiente:
   - Precertificación = pruebas TesteCF
   - Certificación = proceso formal DGII
   - Producción = operación real (solo cuando proceda)
4. Complete RNC y razón social del emisor.
5. Indique la ruta del certificado .p12 / .pfx y la clave.
6. (Recomendado) Ruta al XSD oficial DGII.
7. Configure secuencias e-NCF (31, 32, 34, etc.): desde, hasta y vencimiento.
8. Guarde.

Avisos:

- Si el certificado vence en 30 días o menos, verá un aviso en Cola y en Configuración.
- En certificación y producción la validación XSD puede ser obligatoria.

## 3. Flujo diario

1. Se registra la venta en caja.
2. Se encola el documento e-CF (si aplica).
3. Generar XML (se asigna el e-NCF).
4. Firmar con el certificado.
5. Enviar a la DGII (se obtiene TrackId).
6. Consultar estado (Aceptado, Rechazado o En proceso).
7. Imprimir Representación Impresa (RI) con código de seguridad y QR.

### Desde la Cola

- Use filtros: Todos, Pendientes, Enviados, Errores, Aceptados.
- Cada tarjeta muestra el estado y la siguiente acción sugerida.
- Toque la tarjeta para abrir el detalle.
- Deslice hacia abajo para actualizar.

### Desde el detalle

- Generar / validar XML: borrador o validación fallida.
- Firmar: cuando el XML está listo.
- Enviar a DGII: cuando está firmado (o reintento si falló la red y no hay TrackId).
- Consultar estado DGII: cuando ya hay TrackId.
- Imprimir RI (QR): cuando hay e-NCF (ideal firmado o aceptado).
- e-NCF de referencia (NC): solo tipo 34.
- Anular e-CF (interno): solo si aún no está aceptado por DGII.

Anti doble envío: si ya hay TrackId, Enviar otra vez no crea un segundo envío; debe consultar el estado.

## 4. Nota de crédito electrónica (tipo 34)

1. Conozca el e-NCF del comprobante que se modifica.
2. En el detalle del e-CF 34 use "e-NCF de referencia (NC)" y guarde.
3. Luego: Generar XML → Firmar → Enviar → Consultar.
4. El XML incluirá el vínculo al comprobante modificado.

Sin referencia no se genera el XML 34.

## 5. Representación impresa (RI)

- Imprimir RI (QR) genera el PDF con datos comerciales, e-NCF, código de seguridad y QR.
- El código se guarda al firmar.
- Puede reimprimir; el código se mantiene estable para el mismo XML firmado.

## 6. Anulación

- Anular e-CF (interno) es control de FiscoGest: deja motivo y detiene el pipeline.
- No sustituye el trámite formal ante DGII si el comprobante ya fue aceptado.
- Documentos aceptados: use nota de crédito o el procedimiento normativo.

## 7. Si algo falla

- Error al firmar: revise ruta y clave del .p12; certificado no vencido.
- Error técnico al enviar: internet y ambiente; reintente Enviar si no hay TrackId.
- Ya estaba enviado: use Consultar estado.
- Rechazado DGII: lea el mensaje en detalle y eventos.
- Sin secuencia: configure rangos e-NCF del tipo.
- NC 34 sin referencia: cargue el e-NCF de referencia en el detalle.

Los eventos del detalle son la bitácora (generar, firmar, enviar, consultar, anular).

## 8. Pestaña Guía y Especificación

- La pestaña Guía resume el guión TesteCF y el checklist de adopción.
- Para marcar ítems por versión: icono de reglas del hub → Especificación y checklist.

## 9. Buenas prácticas

1. No pase a Producción sin pruebas aceptadas en TesteCF o certificación.
2. Renueve el certificado antes de que venza.
3. Guarde evidencia (TrackId, RI) de las pruebas.
4. No altere rangos e-NCF a mitad de operación sin coordinar con el contador.
5. La caja no debe esperar a la DGII: la cola y el detalle resuelven el electrónico después del cobro.
