import 'package:flutter_test/flutter_test.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/tipo_ecf.dart';
import 'package:fiscogest_rd/features/e_cf/domain/services/rfce_rules.dart';
import 'package:fiscogest_rd/features/e_cf/data/xml/rfce_xml.dart';

void main() {
  group('RFCE reglas de negocio', () {
    test('E32 bajo umbral es candidato RFCE', () {
      expect(
        RfceRules.esCandidatoRfce(
          tipo: TipoEcf.facturaConsumo,
          total: 1000,
        ),
        isTrue,
      );
    });

    test('E32 en o sobre 250000 no es RFCE', () {
      expect(
        RfceRules.esCandidatoRfce(
          tipo: TipoEcf.facturaConsumo,
          total: 250000,
        ),
        isFalse,
      );
      expect(
        RfceRules.esCandidatoRfce(
          tipo: TipoEcf.facturaConsumo,
          total: 250000.01,
        ),
        isFalse,
      );
    });

    test('E31 nunca es RFCE', () {
      expect(
        RfceRules.esCandidatoRfce(
          tipo: TipoEcf.facturaCreditoFiscal,
          total: 100,
        ),
        isFalse,
      );
    });
  });

  group('RfceXml detección', () {
    test('no trata un RFCE ya armado como e-CF 32', () {
      const xml = '<?xml version="1.0"?><RFCE><Encabezado></Encabezado></RFCE>';
      expect(RfceXml.esResumenConsumo(xml), isFalse);
    });
  });
}
