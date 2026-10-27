import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('firmador móvil sin SignatureValue duplicado', () {
    final src = File('lib/features/e_cf/data/xml/ecfe_signer_impl.dart')
        .readAsStringSync();
    final dup = RegExp(
      r"<SignatureValue>\$signatureValue</SignatureValue>'\s*\n\s*'<SignatureValue>\$signatureValue</SignatureValue>",
    );
    expect(dup.hasMatch(src), isFalse);
  });

  test('builder sin pretty:true', () {
    final src = File('lib/features/e_cf/data/xml/ecfe_xml_builder_impl.dart')
        .readAsStringSync();
    expect(src.contains('pretty: true'), isFalse);
    expect(src.contains('pretty: false'), isTrue);
  });

  test('preflight existe', () {
    expect(
      File('lib/features/e_cf/domain/services/ecfe_preflight.dart').existsSync(),
      isTrue,
    );
  });
}
