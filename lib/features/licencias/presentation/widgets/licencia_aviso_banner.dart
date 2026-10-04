import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/features/licencias/presentation/providers/licencia_providers.dart';

/// Banner superior: avisa de prueba/vencimiento y lleva a Licencia.
class LicenciaAvisoBanner extends ConsumerWidget {
  const LicenciaAvisoBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(licenciaActualProvider);

    return async.maybeWhen(
      data: (lic) {
        if (lic == null) return const SizedBox.shrink();
        if (lic.esDesarrollador || lic.vitalicia) {
          return const SizedBox.shrink();
        }

        final porVencer = lic.diasRestantes != null &&
            lic.diasRestantes! >= 0 &&
            lic.diasRestantes! <= 15;
        final mostrar = lic.plan == 'demo' ||
            lic.estado == 'gracia' ||
            lic.estado == 'vencida' ||
            porVencer;
        if (!mostrar) return const SizedBox.shrink();

        final texto = lic.estado == 'vencida'
            ? 'Su licencia venció. Vaya a Configuración → Sistema → Licencia y pagos para elegir su plan.'
            : lic.plan == 'demo'
                ? 'Está en prueba. Vaya a Configuración → Sistema → Licencia y pagos para elegir su plan de pago.'
                : 'Su licencia está por vencer. Vaya a Configuración → Sistema → Licencia y pagos para renovar.';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/licencia'),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      texto,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
                ],
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
