import 'package:fiscogest_rd/features/e_cf/domain/entities/ecfe_checklist_item.dart';

/// Checklist base al adoptar una circular / versión de especificación DGII.
class EcfeChecklistCatalog {
  static List<EcfeChecklistItem> plantillaBase() => const [
        EcfeChecklistItem(
          id: 'cfg_ambiente',
          label: 'Configurar ambiente (TesteCF / CerteCF) y RNC emisor',
          categoria: 'config',
        ),
        EcfeChecklistItem(
          id: 'cfg_cert',
          label: 'Cargar certificado .p12 y validar OpenSSL en el equipo',
          categoria: 'config',
        ),
        EcfeChecklistItem(
          id: 'seq_encf',
          label: 'Verificar rangos de secuencia e-NCF (31/32/34)',
          categoria: 'config',
        ),
        EcfeChecklistItem(
          id: 'xml_31',
          label: 'Generar y validar estructura XML tipo 31 (crédito fiscal)',
          categoria: 'xml',
        ),
        EcfeChecklistItem(
          id: 'xml_32',
          label: 'Generar y validar estructura XML tipo 32 (consumo)',
          categoria: 'xml',
        ),
        EcfeChecklistItem(
          id: 'xml_34',
          label: 'Generar XML tipo 34 (nota de crédito) si aplica',
          categoria: 'xml',
        ),
        EcfeChecklistItem(
          id: 'firma',
          label: 'Firmar XML (XMLDSig RSA-SHA256) sin error técnico',
          categoria: 'firma',
        ),
        EcfeChecklistItem(
          id: 'auth_semilla',
          label: 'Autenticación DGII: semilla → token JWT',
          categoria: 'servicios',
        ),
        EcfeChecklistItem(
          id: 'recepcion',
          label: 'Enviar a recepción y obtener TrackId',
          categoria: 'servicios',
        ),
        EcfeChecklistItem(
          id: 'consulta',
          label: 'Consultar estado por TrackId (aceptado / rechazado)',
          categoria: 'servicios',
        ),
        EcfeChecklistItem(
          id: 'ri_qr',
          label: 'Imprimir RI con código de seguridad y QR',
          categoria: 'ri',
        ),
        EcfeChecklistItem(
          id: 'rfce',
          label: 'Probar candidato RFCE (consumo < RD\$250,000)',
          categoria: 'rfce',
        ),
        EcfeChecklistItem(
          id: 'hook_venta',
          label: 'Emitir factura B01/B02 y verificar encolado automático',
          categoria: 'integracion',
        ),
        EcfeChecklistItem(
          id: 'doc_circular',
          label: 'Archivar referencia de circular DGII y notas de cambios',
          categoria: 'documentacion',
        ),
      ];
}
