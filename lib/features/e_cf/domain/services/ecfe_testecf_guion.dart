/// Guión TesteCF / precert → cert → producción (implementación en el local).
class EcfeTestecfPaso {
  const EcfeTestecfPaso({
    required this.id,
    required this.orden,
    required this.titulo,
    required this.detalle,
    required this.fase,
  });

  final String id;
  final int orden;
  final String titulo;
  final String detalle;
  /// precert | cert | prod
  final String fase;
}

class EcfeTestecfGuion {
  const EcfeTestecfGuion._();

  static const pasos = <EcfeTestecfPaso>[
    EcfeTestecfPaso(
      id: 'cfg_mod',
      orden: 1,
      fase: 'precert',
      titulo: 'Habilitar módulo y ambiente',
      detalle:
          'e-CF → Configuración: Habilitar = sí, Ambiente = Precertificación, '
          'RNC y razón social del emisor de prueba DGII.',
    ),
    EcfeTestecfPaso(
      id: 'cfg_cert',
      orden: 2,
      fase: 'precert',
      titulo: 'Certificado digital de prueba',
      detalle:
          'Ruta .p12 + clave. Confirmar que el aviso de vencimiento no diga '
          'VENCIDO. OpenSSL debe poder leer el contenedor en este equipo.',
    ),
    EcfeTestecfPaso(
      id: 'cfg_xsd',
      orden: 3,
      fase: 'precert',
      titulo: 'XSD oficial',
      detalle:
          'Ruta al .xsd del paquete e-CF DGII (o assets/ecf_xsd/). '
          'En certificación/producción la validación XSD es obligatoria.',
    ),
    EcfeTestecfPaso(
      id: 'cfg_seq',
      orden: 4,
      fase: 'precert',
      titulo: 'Secuencias e-NCF 31 / 32 / 34',
      detalle:
          'Configuración → Secuencias: rangos desde/hasta/vencimiento '
          'autorizados para crédito fiscal, consumo y nota de crédito.',
    ),
    EcfeTestecfPaso(
      id: 'tx_31',
      orden: 5,
      fase: 'precert',
      titulo: 'Prueba E31 (crédito fiscal)',
      detalle:
          'Venta a cliente con RNC → cola e-CF → Generar XML → Firmar → '
          'Enviar → Consultar hasta Aceptado → Imprimir RI (QR).',
    ),
    EcfeTestecfPaso(
      id: 'tx_32',
      orden: 6,
      fase: 'precert',
      titulo: 'Prueba E32 (consumo)',
      detalle:
          'Misma secuencia con factura de consumo. Verificar e-NCF E32… y RI.',
    ),
    EcfeTestecfPaso(
      id: 'tx_34',
      orden: 7,
      fase: 'precert',
      titulo: 'Prueba E34 (nota de crédito)',
      detalle:
          'Detalle → e-NCF de referencia del comprobante modificado → '
          'Generar/Firmar/Enviar/Consultar. XML debe incluir eNCFModificado.',
    ),
    EcfeTestecfPaso(
      id: 'tx_doble',
      orden: 8,
      fase: 'precert',
      titulo: 'Anti doble envío',
      detalle:
          'Documento con TrackId: Enviar otra vez no debe crear otro envío. '
          'Mensaje “ya estaba enviado”. Consultar actualiza estado.',
    ),
    EcfeTestecfPaso(
      id: 'tx_cola',
      orden: 9,
      fase: 'precert',
      titulo: 'Cola operativa',
      detalle:
          'Filtros Pendientes / Errores / Aceptados. Ver “siguiente acción”, '
          'errores y pull-to-refresh. Abrir detalle desde la lista.',
    ),
    EcfeTestecfPaso(
      id: 'cert_formal',
      orden: 10,
      fase: 'cert',
      titulo: 'Ambiente Certificación',
      detalle:
          'Cambiar a Certificación, cert y secuencias de certificación, '
          'XSD obligatorio. Completar ítems del checklist de la versión.',
    ),
    EcfeTestecfPaso(
      id: 'prod',
      orden: 11,
      fase: 'prod',
      titulo: 'Paso a Producción',
      detalle:
          'Solo tras OK del proceso DGII. Ambiente Producción, certificado y '
          'rangos reales. La caja encola e-CF sin pasos extra para el cajero.',
    ),
  ];
}
