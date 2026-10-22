import 'package:flutter/material.dart';

/// Anchos de referencia FiscoGest.
///
/// - **Móvil** (&lt; 768): UI en columna, menú drawer.
/// - **Tablet** (768–1023): en vertical ≈ móvil ampliado; en **horizontal**
///   usa chrome ancho (sidebar) como escritorio.
/// - **Escritorio** (≥ 1024): sidebar fijo + layouts multi-columna.
abstract class AppBreakpoints {
  static const double mobile = 360;
  static const double mobileLarge = 480;
  static const double tablet = 768;
  static const double tabletLarge = 1024;
  static const double desktop = 1024;
  static const double desktopLarge = 1440;

  /// Sidebar fijo y cabeceras de escritorio (tablet landscape típica ≥ 900).
  static const double wideChrome = 900;

  static Size sizeOf(BuildContext context) => MediaQuery.sizeOf(context);

  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  static bool isPortrait(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.portrait;

  /// Ancho &lt; 768 (teléfono / ventana estrecha).
  static bool isMobile(BuildContext context) =>
      sizeOf(context).width < tablet;

  /// 768 ≤ ancho &lt; 1024.
  static bool isTablet(BuildContext context) {
    final w = sizeOf(context).width;
    return w >= tablet && w < desktop;
  }

  /// Ancho ≥ 1024.
  static bool isDesktop(BuildContext context) =>
      sizeOf(context).width >= desktop;

  /// Una columna / drawer: solo móvil real (no tablet horizontal).
  static bool isCompact(BuildContext context) => isMobile(context);

  /// Sidebar permanente + header tipo escritorio.
  /// Incluye tablet en horizontal aunque el ancho sea 768–899.
  static bool useWideChrome(BuildContext context) {
    final w = sizeOf(context).width;
    if (w >= wideChrome) return true;
    if (w >= tablet && isLandscape(context)) return true;
    return false;
  }

  /// Formularios y grids en 2+ columnas.
  static bool useMultiColumn(BuildContext context) => !isCompact(context);

  /// Padding horizontal exterior del contenido.
  static double contentHorizontalPadding(BuildContext context) {
    final w = sizeOf(context).width;
    if (w < tablet) return 12;
    if (w < desktop) return 16;
    return 24;
  }
}
