// [CAMPANAS_FASE1] Reserva local de una oferta hasta confirmar el pago.
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfertaReserva {
  const OfertaReserva({
    required this.campanaId, required this.titulo,
    required this.valor, required this.efectoTipo,
  });
  factory OfertaReserva.fromJson(Map<String, dynamic> j) => OfertaReserva(
        campanaId: '${j['campanaId'] ?? ''}',
        titulo: '${j['titulo'] ?? ''}',
        valor: '${j['valor'] ?? ''}',
        efectoTipo: '${j['efectoTipo'] ?? 'personalizado'}',
      );
  final String campanaId, titulo, valor, efectoTipo;
  Map<String, dynamic> toJson() =>
      {'campanaId': campanaId, 'titulo': titulo, 'valor': valor, 'efectoTipo': efectoTipo};
}

class OfertaReservaPagoStore {
  static const _k = 'oferta_reserva_pago_v1';
  static Future<OfertaReserva?> leer() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_k);
    if (raw == null || raw.isEmpty) return null;
    try { return OfertaReserva.fromJson(jsonDecode(raw) as Map<String, dynamic>); }
    catch (_) { return null; }
  }
  static Future<void> guardar(OfertaReserva r) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_k, jsonEncode(r.toJson()));
  }
  static Future<void> limpiar() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_k);
  }
}
