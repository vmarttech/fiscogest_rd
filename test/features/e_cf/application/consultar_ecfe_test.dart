import 'package:flutter_test/flutter_test.dart';
import 'package:fiscogest_rd/features/e_cf/application/consultar_ecfe.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/estado_ecf_interno.dart';

void main() {
  group('ConsultarEcfe.mapearEstadoDgii', () {
    test('reconoce Aceptado', () {
      expect(
        ConsultarEcfe.mapearEstadoDgii('Aceptado', null),
        EstadoEcfInterno.aceptado,
      );
    });

    test('reconoce Aceptado Condicional', () {
      expect(
        ConsultarEcfe.mapearEstadoDgii('Aceptado Condicional', null),
        EstadoEcfInterno.aceptadoObservacion,
      );
    });

    test('reconoce Rechazado', () {
      expect(
        ConsultarEcfe.mapearEstadoDgii('Rechazado', null),
        EstadoEcfInterno.rechazado,
      );
    });

    test('reconoce En Proceso', () {
      expect(
        ConsultarEcfe.mapearEstadoDgii('En Proceso', null),
        EstadoEcfInterno.enProceso,
      );
    });

    test('no infiere el estado a partir de un código numérico', () {
      expect(ConsultarEcfe.mapearEstadoDgii(null, '1'), isNull);
      expect(ConsultarEcfe.mapearEstadoDgii(null, '2'), isNull);
      expect(ConsultarEcfe.mapearEstadoDgii(null, '3'), isNull);
      expect(ConsultarEcfe.mapearEstadoDgii(null, '4'), isNull);
    });

    test('devuelve null para estados vacíos o desconocidos', () {
      expect(ConsultarEcfe.mapearEstadoDgii('', null), isNull);
      expect(
        ConsultarEcfe.mapearEstadoDgii('Estado no documentado', null),
        isNull,
      );
    });
  });
}
