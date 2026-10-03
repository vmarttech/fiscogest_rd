import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_sizes.dart';

/// Barra de acciones compacta. En PC no se estira a todo el monitor.
class AppActionBar extends StatelessWidget {
  const AppActionBar({
    super.key,
    required this.actions,
    this.alignment = WrapAlignment.center,
    this.spacing = 12,
    this.runSpacing = 8,
    this.surface = false,
    this.maxWidth,
  });

  final List<Widget> actions;
  final WrapAlignment alignment;
  final double spacing;
  final double runSpacing;

  /// Fondo tipo dock (ideal pegado abajo del scaffold).
  final bool surface;

  /// Limita el ancho de la barra en PC (default formMaxWidth).
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    final bar = mobile
        ? Row(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) SizedBox(width: spacing),
                Expanded(child: actions[i]),
              ],
            ],
          )
        : Wrap(
            alignment: alignment,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: spacing,
            runSpacing: runSpacing,
            children: actions,
          );

    final capped = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? AppSizes.formMaxWidth,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: mobile ? 12 : 16,
            vertical: surface ? 10 : 4,
          ),
          child: bar,
        ),
      ),
    );

    if (!surface) return capped;

    return Material(
      elevation: 8,
      shadowColor: Colors.black26,
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.97),
      child: SafeArea(
        top: false,
        child: capped,
      ),
    );
  }
}
