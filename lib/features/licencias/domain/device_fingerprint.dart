import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Identidad estable de esta instalación (lista para enviar a Supabase).
class DeviceFingerprint {
  static const _fileName = 'fiscogest_device_id.txt';

  /// UUID v4 persistido. No cambia entre reinicios.
  static Future<String> obtener() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, _fileName));
    if (await file.exists()) {
      final id = (await file.readAsString()).trim();
      if (id.isNotEmpty) return id;
    }
    final id = const Uuid().v4();
    await file.writeAsString(id);
    return id;
  }

  static String plataformaActual() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isLinux) return 'linux';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    return 'otro';
  }

  /// Clasificación comercial: PC vs móvil (cupo 1+1).
  static String tipoActual() {
    final p = plataformaActual();
    if (p == 'android' || p == 'ios') return 'movil';
    if (p == 'web') return 'otro';
    return 'pc';
  }

  static String aliasSugerido() {
    final p = plataformaActual();
    switch (p) {
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
