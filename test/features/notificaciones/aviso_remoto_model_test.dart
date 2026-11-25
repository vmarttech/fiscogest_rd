// [AVISOS_FASE1]
import 'package:flutter_test/flutter_test.dart';
import 'package:fiscogest_rd/features/notificaciones/domain/aviso_remoto.dart';

void main() {
  group('AvisoRemoto', () {
    test('mapea aviso no leido con etiquetas', () {
      final a = AvisoRemoto.fromJson(const {
        'id': 'a1',
        'tipo': 'oferta',
        'titulo': 'Promo navideña',
        'mensaje': 'Descuento diciembre',
        'negocio_id': null,
        'prioridad': 'alta',
        'fecha_envio': '2026-11-24T10:00:00Z',
        'fecha_leido': null,
      });
      expect(a.id, 'a1');
      expect(a.leido, isFalse);
      expect(a.tipoEtiqueta, 'Oferta / promocion');
      expect(a.prioridadEtiqueta, 'Alta');
    });

    test('mapea aviso leido desde fecha_leido', () {
      final a = AvisoRemoto.fromJson(const {
        'id': 'a2',
        'tipo': 'sistema',
        'titulo': 'Mantenimiento',
        'mensaje': 'Madrugada domingo',
        'prioridad': 'normal',
        'fecha_envio': '2026-11-24T10:00:00Z',
        'fecha_leido': '2026-11-24T11:00:00Z',
      });
      expect(a.leido, isTrue);
      expect(a.tipoEtiqueta, 'Sistema');
    });

    test('valores por defecto si el JSON viene incompleto', () {
      final a = AvisoRemoto.fromJson(const {'id': 'a3', 'titulo': 'T', 'mensaje': 'M'});
      expect(a.tipo, 'informacion');
      expect(a.prioridad, 'normal');
      expect(a.leido, isFalse);
    });
  });
}
