import 'dart:async';
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
      // ignore: avoid_print
      print('[UpdateChecker] local version=${info.version} build=${info.buildNumber} code=$currentCode');
      final uri = Uri.parse(kUpdateJsonUrl).replace(
        queryParameters: {
          't': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      // ignore: avoid_print
      print('[UpdateChecker] GET $uri');
      final res = await http
          .get(uri, headers: const {
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
          })
          .timeout(const Duration(seconds: 12));
      // ignore: avoid_print
      print('[UpdateChecker] status=${res.statusCode} bodyLen=${res.body.length}');
      if (res.statusCode != 200) {
        // ignore: avoid_print
        print('[UpdateChecker] abort: bad status');
        return null;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final remote = UpdateInfo.fromJson(data);
      // ignore: avoid_print
      print('[UpdateChecker] remote name=${remote.versionName} code=${remote.versionCode}');
      if (remote.versionCode > currentCode && remote.apkUrl.isNotEmpty) {
        // ignore: avoid_print
        print('[UpdateChecker] UPDATE AVAILABLE');
        return remote;
      }
      // ignore: avoid_print
      print('[UpdateChecker] no update (remote<=local or empty apkUrl)');
      return null;
    } catch (e, st) {
      // ignore: avoid_print
      print('[UpdateChecker] ERROR: $e');
      // ignore: avoid_print
      print(st);
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

    // NO usar await showDialog: bloquearía la descarga hasta cerrar el diálogo.
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(child: Text('Descargando actualización...')),
            ],
          ),
        ),
      ),
    ));

    var dialogOpen = true;
    void closeProgress() {
      if (dialogOpen && context.mounted) {
        final nav = Navigator.of(context, rootNavigator: true);
        if (nav.canPop()) nav.pop();
        dialogOpen = false;
      }
    }

    try {
      final res = await http
          .get(Uri.parse(update.apkUrl))
          .timeout(const Duration(minutes: 3));
      if (res.statusCode != 200) {
        throw Exception('Error al descargar (${res.statusCode})');
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/fiscogest_update.apk');
      await file.writeAsBytes(res.bodyBytes);

      closeProgress();

      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir el instalador: ${result.message}'),
          ),
        );
      }
    } catch (e) {
      closeProgress();
      if (context.mounted) {
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
