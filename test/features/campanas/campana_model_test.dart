// [CAMPANAS_FASE1]
import 'package:flutter_test/flutter_test.dart';
import 'package:fiscogest_rd/features/campanas/domain/campana_promocional.dart';

void main() {
  test('mapea campaña vigente de segmento plan_especifico', () {
    final c = CampanaPromocional.fromJson(const {
      'id': 'c1',
      'nombre': 'Black Friday',
      'descripcion': '50% en planes anuales',
      'tipo': 'descuento',
      'valor': '50%',
      'segmento_objetivo': 'plan_especifico',
      'plan_aplicar': 'pro',
      'fecha_inicio': '2026-11-24T00:00:00Z',
      'fecha_fin': '2026-12-01T00:00:00Z',
      'usos_actuales': 3,
      'limite_usos_total': 10,
      'activa': true,
    });
    expect(c.segmentoEtiqueta, contains('pro'));
    expect(c.tipoEtiqueta, 'Descuento');
    expect(c.usosActuales, 3);
    expect(c.vigente, isTrue);
  });

  test('campaña pausada no está vigente', () {
    final c = CampanaPromocional.fromJson(const {
      'id': 'c2',
      'nombre': 'Pausa',
      'tipo': 'meses_gratis',
      'valor': '3 meses',
      'segmento_objetivo': 'nuevas_cuentas',
      'activa': false,
    });
    expect(c.vigente, isFalse);
    expect(c.estadoEtiqueta, 'Pausada');
  });
}
