import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';

class BotonesAccionWidget extends StatelessWidget {
  const BotonesAccionWidget({
    super.key,
    required this.onGuardarBorrador,
    required this.onRegistrarCompra,
  });

  final VoidCallback onGuardarBorrador;
  final VoidCallback onRegistrarCompra;

  static const double _btnHeight = 44;
  static const double _maxBarWidth = 420;

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);

    final borrador = SizedBox(
      height: _btnHeight,
      width: mobile ? double.infinity : 160,
      child: OutlinedButton(
        onPressed: onGuardarBorrador,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.allM),
        ),
        child: Text(
          'Guardar borrador',
          style: AppTypography.button.copyWith(color: AppColors.primary),
        ),
      ),
    );

    final registrar = SizedBox(
      height: _btnHeight,
      width: mobile ? double.infinity : 200,
      child: AppButton(
        text: 'Registrar compra',
        onPressed: onRegistrarCompra,
        height: _btnHeight,
        width: mobile ? double.infinity : 200,
      ),
    );

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          registrar,
          AppLayout.vS,
          borrador,
        ],
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxBarWidth),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            borrador,
            AppLayout.hM,
            registrar,
          ],
        ),
      ),
    );
  }
}
