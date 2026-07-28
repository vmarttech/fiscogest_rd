import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';

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
    int maxWidth = 1200,
  }) {
    return Center(
      child: Container(
        alignment: Alignment.topCenter,
        constraints: BoxConstraints(maxWidth: maxWidth.toDouble()),
        child: child,
      ),
    );
  }
}
