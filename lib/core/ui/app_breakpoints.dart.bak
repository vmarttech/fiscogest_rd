import 'package:flutter/material.dart';

abstract class AppBreakpoints {
  static const double mobile = 360;
  static const double mobileLarge = 480;
  static const double tablet = 768;
  static const double tabletLarge = 1024;
  static const double desktop = 1280;
  static const double desktopLarge = 1440;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < tablet;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet &&
      MediaQuery.of(context).size.width < desktop;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;
}
