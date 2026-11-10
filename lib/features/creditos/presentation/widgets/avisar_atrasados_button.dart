import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drift/drift.dart' show Value;
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_entity.dart';
import 'package:fiscogest_rd/features/clientes/presentation/providers/cliente_providers.dart';

class AvisarAtrasadosButton extends ConsumerWidget {

  const AvisarAtrasadosButton({
    super.key,
    required this.fiosAtrasados,
  });
  final List<dynamic> fiosAtrasados;

  static String _normalizar(String texto) {
    return texto
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');
  }

  static String? _soloDigitos(String? raw) {
    if (raw == null) return null;
    final digitos = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.length < 7) return null;
    if (digitos.length == 10 && digitos.startsWith('8')) {
      return '1$digitos';
    }
    return digitos;
  }

  static String? _buscarTelefonoCliente(
    String nombreFio,
    List<ClienteEntity> clientes,
  ) {
    if (nombreFio.trim().isEmpty || clientes.isEmpty) return null;
    final nombreNorm = _normalizar(nombreFio);

    for (final c in clientes) {
      final n = _normalizar(c.nombre);
      if (n == nombreNorm) {
        final tel = _soloDigitos(c.telefono);
        if (tel != null) return tel;
      }
    }
    for (final c in clientes) {
      final n = _normalizar(c.nombre);
      if (n.contains(nombreNorm) || nombreNorm.contains(n)) {
        final tel = _soloDigitos(c.telefono);
        if (tel != null) return tel;
      }
    }
    final primera = nombreNorm.split(' ').first;
    if (primera.length >= 3) {
      for (final c in clientes) {
        final n = _normalizar(c.nombre);
        if (n.startsWith(primera) || n.split(' ').first == primera) {
          final tel = _soloDigitos(c.telefono);
          if (tel != null) return tel;
        }
      }
    }
    return null;
  }

  /// Resuelve teléfono: 1) fiao.telefono  2) match en clientes
  static String? _resolverTelefono(
    FioData fio,
    List<ClienteEntity> clientes,
  ) {
    final propio = _soloDigitos(fio.telefono);
    if (propio != null) return propio;
    return _buscarTelefonoCliente(fio.nombreCliente, clientes);
  }

  static Future<void> avisar(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> fiosAtrasados, {
    /// Punto 6: solo fios con al menos [minDiasAtraso] días de atraso
    /// (respecto a fechaCompromiso). 0 = todos los atrasados.
    int minDiasAtraso = 0,
  }) async {
    if (fiosAtrasados.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          width: 320,
          content: Text('No hay fios pendientes de cobro.'),
        ),
      );
      return;
    }

    final ahora = DateTime.now();
    final fios = <FioData>[];
    for (final f in fiosAtrasados) {
      if (f is! FioData) continue;
      if (minDiasAtraso > 0) {
        final compromiso = f.fechaCompromiso;
        if (compromiso == null) continue;
        final dias = ahora.difference(compromiso).inDays;
        if (dias < minDiasAtraso) continue;
      }
      fios.add(f);
    }

    if (fios.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          width: 340,
          content: Text(
            minDiasAtraso > 0
                ? 'No hay fios con $minDiasAtraso+ días de atraso.'
                : 'No hay fios válidos para avisar.',
          ),
        ),
      );
      return;
    }

    var listaClientes = ref.read(clientesControllerProvider).valueOrNull ?? [];
    if (listaClientes.isEmpty) {
      try {
        await ref.read(clientesControllerProvider.notifier).build();
      } catch (_) {}
      listaClientes = ref.read(clientesControllerProvider).valueOrNull ?? [];
    }

    final porTel = <String, Map<String, dynamic>>{};
    final sinTelefono = <FioData>[];

    for (final fio in fios) {
      final telefono = _resolverTelefono(fio, listaClientes);
      if (telefono == null) {
        sinTelefono.add(fio);
        continue;
      }
      if (!porTel.containsKey(telefono)) {
        porTel[telefono] = {
          'nombres': <String>[],
          'saldos': <double>[],
          'fioIds': <int>[],
        };
      }
      porTel[telefono]!['nombres'].add(fio.nombreCliente);
      porTel[telefono]!['saldos'].add(fio.saldoPendiente);
      (porTel[telefono]!['fioIds'] as List<int>).add(fio.id);
    }

    // Punto 3: fallidos con acción — pedir número y persistirlo en el fiao
    if (sinTelefono.isNotEmpty && context.mounted) {
      final resueltos = await _dialogoSinTelefono(context, ref, sinTelefono);
      for (final e in resueltos.entries) {
        final fio = e.key;
        final tel = e.value;
        if (!porTel.containsKey(tel)) {
          porTel[tel] = {
            'nombres': <String>[],
            'saldos': <double>[],
            'fioIds': <int>[],
          };
        }
        porTel[tel]!['nombres'].add(fio.nombreCliente);
        porTel[tel]!['saldos'].add(fio.saldoPendiente);
        (porTel[tel]!['fioIds'] as List<int>).add(fio.id);
      }
    }

    if (!context.mounted) return;

    if (porTel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          width: 340,
          content: Text('No se pudo enviar: no hay números válidos.'),
        ),
      );
      return;
    }

    int enviados = 0;
    int fallidos = 0;

    for (final entrada in porTel.entries) {
      final numero = entrada.key;
      final datos = entrada.value;
      final nombres = (datos['nombres'] as List).join(' + ');
      final total = (datos['saldos'] as List<double>).fold(0.0, (a, b) => a + b);

      final mensaje = Uri.encodeComponent(
        'Estimado(a) $nombres, le informamos que tiene un saldo pendiente de cobro de RD\$ ${total.toStringAsFixed(2)}. '
        'Por favor pasar a cancelar. ¡Gracias!',
      );

      final uri = Uri.parse('https://wa.me/$numero?text=$mensaje');

      try {
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (ok) {
          enviados++;
        } else {
          fallidos++;
        }
      } catch (_) {
        fallidos++;
      }

      if (porTel.length > 1) {
        await Future.delayed(const Duration(milliseconds: 450));
      }
    }

    if (!context.mounted) return;

    final resumen = <String>['$enviados enviado(s)'];
    if (fallidos > 0) resumen.add('$fallidos fallido(s)');
    final quedanSin = sinTelefono.length;
    // sinTelefono se redujo solo visualmente; contamos los que no entraron a porTel por id sería más exacto
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        width: 360,
        content: Text('Se completó: ${resumen.join(" · ")}'),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Diálogo para completar teléfonos faltantes y persistirlos en el fiao.
  static Future<Map<FioData, String>> _dialogoSinTelefono(
    BuildContext context,
    WidgetRef ref,
    List<FioData> faltantes,
  ) async {
    final resueltos = <FioData, String>{};
    final controllers = {
      for (final f in faltantes) f.id: TextEditingController(),
    };

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Faltan teléfonos'),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Estos fios no tienen número. Puede agregarlo ahora '
                    '(se guardará en el fiao para la próxima vez):',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  for (final f in faltantes) ...[
                    Text(
                      f.nombreCliente,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controllers[f.id],
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'WhatsApp / Teléfono',
                        isDense: true,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Omitir'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar y enviar'),
            ),
          ],
        );
      },
    );

    if (ok == true) {
      final db = ref.read(databaseProvider);
      for (final f in faltantes) {
        final raw = controllers[f.id]?.text.trim() ?? '';
        final tel = _soloDigitos(raw);
        if (tel == null) continue;
        resueltos[f] = tel;
        try {
          await (db.update(db.fiosTable)..where((t) => t.id.equals(f.id))).write(
            FiosTableCompanion(telefono: Value(raw.trim())),
          );
        } catch (_) {}
      }
    }

    for (final c in controllers.values) {
      c.dispose();
    }
    return resueltos;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: fiosAtrasados.isEmpty
          ? null
          : () => avisar(context, ref, fiosAtrasados),
      icon: const Icon(Icons.chat_bubble_outline),
      label: const Text('Avisar atrasados'),
    );
  }
}
