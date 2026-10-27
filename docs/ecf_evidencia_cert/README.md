# Evidencia e-CF para certificación DGII

Generado: 2026-10-26T22:36:11

## Qué guardar por cada prueba

Por cada caso (E32 RFCE, E32 completo, E31, E34):

1. `NN_caso_xml_sin_firma.xml` — XML generado (validado XSD)
2. `NN_caso_xml_firmado.xml` — XML firmado enviado
3. `NN_caso_recepcion.json` — status HTTP + body (TrackId / estado RFCE)
4. `NN_caso_consulta.json` — consulta por TrackId (estado final)
5. Notas: ambiente (testecf|certecf), RNC, eNCF, fecha/hora

## Casos mínimos

| # | Caso | Archivo prefijo |
|---|------|-----------------|
| 01 | E32 consumo < 250k (RFCE) | 01_e32_rfce |
| 02 | E32 consumo ≥ 250k (completo) | 02_e32_completo |
| 03 | E31 crédito fiscal | 03_e31 |
| 04 | E34 nota de crédito | 04_e34 |
| 05 | Reenvío con TrackId existente (no duplicar) | 05_antDobles |

## Criterio de cierre técnico

- Al menos un XML firmado con estado DGII **Aceptado** o **Aceptado Condicional**
- RFCE y e-CF completo probados si el negocio usa ambos
- XSD oficial en uso (`exigirXsd` en cert)
- Certificado PSC vigente del RNC emisor
