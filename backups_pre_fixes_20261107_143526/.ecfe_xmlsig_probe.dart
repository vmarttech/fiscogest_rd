import 'dart:io';
import 'package:fiscogest_rd/features/e_cf/data/xml/ecfe_signer_impl.dart';

Future<void> main(List<String> args) async {
  try {
    final signer = EcfeSignerImpl(
      rutaCertificado: args[0],
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
    await File(args[1]).writeAsString(firmado, flush: true);

    print('FIRMA GENERADA');
    print('Archivo: ${args[1]}');
  } catch (e, st) {
    stderr.writeln('ERROR FIRMANDO: $e');
    stderr.writeln(st);
    exitCode = 1;
  }
}
