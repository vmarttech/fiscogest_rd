import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/features/licencias/domain/licencia_gates.dart';
import 'package:fiscogest_rd/features/licencias/presentation/providers/licencia_providers.dart';

/// Banner superior: demo / gratis / por vencer / vencida → Licencia.
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

        final gates = LicenciaGates(lic);
        final porVencer = lic.diasRestantes != null &&
            lic.diasRestantes! >= 0 &&
            lic.diasRestantes! <= 15 &&
            lic.plan != 'gratis' &&
            lic.plan != 'demo';

        final mostrar = lic.plan == 'demo' ||
            lic.plan == 'gratis' ||
            lic.estado == 'gracia' ||
            lic.estado == 'vencida' ||
            porVencer;
        if (!mostrar) return const SizedBox.shrink();

        late final String texto;
        late final Color bg;
        late final IconData icon;

        if (lic.estado == 'vencida' && lic.plan != 'gratis') {
          texto =
              'Licencia vencida. Configuración → Sistema → Licencia y pagos para elegir plan.';
          bg = const Color(0xFFB91C1C);
          icon = Icons.error_outline;
        } else if (lic.estado == 'gracia') {
          final d = lic.diasRestantes;
          texto = d != null
              ? 'Periodo de gracia ($d días). Renueve en Licencia y pagos.'
              : 'Periodo de gracia. Renueve en Configuración → Licencia y pagos.';
          bg = const Color(0xFFC2410C);
          icon = Icons.schedule;
        } else if (lic.plan == 'gratis') {
          final fiao = gates.maxCuentasFiao ?? 25;
          final prod = gates.maxProductos ?? 50;
          final cli = gates.maxClientes ?? 30;
          final ven = gates.maxVentasMes ?? 40;
          texto =
              'Plan gratis · límites: $prod productos, $cli clientes, '
              '$ven ventas/mes, fiao $fiao. Toque para mejorar su plan.';
          bg = const Color(0xFF0F766E);
          icon = Icons.workspace_premium_outlined;
        } else if (lic.plan == 'demo') {
          final d = lic.diasRestantes;
          texto = d != null
              ? 'Prueba: $d días restantes. Elija plan de pago en Licencia y pagos.'
              : 'Está en prueba. Elija plan de pago en Configuración → Licencia y pagos.';
          bg = const Color(0xFF0F766E);
          icon = Icons.info_outline;
        } else {
          final d = lic.diasRestantes;
          texto = d != null
              ? 'Licencia por vencer ($d días). Renueve en Licencia y pagos.'
              : 'Licencia por vencer. Renueve en Configuración → Licencia y pagos.';
          bg = const Color(0xFFB45309);
          icon = Icons.notification_important_outlined;
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/licencia'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: bg.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 20),
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
