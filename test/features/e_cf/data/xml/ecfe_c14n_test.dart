import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:xml_crypto/xml_crypto.dart';

const c14nUri = 'http://www.w3.org/TR/2001/REC-xml-c14n-20010315';

String canonicalizar(String xml) {
  final algorithm = SignedXml.canonicalizationAlgorithms[c14nUri]!;
  return (algorithm.process(XmlDocument.parse(xml).rootElement)) as String;
}

void main() {
  group('XML C14N 1.0', () {
    test('ordena atributos y expande elementos vacíos', () {
      final result = canonicalizar('<root z="3" a="1" b="2"><empty/></root>');

      expect(result, '<root a="1" b="2" z="3"><empty></empty></root>');
    });

    test('preserva namespaces utilizados por elementos y atributos', () {
      final result = canonicalizar(
        '<r xmlns:z="urn:z" xmlns:a="urn:a">'
        '<z:item z:b="2" a:c="1"/>'
        '</r>',
      );

      expect(
        result,
        '<r xmlns:a="urn:a" xmlns:z="urn:z">'
        '<z:item a:c="1" z:b="2"></z:item>'
        '</r>',
      );
    });

    test('preserva espacios significativos y escapa caracteres XML', () {
      final result = canonicalizar(
        '<root> <item>A &amp; B &lt; C</item> </root>',
      );

      expect(result, '<root> <item>A &amp; B &lt; C</item> </root>');
    });

    test('es determinista para documentos equivalentes', () {
      final a = canonicalizar('<root b="2" a="1"><x/></root>');
      final b = canonicalizar('<root a="1" b="2"><x></x></root>');

      expect(a, b);
    });
  });
}
