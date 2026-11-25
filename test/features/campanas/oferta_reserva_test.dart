import 'package:flutter_test/flutter_test.dart';
import 'package:fiscogest_rd/features/campanas/data/campanas_remote.dart';
import 'package:fiscogest_rd/features/campanas/data/oferta_reserva_pago_store.dart';

void main() {
  test('parseAplicado interpreta JSONB con efecto', () {
    final r = CampanasRemote.parseAplicado(
        {'aplicado': true, 'efecto': {'tipo': 'descuento', 'pct': 50}});
    expect(r['aplicado'], isTrue);
    expect((r['efecto'] as Map)['pct'], 50);
  });
  test('parseAplicado tolera booleano legado', () {
    expect(CampanasRemote.parseAplicado(true)['aplicado'], isTrue);
    expect(CampanasRemote.parseAplicado(false)['aplicado'], isFalse);
  });
  test('OfertaReserva serializa y reconstruye', () {
    const r = OfertaReserva(
        campanaId: 'c1', titulo: 'Black Friday', valor: '50%', efectoTipo: 'descuento');
    final b = OfertaReserva.fromJson(r.toJson());
    expect(b.campanaId, 'c1');
    expect(b.efectoTipo, 'descuento');
  });
}
