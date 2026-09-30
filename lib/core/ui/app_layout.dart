import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';

abstract class AppLayout {
  // Filas estándar
  static Row row({
    Key? key,
    List<Widget> children = const [],
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    EdgeInsetsGeometry? padding,
  }) => Row(
    key: key,
    mainAxisAlignment: mainAxisAlignment,
    crossAxisAlignment: crossAxisAlignment,
    children: children,
  );

  // Columnas estándar
  static Column column({
    Key? key,
    List<Widget> children = const [],
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.stretch,
    EdgeInsetsGeometry? padding,
  }) => Column(
    key: key,
    mainAxisAlignment: mainAxisAlignment,
    crossAxisAlignment: crossAxisAlignment,
    children: children,
  );

  // Separadores automáticos
  static Spacer spacer([int flex = 1]) => Spacer(flex: flex);
  static const Widget hXs = SizedBox(width: AppSpacing.xs);
  static const Widget hS = SizedBox(width: AppSpacing.s);
  static const Widget hM = SizedBox(width: AppSpacing.m);
  static const Widget hL = SizedBox(width: AppSpacing.l);
  static const Widget hXl = SizedBox(width: AppSpacing.xl);
  static const Widget vXs = SizedBox(height: AppSpacing.xs);
  static const Widget vS = SizedBox(height: AppSpacing.s);
  static const Widget vM = SizedBox(height: AppSpacing.m);
  static const Widget vL = SizedBox(height: AppSpacing.l);
  static const Widget vXl = SizedBox(height: AppSpacing.xl);

  // Centrado inteligente por pantalla
  static Widget centerConstrained({
    required Widget child,
    int maxWidth = 1320,
  }) {
    return Center(
      child: Container(
        alignment: Alignment.topCenter,
        constraints: BoxConstraints(maxWidth: maxWidth.toDouble()),
        child: child,
      ),
    );
  }

  // Padding universal
  static const EdgeInsetsGeometry pantallaPadding = EdgeInsets.only(
    left: AppSpacing.m,
    right: AppSpacing.m,
    top: AppSpacing.m,
    bottom: AppSpacing.m,
  );

  // ✅ NUEVO: Fila estándar Etiqueta ↔ Valor
  static Widget filaDato({
    required String etiqueta,
    required String valor,
    TextStyle? estiloEtiqueta,
    TextStyle? estiloValor,
    bool alinearDerecha = true,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      vertical: AppSpacing.xs,
    ),
  }) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: estiloEtiqueta ?? AppTypography.labelMedium),
          Text(
            valor,
            style: estiloValor ?? AppTypography.labelMedium,
            textAlign: alinearDerecha ? TextAlign.right : null,
          ),
        ],
      ),
    );
  }
}

// Diseño adaptativo Fila / Columna
class ResponsiveRow extends StatelessWidget {
  const ResponsiveRow({
    super.key,
    required this.child1,
    required this.child2,
    this.breakpoint = 600,
    this.spacing,
  });
  final Widget child1;
  final Widget child2;
  final double breakpoint;
  final double? spacing;
  @override
  Widget build(BuildContext context) {
    final anchoPantalla = MediaQuery.of(context).size.width;
    final espacio = spacing ?? AppSpacing.m;
    if (anchoPantalla >= breakpoint) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: child1),
          SizedBox(width: espacio),
          Expanded(child: child2),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child1,
        SizedBox(height: espacio),
        child2,
      ],
    );
  }
}
