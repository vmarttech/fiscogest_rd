import 'dart:io';

import 'package:fiscogest_rd/features/e_cf/data/gateways/dgii_endpoints.dart';
import 'package:path_provider/path_provider.dart';

class DgiiEspejo {
  static Future<File> _archivo() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/dgii_espejo.txt');
  }

  static Future<void> cargar() async {
    try {
      final archivo = await _archivo();
      final texto = await archivo.exists()
          ? (await archivo.readAsString()).trim()
          : '';
      DgiiEndpoints.modoPractica = texto == 'practica';
    } catch (_) {
      DgiiEndpoints.modoPractica = false;
    }
  }

  static Future<void> guardarModo(bool activo) async {
    DgiiEndpoints.modoPractica = activo;
    final archivo = await _archivo();
    if (!activo) {
      if (await archivo.exists()) await archivo.delete();
      return;
    }
    await archivo.writeAsString('practica');
  }
}
