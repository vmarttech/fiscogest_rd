class EspejoRecepcion {
  const EspejoRecepcion({
    required this.ok,
    required this.codigo,
    required this.mensaje,
    this.trackId,
  });
  final bool ok;
  final String codigo;
  final String mensaje;
  final String? trackId;
}

class DgiiEspejoLocal {
  static final Map<String, int> _pasos = {};

  static String _tag(String xml, String nombre) {
    final abre = '<$nombre>';
    final i = xml.indexOf(abre);
    if (i < 0) return '';
    final j = xml.indexOf('</$nombre>', i + abre.length);
    if (j < 0) return '';
    return xml.substring(i + abre.length, j).trim();
  }

  static String _digitos(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  static String? validar(String xml, {required bool resumen}) {
    final tipo = _tag(xml, 'TipoeCF');
    final encf = _tag(xml, 'eNCF').toUpperCase();
    if (!xml.contains('<Signature') || _tag(xml, 'SignatureValue').isEmpty) {
      return 'Falta la firma digital';
    }
    if (xml.toUpperCase().contains('RECHAZAR')) {
      return 'El nombre trae RECHAZAR. Asi se ve un comprobante rechazado';
    }
    const tipos = ['31', '32', '33', '34', '41', '43', '44'];
    if (!tipos.contains(tipo)) return 'Este tipo no se practica aqui';
    final resto = encf.startsWith('E$tipo')
        ? encf.substring(1 + tipo.length)
        : '';
    if (resto.length != 10 || int.tryParse(resto) == null) {
      return 'El e-NCF no corresponde al tipo $tipo';
    }
    final rnc = _digitos(_tag(xml, 'RNCEmisor'));
    if (rnc.length != 9 && rnc.length != 11) return 'RNC del emisor invalido';
    if (_tag(xml, 'RazonSocialEmisor').isEmpty) return 'Falta la razon social';
    if (_tag(xml, 'FechaEmision').isEmpty) return 'Falta la fecha de emision';
    if (_tag(xml, 'FechaHoraFirma').isEmpty) return 'Falta la hora de la firma';
    final total = double.tryParse(_tag(xml, 'MontoTotal')) ?? 0;
    if (total <= 0) return 'El total debe ser mayor que cero';
    final comprador = _digitos(_tag(xml, 'RNCComprador'));
    if (tipo == '31' && comprador.length != 9 && comprador.length != 11) {
      return 'La factura 31 requiere RNC o cedula del comprador';
    }
    final esResumen = resumen || xml.contains('<RFCE');
    if (tipo == '32' && total >= 250000 && esResumen) {
      return 'Desde 250000 el consumo no se envia como resumen';
    }
    if (esResumen && _tag(xml, 'CodigoSeguridadeCF').length != 6) {
      return 'El resumen requiere el codigo de seguridad de 6 caracteres';
    }
    if ((tipo == '33' || tipo == '34') &&
        _tag(xml, 'NCFModificado').isEmpty &&
        _tag(xml, 'eNCFModificado').isEmpty) {
      return 'La nota requiere el e-NCF que modifica';
    }
    if ((tipo == '41' || tipo == '43') &&
        _tag(xml, 'TipoIngresos').isNotEmpty) {
      return 'El tipo $tipo no lleva TipoIngresos';
    }
    if (tipo == '34' &&
        _tag(xml, 'IndicadorNotaCredito') != '0' &&
        _tag(xml, 'IndicadorNotaCredito') != '1') {
      return 'La nota de credito debe indicar si pasan de 30 dias (0 o 1)';
    }
    if (tipo == '43' && comprador.isNotEmpty) {
      return 'El gasto menor no lleva RNC del comprador';
    }
    if (tipo == '44' && comprador.length != 9 && comprador.length != 11) {
      return 'El regimen especial requiere RNC o cedula';
    }
    if (tipo == '32' &&
        total >= 250000 &&
        comprador.length != 9 &&
        comprador.length != 11) {
      return 'Desde 250000 el consumo requiere RNC o cedula';
    }
    if ((tipo == '33' || tipo == '34') &&
        _tag(xml, 'FechaNCFModificado').isEmpty) {
      return 'La nota no trae la fecha del e-NCF modificado';
    }
    if (tipo == '33' || tipo == '34') {
      final codigoModificado = _tag(xml, 'CodigoModificacion');
      if (codigoModificado.isEmpty) {
        return 'La nota no trae el codigo de modificacion';
      }
      const codigosModificacion = {'1', '2', '3', '4', '5'};
      if (!codigosModificacion.contains(codigoModificado)) {
        return 'CodigoModificacion $codigoModificado no es valido';
      }
    }
    return null;
  }

  static EspejoRecepcion recibir(String xml, {required bool resumen}) {
    final error = validar(xml, resumen: resumen);
    if (error != null) {
      return EspejoRecepcion(
        ok: false,
        codigo: '2',
        mensaje: 'Practica: $error',
      );
    }
    if (resumen || xml.contains('<RFCE')) {
      return const EspejoRecepcion(
        ok: true,
        codigo: '1',
        mensaje:
            'Practica: resumen aceptado en este equipo. No llego a la DGII.',
      );
    }
    final track = 'practica-${DateTime.now().microsecondsSinceEpoch}';
    _pasos[track] = 0;
    return EspejoRecepcion(
      ok: true,
      codigo: '0',
      trackId: track,
      mensaje:
          'Practica: recibido en este equipo. Consulta para ver el resultado.',
    );
  }

  static String consultar(String trackId) {
    if (!trackId.startsWith('practica-')) return 'No encontrado';
    final n = (_pasos[trackId] ?? 0) + 1;
    _pasos[trackId] = n;
    return n == 1 ? 'En Proceso' : 'Aceptado';
  }
}
