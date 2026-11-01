import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Clave de cifrado de la BD local (independiente del login).
class DbEncryptionKey {
  static const _k = 'fiscogest_db_cipher_key_v1';
  static const _secure = FlutterSecureStorage();

  static Future<String> obtenerOCrear() async {
    final existing = await _secure.read(key: _k);
    if (existing != null && existing.length >= 32) return existing;

    final r = Random.secure();
    final bytes = List<int>.generate(32, (_) => r.nextInt(256));
    final key = base64UrlEncode(bytes);
    await _secure.write(key: _k, value: key);
    return key;
  }
}
