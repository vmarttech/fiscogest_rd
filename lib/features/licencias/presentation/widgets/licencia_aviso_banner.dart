import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/store/store_channel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/auth/dueno_plataforma.dart';
import 'package:fiscogest_rd/core/auth/sesion_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/features/licencias/domain/licencia_gates.dart';
import 'package:fiscogest_rd/features/licencias/presentation/providers/licencia_providers.dart';

/// Banner de estado de licencia y consumo mensual del plan Gratis.
class LicenciaAvisoBanner extends ConsumerWidget {
  const LicenciaAvisoBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(licenciaActualProvider);

    return async.maybeWhen(
      data: (lic) {
        if (lic == null) {
          return _banner(
            context,
            texto:
                'Licencia pendiente de validación. Registra o vincula tu negocio para iniciar.',
            icon: Icons.verified_user_outlined,
            color: Colors.blueGrey.shade700,
            onTap: () => context.push('/setup-cuenta'),
          );
        }
        if ((lic.esDesarrollador || lic.vitalicia) &&
            esDuenoPlataforma(ref.watch(sesionProvider)?.username)) {
          return const SizedBox.shrink();
        }

        final gates = LicenciaGates(lic);
        final mobile = MediaQuery.sizeOf(context).width < 600;
        final porVencer =
            lic.diasRestantes != null &&
            lic.diasRestantes! >= 0 &&
            lic.diasRestantes! <= 15 &&
            lic.plan != 'gratis' &&
            lic.plan != 'demo';

        final mostrar =
            lic.plan == 'demo' ||
            lic.plan == 'gratis' ||
            lic.estado == 'gracia' ||
            lic.estado == 'vencida' ||
            lic.estado == 'registro_requerido' ||
            porVencer;
        if (!mostrar) return const SizedBox.shrink();

        late final String texto;
        late final Color bg;
        late final IconData icon;

        if (lic.estado == 'registro_requerido') {
          texto =
              'La prueba terminó. Completa el registro para continuar con el plan Gratis.';
          bg = const Color(0xFFB91C1C);
          icon = Icons.person_add_alt_1_outlined;
        } else if (lic.estado == 'vencida' && lic.plan != 'gratis') {
          texto = storeOcultaCompraTransferencia
              ? 'Licencia vencida. Vaya a Configuración → Licencia para activar o renovar.'
              : 'Licencia vencida. Configuración → Sistema → Licencia y pagos para elegir plan.';
          bg = const Color(0xFFB91C1C);
          icon = Icons.error_outline;
        } else if (lic.estado == 'gracia') {
          final d = lic.diasGraciaRestantes;
          texto = d != null
              ? 'Prueba gratuita · $d días de gracia restantes.'
              : 'Prueba gratuita en período de gracia.';
          bg = const Color(0xFFC2410C);
          icon = Icons.schedule;
        } else if (lic.plan == 'gratis') {
          final uso =
              ref.watch(licenciaUsoGratisProvider).valueOrNull ??
              const <String, int>{};
          final prod = gates.maxProductos ?? 20;
          final cli = gates.maxClientes ?? 30;
          final ven = gates.maxVentasMes ?? 15;
          texto = mobile
              ? 'Gratis · ventas ${uso['ventas'] ?? 0}/$ven · productos ${uso['productos'] ?? 0}/$prod · clientes ${uso['clientes'] ?? 0}/$cli'
              : 'Gratis este mes: ventas ${uso['ventas'] ?? 0}/$ven, productos ${uso['productos'] ?? 0}/$prod, clientes ${uso['clientes'] ?? 0}/$cli.';
          bg = Theme.of(context).colorScheme.primary;
          icon = Icons.workspace_premium_outlined;
        } else if (lic.plan == 'demo') {
          final d = lic.diasRestantes;
          texto = d != null
              ? mobile
                    ? 'Prueba · $d días restantes · acceso completo'
                    : 'Prueba gratuita: $d días restantes con acceso completo. Luego puedes registrarte en el plan Gratis.'
              : 'Prueba gratuita con acceso completo. Luego puedes registrarte en el plan Gratis.';
          bg = Theme.of(context).colorScheme.primary;
          icon = Icons.info_outline;
        } else {
          final d = lic.diasRestantes;
          texto = d != null
              ? 'Licencia por vencer ($d días). Renueve en Licencia y pagos.'
              : 'Licencia por vencer. Renueve en Configuración → Licencia y pagos.';
          bg = const Color(0xFFB45309);
          icon = Icons.notification_important_outlined;
        }

        final textoCompacto = texto
            .replaceAll('Configuración → ', '')
            .replaceAll('Toque para mejorar su plan.', '· Ver planes');

        return _banner(
          context,
          texto: mobile ? texto : textoCompacto,
          icon: icon,
          color: bg,
          onTap: () => lic.estado == 'registro_requerido'
              ? context.push('/setup-cuenta')
              : context.push('/licencia'),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _banner(
    BuildContext context, {
    required String texto,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 5, 12, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  texto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.white70, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
