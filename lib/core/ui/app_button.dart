import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_sizes.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.iconRight = false,
    this.height = AppSizes.buttonHeightMd,
    this.width,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final bool iconRight;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = (isDisabled || isLoading) ? null : onPressed;
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: effectiveOnPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.grey300,
          foregroundColor: AppColors.white,
          disabledForegroundColor: AppColors.grey500,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.allM),
          textStyle: AppTypography.button,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.white,
        ),
      );
    }

    // ✅ AQUÍ SE DECLARAN LAS VARIABLES QUE FALTABAN
    final iconWidget = icon != null
        ? Icon(icon, size: AppSizes.iconMd)
        : const SizedBox.shrink();
    final textWidget = Text(text);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: icon == null
          ? [textWidget]
          : iconRight
          ? [textWidget, const SizedBox(width: 8), iconWidget]
          : [iconWidget, const SizedBox(width: 8), textWidget],
    );

    // En barras de acción estrechas (móvil), conserva la etiqueta en una línea
    // reduciéndola suavemente dentro del ancho disponible.
    return LayoutBuilder(
      builder: (context, constraints) => constraints.hasBoundedWidth
          ? FittedBox(fit: BoxFit.scaleDown, child: content)
          : content,
    );
  }
}
