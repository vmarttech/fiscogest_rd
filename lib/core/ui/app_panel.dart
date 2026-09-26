import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';

/// Contenedor de listados / bloques principales (mismo lenguaje que Inicio).
class AppPanel extends StatelessWidget {
  const AppPanel({
    super.key,
    required this.child,
    this.header,
    this.padding = EdgeInsets.zero,
    this.clip = true,
  });

  final Widget child;
  final Widget? header;
  final EdgeInsetsGeometry padding;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey900.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header != null) header!,
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// Cabecera de columnas tipo tabla (desktop).
class AppPanelHeader extends StatelessWidget {
  const AppPanelHeader({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: children),
    );
  }
}
