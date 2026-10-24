import 'package:flutter/material.dart';

/// Anchos de referencia FiscoGest.
///
/// - **Teléfono**: [shortestSide] < 600 (portrait y landscape).
/// - **Tablet** (lado corto ≥ 600, ancho &lt; 1024).
/// - **Escritorio** (ancho ≥ 1024 / chrome ancho).
///
/// Un celular en horizontal no debe activar sidebar ni layout PC.
abstract class AppBreakpoints {
  static const double mobile = 360;
  static const double mobileLarge = 480;
  static const double tablet = 768;
  static const double tabletLarge = 1024;
  static const double desktop = 1024;
  static const double desktopLarge = 1440;

  /// Sidebar fijo y cabeceras de escritorio.
  static const double wideChrome = 900;

  /// Lado corto típico de teléfono (Material).
  static const double phoneShortest = 600;

  static Size sizeOf(BuildContext context) => MediaQuery.sizeOf(context);

  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  static bool isPortrait(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.portrait;

  /// Teléfono real: vertical u horizontal (no usar solo width).
  static bool isMobile(BuildContext context) =>
      sizeOf(context).shortestSide < phoneShortest;

  /// Tablet por ancho (ventana intermedia), excluyendo teléfonos.
  static bool isTablet(BuildContext context) {
    final s = sizeOf(context);
    if (s.shortestSide < phoneShortest) return false;
    return s.width >= tablet && s.width < desktop;
  }

  /// Escritorio / ventana ancha.
  static bool isDesktop(BuildContext context) {
    final s = sizeOf(context);
    if (s.shortestSide < phoneShortest) return false;
    return s.width >= desktop;
  }

  /// Una columna / drawer: teléfonos.
  static bool isCompact(BuildContext context) => isMobile(context);

  /// Sidebar permanente + header tipo escritorio.
  /// Nunca en teléfono (aunque esté en landscape con ancho > 900).
  static bool useWideChrome(BuildContext context) {
    final s = sizeOf(context);
    if (s.shortestSide < phoneShortest) return false;
    if (s.width >= wideChrome) return true;
    if (s.width >= tablet && isLandscape(context)) return true;
    return false;
  }

  /// Formularios y grids en 2+ columnas.
  static bool useMultiColumn(BuildContext context) => !isCompact(context);

  /// Padding horizontal exterior del contenido.
  static double contentHorizontalPadding(BuildContext context) {
    final w = sizeOf(context).width;
    if (isMobile(context)) return 12;
    if (w < desktop) return 16;
    return 24;
  }
}
