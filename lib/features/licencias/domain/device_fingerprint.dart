import 'dart:math';
import 'dart:convert';
import 'dart:io' show File;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdentity {
  const DeviceIdentity({
    required this.fingerprint,
    required this.persistenteTrasReinstalar,
    required this.metodo,
    this.legacyFingerprint,
  });

  final String fingerprint;
  final bool persistenteTrasReinstalar;
  final String metodo;
  final String? legacyFingerprint;
}

/// Identificador pseudónimo. Nunca lee IMEI ni número de serie.
class DeviceFingerprint {
  static const _channel = MethodChannel('fiscogest/device_identity');
  static const _fallbackKey = 'fiscogest_device_id_v2';
  static const _legacyFile = 'fiscogest_device_id.txt';
  static const _secureStorage = FlutterSecureStorage();
  static DeviceIdentity? _identity;

  static Future<String> obtener() async =>
      (await obtenerResultado()).fingerprint;

  static Future<DeviceIdentity> obtenerResultado() async {
    final cached = _identity;
    if (cached != null) return cached;
    final legacy = await _leerIdAnterior();

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      try {
        final raw = await _channel
            .invokeMethod<String>('getStableDeviceId')
            .timeout(const Duration(seconds: 3));
        if (raw != null && raw.trim().isNotEmpty) {
          return _identity = DeviceIdentity(
            fingerprint: _hash(raw.trim()),
            persistenteTrasReinstalar: true,
            metodo: defaultTargetPlatform == TargetPlatform.android
                ? 'android_id'
                : 'keychain_ios',
            legacyFingerprint: legacy,
          );
        }
      } catch (_) {
        // La identidad del dispositivo nunca debe impedir iniciar la app.
      }
    }

    if (legacy != null && legacy.isNotEmpty) {
      return _identity = DeviceIdentity(
        fingerprint: legacy,
        persistenteTrasReinstalar: false,
        metodo: 'identificador_local_anterior',
      );
    }

    final stored = await _leerAlmacenamiento();
    if (stored != null) {
      return _identity = DeviceIdentity(
        fingerprint: _hash(stored),
        persistenteTrasReinstalar: false,
        metodo: 'almacenamiento_local',
      );
    }

    final generated = _randomId();
    await _guardarAlmacenamiento(generated);
    return _identity = DeviceIdentity(
      fingerprint: _hash(generated),
      persistenteTrasReinstalar: false,
      metodo: 'temporal',
    );
  }

  static Future<String?> _leerIdAnterior() async {
    if (kIsWeb) return null;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File(path.join(directory.path, _legacyFile));
      if (!await file.exists()) return null;
      final value = (await file.readAsString()).trim();
      return value.isEmpty ? null : value;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _leerAlmacenamiento() async {
    try {
      final value = await _secureStorage.read(key: _fallbackKey);
      if (value != null && value.isNotEmpty) return value;
    } catch (_) {}
    try {
      return (await SharedPreferences.getInstance()).getString(_fallbackKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _guardarAlmacenamiento(String value) async {
    try {
      await _secureStorage.write(key: _fallbackKey, value: value);
      return;
    } catch (_) {}
    try {
      await (await SharedPreferences.getInstance()).setString(
        _fallbackKey,
        value,
      );
    } catch (_) {}
  }

  static String _hash(String value) => sha256
      .convert(utf8.encode('com.fiscogest.fiscogest_rd:v1:$value'))
      .toString();

  static String _randomId() {
    final random = Random.secure();
    return List<int>.generate(
      32,
      (_) => random.nextInt(256),
    ).map((n) => n.toRadixString(16).padLeft(2, '0')).join();
  }

  static String plataformaActual() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.linux => 'linux',
      TargetPlatform.windows => 'windows',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.fuchsia => 'otro',
    };
  }

  static String tipoActual() {
    final plataforma = plataformaActual();
    if (plataforma == 'android' || plataforma == 'ios') return 'movil';
    if (plataforma == 'web') return 'otro';
    return 'pc';
  }

  static String aliasSugerido() {
    switch (plataformaActual()) {
      case 'android':
        return 'Celular Android';
      case 'ios':
        return 'iPhone / iPad';
      case 'linux':
        return 'PC Linux';
      case 'windows':
        return 'PC Windows';
      case 'macos':
        return 'Mac';
      default:
        return 'Este equipo';
    }
  }
}
