import 'package:flutter_test/flutter_test.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/tipo_ecf.dart';
import 'package:fiscogest_rd/features/e_cf/domain/services/rfce_rules.dart';
import 'package:fiscogest_rd/features/e_cf/data/xml/rfce_xml.dart';

void main() {
  group('RfceRules', () {
    test('E32 bajo 250k es candidato', () {
      expect(
        RfceRules.esCandidatoRfce(tipo: TipoEcf.facturaConsumo, total: 249999.99),
        isTrue,
      );
    });
    test('E32 en 250k no es candidato', () {
      expect(
        RfceRules.esCandidatoRfce(tipo: TipoEcf.facturaConsumo, total: 250000),
        isFalse,
      );
    });
    test('E31 no es RFCE', () {
      expect(
        RfceRules.esCandidatoRfce(tipo: TipoEcf.facturaCreditoFiscal, total: 100),
        isFalse,
      );
    });
  });

  test('XML ya RFCE no se detecta como e-CF 32 resumible', () {
    expect(
      RfceXml.esResumenConsumo('<RFCE><Encabezado/></RFCE>'),
      isFalse,
    );
  });
}
