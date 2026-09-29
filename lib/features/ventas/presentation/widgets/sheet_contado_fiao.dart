import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';

enum ResultadoCobro { contado, fiao }

/// Sheet de cierre en modo simplificado: Contado (caja) o Fiao (deuda).
class SheetContadoFiao extends StatelessWidget {
  const SheetContadoFiao({
    super.key,
    required this.totalTexto,
    this.nombreCliente,
  });

  final String totalTexto;
  final String? nombreCliente;

  static Future<ResultadoCobro?> show(
    BuildContext context, {
    required String totalTexto,
    String? nombreCliente,
  }) {
    return showModalBottomSheet<ResultadoCobro>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SheetContadoFiao(
        totalTexto: totalTexto,
        nombreCliente: nombreCliente,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cliente = (nombreCliente ?? '').trim();
    final tieneCliente = cliente.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '¿Cómo cobra?',
            style: AppTypography.h4.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Total: $totalTexto',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tieneCliente ? 'Cliente: $cliente' : 'Cliente: sin nombre',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _OpcionCobro(
            icon: Icons.payments_rounded,
            titulo: 'CONTADO',
            subtitulo: 'Caja → factura al momento',
            color: AppColors.primary,
            onTap: () => Navigator.pop(context, ResultadoCobro.contado),
          ),
          const SizedBox(height: 10),
          _OpcionCobro(
            icon: Icons.edit_note_rounded,
            titulo: 'FIAO',
            subtitulo: 'Anotar lo que debe el cliente',
            color: AppColors.warning,
            onTap: () => Navigator.pop(context, ResultadoCobro.fiao),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpcionCobro extends StatelessWidget {
  const _OpcionCobro({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String titulo;
  final String subtitulo;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
