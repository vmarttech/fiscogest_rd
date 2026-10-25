import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/features/licencias/domain/planes_precios.dart';

/// Al entrar a una función no incluida en el plan → upgrade (menú siempre visible).
class PlanRequeridoAlmacenes extends StatelessWidget {
  const PlanRequeridoAlmacenes({
    super.key,
    required this.titulo,
    this.planActual = 'gratis',
    this.funcion = 'almacenes',
  });

  final String titulo;
  final String planActual;
  final String funcion;

  @override
  Widget build(BuildContext context) {
    final min = planMinimoPara(funcion);
    final msg =
        'Tu plan ${nombrePlanUi(planActual)} no incluye esta función. '
        'Actualiza a ${nombrePlanUi(min)} para usarla.';

    return AppScaffold(
      title: titulo,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 36,
                    color: Color(0xFF0F766E),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Función de plan superior',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  msg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () => context.push('/licencia/comprar'),
                    icon: const Icon(Icons.workspace_premium_outlined),
                    label: const Text(
                      'Ver planes y pagar',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Más tarde'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
