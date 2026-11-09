import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Tasa USD → DOP en tiempo real (solo referencia para transferencia).
/// No interviene en PayPal ni en montos de cobro en USD.
class TasaUsdDop {
  const TasaUsdDop({
    required this.tasa,
    required this.actualizadoEn,
    required this.fuente,
    required this.desdeCache,
  });

  /// Cuántos DOP por 1 USD.
  final double tasa;
  final DateTime actualizadoEn;
  final String fuente;
  final bool desdeCache;

  double aDop(double usd) => usd * tasa;

  String formatoDop(double usd) => _miles(aDop(usd));

  static String _miles(double v) {
    final neg = v < 0;
    final abs = v.abs();
    final fixed = abs.toStringAsFixed(2);
    final sp = fixed.split('.');
    var intPart = sp[0];
    final dec = sp[1];
    final rev = intPart.split('').reversed.toList();
    final chunks = <String>[];
    for (var i = 0; i < rev.length; i += 3) {
      chunks.add(rev.sublist(i, i + 3 > rev.length ? rev.length : i + 3).join());
    }
    intPart = chunks.map((c) => c.split('').reversed.join()).toList().reversed.join(',');
    return '${neg ? '-' : ''}RD\$$intPart.$dec';
  }
}

class TasaCambioService {
  TasaCambioService._();
  static final instance = TasaCambioService._();

  static const _prefTasa = 'fx_usd_dop_tasa';
  static const _prefTs = 'fx_usd_dop_ts';
  static const _prefFuente = 'fx_usd_dop_fuente';

  /// open.er-api.com — sin API key, incluye DOP, actualiza con frecuencia.
  static const _urlPrimary =
      'https://open.er-api.com/v6/latest/USD';

  /// Respaldo (también incluye DOP).
  static const _urlBackup =
      'https://api.exchangerate-api.com/v4/latest/USD';

  TasaUsdDop? _memoria;

  /// Obtiene tasa en vivo; si falla red, usa última guardada.
  Future<TasaUsdDop?> obtenerUsdDop({bool forzarRed = false}) async {
    if (!forzarRed && _memoria != null) {
      final age = DateTime.now().difference(_memoria!.actualizadoEn);
      if (age.inMinutes < 30 && !_memoria!.desdeCache) return _memoria;
    }

    final viva = await _fetchRed();
    if (viva != null) {
      _memoria = viva;
      await _guardar(viva);
      return viva;
    }

    final cache = await _leerCache();
    if (cache != null) {
      _memoria = cache;
      return cache;
    }
    return _memoria;
  }

  Future<TasaUsdDop?> _fetchRed() async {
    for (final url in [_urlPrimary, _urlBackup]) {
      try {
        final res = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 8));
        if (res.statusCode != 200) continue;
        final body = jsonDecode(res.body);
        if (body is! Map) continue;
        final rates = body['rates'];
        if (rates is! Map) continue;
        final raw = rates['DOP'] ?? rates['dop'];
        if (raw == null) continue;
        final tasa = (raw is num) ? raw.toDouble() : double.tryParse('$raw');
        if (tasa == null || tasa <= 0) continue;
        return TasaUsdDop(
          tasa: tasa,
          actualizadoEn: DateTime.now(),
          fuente: url.contains('open.er-api') ? 'open.er-api.com' : 'exchangerate-api.com',
          desdeCache: false,
        );
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  Future<void> _guardar(TasaUsdDop t) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setDouble(_prefTasa, t.tasa);
      await p.setString(_prefTs, t.actualizadoEn.toIso8601String());
      await p.setString(_prefFuente, t.fuente);
    } catch (_) {}
  }

  Future<TasaUsdDop?> _leerCache() async {
    try {
      final p = await SharedPreferences.getInstance();
      final tasa = p.getDouble(_prefTasa);
      final ts = p.getString(_prefTs);
      if (tasa == null || tasa <= 0 || ts == null) return null;
      return TasaUsdDop(
        tasa: tasa,
        actualizadoEn: DateTime.tryParse(ts) ?? DateTime.now(),
        fuente: p.getString(_prefFuente) ?? 'caché local',
        desdeCache: true,
      );
    } catch (_) {
      return null;
    }
  }
}
