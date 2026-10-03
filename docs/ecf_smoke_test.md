# Smoke test e-CF — TesteCF (30 a 45 min)

## Precondiciones

- Ambiente Precertificación
- Módulo habilitado, RNC y razón de prueba, certificado .p12 y clave
- Secuencias 31, 32 y 34 con rango válido
- XSD configurado (recomendado)
- Internet hacia los servicios e-CF DGII del ambiente

## Lista de verificación

1. Guardar Config y abrir Cola — sin error; aviso de cert solo si aplica
2. Venta crédito fiscal encola e-CF — documento visible en cola
3. Generar XML — e-NCF E31 más 10 dígitos
4. Firmar — estado firmado y código de seguridad
5. Enviar a DGII — TrackId asignado
6. Enviar de nuevo — mensaje de ya enviado; no duplica
7. Consultar estado — aceptado, rechazado o en proceso
8. Imprimir RI (QR) — PDF con e-NCF, código y QR
9. Flujo tipo 32 — e-NCF E32...
10. NC 34 con referencia — XML con comprobante modificado
11. Filtros de cola y refresh — coherente con estados
12. Anular documento no aceptado — estado anulado; no reenvía

Pase mínimo: pruebas 1 a 8 y 11.

## Evidencia a guardar

- TrackId de un envío aceptado
- Una RI de prueba
- Notas de rechazos y cómo se resolvieron
