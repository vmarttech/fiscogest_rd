import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/estado_ecf_interno.dart';
import 'package:fiscogest_rd/features/e_cf/presentation/providers/ecfe_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EcfeEstadoChip extends ConsumerWidget {
  const EcfeEstadoChip({super.key, required this.ventaId});
  final int ventaId;

  Color _color(EstadoEcfInterno e) {
    if (e.esTerminalExito) return AppColors.success;
    if (e == EstadoEcfInterno.rechazado ||
        e == EstadoEcfInterno.errorTecnico ||
        e == EstadoEcfInterno.validacionFallida) {
      return AppColors.error;
    }
    if (e == EstadoEcfInterno.enviado || e == EstadoEcfInterno.enProceso) {
      return const Color(0xFFE65100);
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ecfePorVentaProvider(ventaId));
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (doc) {
        if (doc == null) return const SizedBox.shrink();
        final c = _color(doc.estado);
        return ActionChip(
          avatar: Icon(Icons.qr_code_2, size: 18, color: c),
          label: Text(
            'e-CF: ${doc.estado.etiqueta}'
            '${doc.encf != null ? ' · ${doc.encf}' : ''}',
            style: TextStyle(color: c, fontSize: 12),
          ),
          backgroundColor: c.withValues(alpha: 0.12),
          onPressed: () {
            if (doc.id != null) {
              context.push('/ecfe/${doc.id}');
            } else {
              context.push('/ecfe');
            }
          },
        );
      },
    );
  }
}
