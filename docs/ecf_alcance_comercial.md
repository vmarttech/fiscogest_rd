# Alcance comercial e-CF (FiscoGest RD)

Actualizado: 2026-10-26T23:06:31

Este documento define qué garantiza el **software** y qué queda del lado del
**contribuyente / proceso DGII**. Sirve para certificación y para venta:
si DGII niega, debe poder clasificarse la causa.

## 1. Rol del producto

| Capacidad | Incluido |
|-----------|----------|
| Emisor electrónico (generar, firmar, enviar, consultar) | Sí |
| RFCE (E32 < RD$250,000) | Sí |
| Receptor electrónico B2B (URL propia de recepción / acuse / aprobación comercial) | **No** (fuera de este módulo salvo se implemente aparte) |
| Representación impresa / QR / código de seguridad | Según implementación actual en app |

Un cliente que deba **recibir** e-CF de otros emisores necesita componente o
proveedor de recepción; no forma parte del alcance mínimo de este facturador emisor.

## 2. Tipos e-CF en alcance de software

| Tipo | Descripción | Generación XML | Envío DGII | Evidencia Aceptado requerida antes de prometer en venta |
|------|-------------|----------------|------------|--------------------------------------------------------|
| 31 | Crédito fiscal | Sí | Sí | Sí |
| 32 | Consumo (≥ 250k e-CF completo) | Sí | Sí | Sí |
| 32 | Consumo (< 250k RFCE) | Sí | Sí (host fc) | Sí |
| 33 | Nota de débito | Sí (con eNCF ref.) | Sí | Recomendado |
| 34 | Nota de crédito | Sí (con eNCF ref.) | Sí | Sí |
| 41–47 | Otros | Parcial / no listo | No prometer | No |

Cualquier tipo fuera de la tabla no debe venderse como “certificable con este
software” hasta existir evidencia de Aceptado en TesteCF/CerteCF.

## 3. Requisitos del contribuyente (no son bugs del software)

- RNC habilitado como emisor electrónico ante DGII.
- Certificado digital PSC del **mismo** titular (RNC/cédula) que el emisor.
- Secuencias e-NCF autorizadas y vigentes.
- Ambiente correcto (TesteCF / CerteCF / Producción).
- Datos de la operación conformes a reglas de negocio DGII.
- Si el proceso de certificación exige URL de recepción del contribuyente:
  disponerla (propia o de tercero); no la sustituye el gateway de envío a DGII.

## 4. Controles de software ya implantados

- Preflight: ambiente, RNC, certificado en disco, OpenSSL, XSD/xmllint en cert-prod.
- Cruce titular certificado vs RNC emisor (OpenSSL subject).
- Validación estructural + XSD estricto en certificación/producción.
- Firma XMLDSig RSA-SHA256; XML sin pretty-print.
- No consumo de secuencia si falla validación.
- Anti-reenvío / marca de recepción incierta.
- URLs RFCE explícitas por ambiente (fc.dgii.gov.do).
- Umbral RFCE: total **<** 250000.

## 5. Criterio “la negativa no es por el software”

Se puede afirmar solo si:

1. Existe al menos un **Aceptado** (o Aceptado Condicional) por cada tipo
   prometido en la venta (mínimo 32 RFCE y/o 32 completo según negocio).
2. El rechazo, si ocurre, cita dato del contribuyente, secuencia, certificado
   de terceros, o requisito de receptor fuera de alcance.
3. Este documento de alcance está alineado con lo vendido al cliente.

## 6. Evidencia

Carpeta: `docs/ecf_evidencia_cert/`  
Guardar por caso: XML sin firma, XML firmado, JSON recepción, JSON consulta.
