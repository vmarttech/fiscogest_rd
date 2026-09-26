import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_sizes.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignTop = true,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool alignTop;

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    final w = maxWidth ?? AppSizes.maxContentWidth;

    // Margen exterior SIEMPRE en PC → se ve el fondo a los lados
    final outer = mobile
        ? EdgeInsets.zero
        : const EdgeInsets.symmetric(horizontal: AppSpacing.l);

    Widget content = child;
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    return Padding(
      padding: outer,
      child: Align(
        alignment: alignTop ? Alignment.topCenter : Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: w),
          child: SizedBox(width: double.infinity, child: content),
        ),
      ),
    );
  }
}
