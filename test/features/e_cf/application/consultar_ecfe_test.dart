import 'package:flutter_test/flutter_test.dart';
import 'package:fiscogest_rd/features/e_cf/application/consultar_ecfe.dart';
import 'package:fiscogest_rd/features/e_cf/application/consultar_estado_ecfe.dart';
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
  group('ConsultarEstadoEcfe.mapearEstadoDgii', () {
    test('mantiene el mismo mapeo para estados reconocidos', () {
      final casos = <String, EstadoEcfInterno>{
        'Aceptado': EstadoEcfInterno.aceptado,
        'Aceptado Condicional': EstadoEcfInterno.aceptadoObservacion,
        'Rechazado': EstadoEcfInterno.rechazado,
        'En Proceso': EstadoEcfInterno.enProceso,
      };

      for (final caso in casos.entries) {
        expect(
          ConsultarEstadoEcfe.mapearEstadoDgii(caso.key),
          caso.value,
          reason: 'Estado DGII: ${caso.key}',
        );
        expect(
          ConsultarEstadoEcfe.mapearEstadoDgii(caso.key),
          ConsultarEcfe.mapearEstadoDgii(caso.key, null),
          reason: 'Los mappers deben coincidir para ${caso.key}',
        );
      }
    });

    test('devuelve null para estados vacíos o desconocidos', () {
      for (final estado in <String?>[null, '', 'Estado no documentado']) {
        expect(ConsultarEstadoEcfe.mapearEstadoDgii(estado), isNull);
        expect(
          ConsultarEstadoEcfe.mapearEstadoDgii(estado),
          ConsultarEcfe.mapearEstadoDgii(estado, null),
        );
      }
    });
  });
}
