import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

/// URL del manifiesto de versión (público en GitHub).
const String kUpdateJsonUrl =
    'https://raw.githubusercontent.com/vmarttech/fiscogest_rd/main/update.json';

class UpdateInfo {

  UpdateInfo({
    required this.versionName,
    required this.versionCode,
    required this.apkUrl,
    required this.changelog,
    required this.forceUpdate,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      versionName: json['versionName'] as String? ?? '',
      versionCode: (json['versionCode'] as num?)?.toInt() ?? 0,
      apkUrl: json['apkUrl'] as String? ?? '',
      changelog: json['changelog'] as String? ?? '',
      forceUpdate: json['forceUpdate'] as bool? ?? false,
    );
  }
  final String versionName;
  final int versionCode;
  final String apkUrl;
  final String changelog;
  final bool forceUpdate;
}

class UpdateChecker {
  /// Comprueba si hay versión nueva. Devuelve null si no hay update o hay error.
  static Future<UpdateInfo?> check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(info.buildNumber) ?? 0;
      final uri = Uri.parse(kUpdateJsonUrl).replace(
        queryParameters: {
          't': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      final res = await http
          .get(uri, headers: const {
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
          })
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final remote = UpdateInfo.fromJson(data);
      if (remote.versionCode > currentCode && remote.apkUrl.isNotEmpty) {
        return remote;
      }
      return null;
    } catch (_) {
      // Sin internet o error: no molestar al usuario
      return null;
    }
  }

  /// Muestra el diálogo de actualización (llamar con un BuildContext válido).
  static Future<void> showUpdateDialog(
    BuildContext context,
    UpdateInfo update,
  ) async {
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: !update.forceUpdate,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Nueva versión disponible'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Versión ${update.versionName}'),
              const SizedBox(height: 8),
              if (update.changelog.isNotEmpty) Text(update.changelog),
            ],
          ),
          actions: [
            if (!update.forceUpdate)
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Más tarde'),
              ),
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _downloadAndInstall(context, update);
              },
              child: const Text('Actualizar'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _downloadAndInstall(
    BuildContext context,
    UpdateInfo update,
  ) async {
    // Pedir permiso de instalar apps desconocidas (Android 8+)
    if (Platform.isAndroid) {
      final status = await Permission.requestInstallPackages.request();
      if (!status.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Necesitas permitir instalar apps desde esta fuente.',
              ),
            ),
          );
        }
        await openAppSettings();
        return;
      }
    }

    if (!context.mounted) return;

    // Diálogo de progreso
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('Descargando actualización...')),
          ],
        ),
      ),
    );

    try {
      final res = await http.get(Uri.parse(update.apkUrl));
      if (res.statusCode != 200) {
        throw Exception('Error al descargar (${res.statusCode})');
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/fiscogest_update.apk');
      await file.writeAsBytes(res.bodyBytes);

      if (context.mounted) Navigator.of(context).pop(); // cierra progreso

      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el instalador: ${result.message}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // cierra progreso si sigue abierto
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
    }
  }

  /// Llamar al arrancar la app (después del primer frame).
  static Future<void> checkAndPrompt(BuildContext context) async {
    final update = await check();
    if (update != null && context.mounted) {
      await showUpdateDialog(context, update);
    }
  }
}
