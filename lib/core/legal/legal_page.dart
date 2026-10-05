import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fiscogest_rd/core/legal/legal_texts.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';

enum LegalDocumento { privacidad, terminos }

class LegalPage extends StatelessWidget {
  const LegalPage({super.key, required this.documento});

  final LegalDocumento documento;

  static const routePrivacidad = 'legal-privacidad';
  static const routeTerminos = 'legal-terminos';
  static const pathPrivacidad = '/legal/privacidad';
  static const pathTerminos = '/legal/terminos';

  @override
  Widget build(BuildContext context) {
    final esPriv = documento == LegalDocumento.privacidad;
    final titulo = esPriv ? 'Privacidad' : 'Terminos de uso';
    final cuerpo = esPriv ? kPrivacidadResumen : kTerminosResumen;
    final url = esPriv ? kUrlPrivacidad : kUrlTerminos;

    return AppScaffold(
      title: titulo,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            esPriv
                ? 'Politica de privacidad del software FiscoGest RD'
                : 'Terminos de la licencia de uso del software',
            style: AppTypography.h4.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            cuerpo,
            style: AppTypography.bodyMedium.copyWith(height: 1.45),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () async {
              final uri = Uri.parse(url);
              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (_) {}
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Abrir version web'),
          ),
          const SizedBox(height: 8),
          Text(
            'Si el sitio aun no esta publicado, el texto de esta pantalla '
            'es el documento vigente.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/login');
              }
            },
            child: const Text('Volver'),
          ),
        ],
      ),
    );
  }
}
