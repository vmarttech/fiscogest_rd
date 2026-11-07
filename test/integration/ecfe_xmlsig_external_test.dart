import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fiscogest_rd/features/e_cf/data/xml/ecfe_signer_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Generar XMLDSig verificable externamente', () async {
    final tmp = Platform.environment['ECFE_TEST_DIR'];
    expect(tmp, isNotNull);

    final signer = EcfeSignerImpl(
      rutaCertificado: '$tmp/test.p12',
      claveCertificado: 'Prueba123',
    );

    const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<ECF xmlns="urn:fiscogest:test" version="1.0">
  <Encabezado>
    <IdDoc tipo="01" numero="TEST-000001"/>
  </Encabezado>
  <Detalles>
    <Item cantidad="2" precio="100.00">Producto de prueba</Item>
  </Detalles>
</ECF>''';

    final firmado = await signer.firmar(xml);

    final archivo = File('$tmp/documento_firmado.xml');
    await archivo.writeAsString(firmado, flush: true);

    expect(await archivo.exists(), isTrue);
    expect(firmado, contains('<Signature'));
    expect(firmado, contains('<DigestValue>'));

    // ignore: avoid_print
    print('XML GENERADO: ${archivo.path}');
  });
}
