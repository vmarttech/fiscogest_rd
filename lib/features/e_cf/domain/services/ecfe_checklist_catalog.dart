import 'package:fiscogest_rd/features/e_cf/domain/entities/ecfe_checklist_item.dart';

/// Ítems de adopción / certificación por versión de especificación e-CF.
class EcfeChecklistItemDef {
  const EcfeChecklistItemDef({
    required this.id,
    required this.label,
    this.grupo = 'general',
  });

  final String id;
  final String label;
  final String grupo;
}

class EcfeChecklistCatalog {
  const EcfeChecklistCatalog._();

  static const items = <EcfeChecklistItemDef>[
    EcfeChecklistItemDef(id: 'mod_habilitado', grupo: 'config', label: 'Módulo e-CF habilitado y ambiente distinto de Deshabilitado'),
    EcfeChecklistItemDef(id: 'rnc_razon', grupo: 'config', label: 'RNC y razón social del emisor cargados'),
    EcfeChecklistItemDef(id: 'cert_p12', grupo: 'config', label: 'Certificado .p12/.pfx y clave válidos en el equipo'),
    EcfeChecklistItemDef(id: 'cert_vigente', grupo: 'config', label: 'Certificado digital no vencido (margen > 30 días ideal)'),
    EcfeChecklistItemDef(id: 'xsd_ruta', grupo: 'config', label: 'Ruta XSD oficial DGII configurada y validación estructural/XSD OK'),
    EcfeChecklistItemDef(id: 'seq_31', grupo: 'secuencias', label: 'Secuencia e-NCF tipo 31 (crédito fiscal) configurada'),
    EcfeChecklistItemDef(id: 'seq_32', grupo: 'secuencias', label: 'Secuencia e-NCF tipo 32 (consumo) configurada'),
    EcfeChecklistItemDef(id: 'seq_34', grupo: 'secuencias', label: 'Secuencia e-NCF tipo 34 (nota de crédito) configurada'),
    EcfeChecklistItemDef(id: 'xml_31', grupo: 'pruebas', label: 'XML tipo 31 generado, firmado y validado'),
    EcfeChecklistItemDef(id: 'xml_32', grupo: 'pruebas', label: 'XML tipo 32 generado, firmado y validado'),
    EcfeChecklistItemDef(id: 'xml_34', grupo: 'pruebas', label: 'XML tipo 34 con eNCFModificado generado y firmado'),
    EcfeChecklistItemDef(id: 'auth_semilla', grupo: 'red', label: 'Autenticación DGII: semilla → token JWT OK'),
    EcfeChecklistItemDef(id: 'envio_track', grupo: 'red', label: 'Recepción DGII: al menos un TrackId recibido'),
    EcfeChecklistItemDef(id: 'consulta_aceptado', grupo: 'red', label: 'Consulta por TrackId: al menos un e-CF Aceptado'),
    EcfeChecklistItemDef(id: 'ri_qr', grupo: 'ri', label: 'Representación impresa con código de seguridad y QR generada'),
    EcfeChecklistItemDef(id: 'cola_filtros', grupo: 'ops', label: 'Cola e-CF operativa (filtros, errores, siguiente acción)'),
    EcfeChecklistItemDef(id: 'anti_doble', grupo: 'ops', label: 'Verificado anti doble envío con TrackId existente'),
    EcfeChecklistItemDef(id: 'circular_ref', grupo: 'docs', label: 'Circular / versión de especificación DGII archivada en notas'),
  ];

  static List<EcfeChecklistItem> plantillaBase() => [
        for (final i in items)
          EcfeChecklistItem(
            id: i.id,
            label: i.label,
            done: false,
          ),
      ];
}
