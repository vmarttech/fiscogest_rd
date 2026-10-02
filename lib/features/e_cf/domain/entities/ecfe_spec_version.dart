/// Versión de especificación e-CF (circular / XSD / servicios) adoptada por el sistema.
class EcfeSpecVersion {
  const EcfeSpecVersion({
    this.id,
    required this.codigo,
    required this.nombre,
    this.circularDgii,
    this.xsdVersion = '',
    this.notas,
    this.activaPrecert = false,
    this.activaCert = false,
    this.activaProduccion = false,
    this.checklistJson = '[]',
    required this.creadoEn,
    this.activadoEn,
  });

  final int? id;
  /// Ej: "1.0", "1.1-rfce"
  final String codigo;
  final String nombre;
  /// Referencia a circular o documento DGII
  final String? circularDgii;
  final String xsdVersion;
  final String? notas;
  final bool activaPrecert;
  final bool activaCert;
  final bool activaProduccion;
  /// JSON array de {id, label, done, doneAt?}
  final String checklistJson;
  final DateTime creadoEn;
  final DateTime? activadoEn;

  bool get enUso =>
      activaPrecert || activaCert || activaProduccion;
}
