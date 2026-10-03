# Manual del implementador — e-CF FiscoGest

## Objetivo

Dejar el módulo e-CF operativo y probado en el local del cliente, con evidencia
para certificación y un traspaso claro a producción.

## Antes de la visita

1. Confirmar certificado digital (PSC) y clave.
2. Confirmar autorización de e-NCF (rangos) para los tipos a usar.
3. Contar con XSD o paquete de especificación DGII de referencia.
4. Hacer backup de la base FiscoGest.
5. Acordar tiempo: aproximadamente 1 a 2 horas en la primera activación.

## Orden en el local

1. Configuración: habilitar, precertificación, RNC, certificado, XSD, secuencias.
2. Revisar pestaña Guía con el cliente.
3. Ejecutar el smoke test (docs/ecf_smoke_test.md).
4. Marcar checklist en Especificación.
5. Capacitación corta: cola, consultar, RI, aviso de certificado.
6. No activar Producción hasta cumplir el proceso DGII del cliente.

## Responsabilidades

- Cliente: datos fiscales, certificado, rangos, internet, trámites DGII.
- Implementador: configuración FiscoGest, pruebas, cola, RI, capacitación.
- PSC: emisión y renovación del certificado.
- DGII: aceptación o rechazo y reglas oficiales.

## Traspaso a producción

- Pruebas aceptadas documentadas
- Certificado de producción instalado
- Rangos e-NCF de producción cargados
- Ambiente = Producción
- Contador y cajero saben usar Cola y RI

## Documentos del proyecto

- docs/ecf_guia_uso.md — uso diario
- docs/ecf_smoke_test.md — prueba rápida
- docs/ecf_manual_implementador.md — esta guía
