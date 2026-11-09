import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
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
  /// false en login; true tras sesión iniciada.
  static bool promptsEnabled = false;

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

  /// Descarga el APK por streaming (sin cargar todo en RAM) y abre el instalador.
  /// Si falla la descarga in-app, ofrece abrir la misma URL en el navegador (plan B).
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

    // ignore: avoid_print
    print('[UpdateChecker] inicio descarga APK (streaming): ${update.apkUrl}');

    final progress = ValueNotifier<double?>(null);
    var dialogOpen = true;

    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: ValueListenableBuilder<double?>(
            valueListenable: progress,
            builder: (_, value, __) {
              final pct = value;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (pct == null)
                    const CircularProgressIndicator()
                  else
                    LinearProgressIndicator(value: pct.clamp(0.0, 1.0)),
                  const SizedBox(height: 16),
                  Text(
                    pct == null
                        ? 'Descargando actualización...'
                        : 'Descargando... ${(pct * 100).toStringAsFixed(0)}%',
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ));

    void closeProgress() {
      if (dialogOpen && context.mounted) {
        final nav = Navigator.of(context, rootNavigator: true);
        if (nav.canPop()) nav.pop();
        dialogOpen = false;
      }
    }

    Future<void> openInBrowser() async {
      final uri = Uri.tryParse(update.apkUrl);
      if (uri == null) return;
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir: ${update.apkUrl}')),
        );
      }
    }

    final client = http.Client();
    try {
      final uri = Uri.parse(update.apkUrl);
      if (uri.scheme != 'https') {
        throw Exception('La URL del APK debe ser HTTPS');
      }

      final request = http.Request('GET', uri);
      request.headers.addAll({
        'User-Agent': 'FiscoGestRD-Updater/1.0',
        'Accept': '*/*',
      });
      request.followRedirects = true;
      request.maxRedirects = 8;

      final streamed = await client
          .send(request)
          .timeout(const Duration(seconds: 45));

      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        throw Exception('Error al descargar (HTTP ${streamed.statusCode})');
      }

      final total = streamed.contentLength ?? -1;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/fiscogest_update.apk');
      if (await file.exists()) {
        await file.delete();
      }

      final sink = file.openWrite();
      var received = 0;
      try {
        await for (final chunk in streamed.stream.timeout(
          const Duration(seconds: 90),
        )) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) {
            progress.value = received / total;
          }
        }
      } finally {
        await sink.flush();
        await sink.close();
      }

      // APK real de release suele superar varios MB; HTML de error es mucho menor.
      if (received < 5 * 1024 * 1024) {
        try {
          await file.delete();
        } catch (_) {}
        throw Exception(
          'Descarga incompleta o inválida (${(received / 1024).toStringAsFixed(0)} KB).',
        );
      }

      // ignore: avoid_print
      print('[UpdateChecker] APK guardado: ${file.path} ($received bytes)');
      closeProgress();

      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir el instalador: ${result.message}'),
            action: SnackBarAction(
              label: 'Navegador',
              onPressed: openInBrowser,
            ),
          ),
        );
      }
    } on TimeoutException {
      closeProgress();
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Descarga lenta o interrumpida'),
            content: const Text(
              'No se completó la descarga dentro de la app.\n\n'
              'Puedes abrir el enlace en el navegador e instalar el APK desde Descargas.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cerrar'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await openInBrowser();
                },
                child: const Text('Abrir en navegador'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      closeProgress();
      // ignore: avoid_print
      print('[UpdateChecker] ERROR descarga: $e');
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('No se pudo actualizar'),
            content: Text(
              '$e\n\n'
              'Usa el navegador para descargar e instalar manualmente.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cerrar'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await openInBrowser();
                },
                child: const Text('Abrir en navegador'),
              ),
            ],
          ),
        );
      }
    } finally {
      client.close();
      progress.dispose();
    }
  }

  /// Llamar al arrancar la app (después del primer frame).
  static Future<void> checkAndPrompt(BuildContext context) async {
    if (!promptsEnabled) {
      // ignore: avoid_print
      print('[UpdateChecker] prompts deshabilitados (sin sesión)');
      return;
    }
    final update = await check();
    if (update != null && context.mounted) {
      await showUpdateDialog(context, update);
    }
  }
}
