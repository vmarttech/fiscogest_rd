import 'package:flutter/material.dart';

abstract class AppSpacing {
  // Escala base
  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // EdgeInsets predefinidos
  static const EdgeInsets allXs = EdgeInsets.all(xs);
  static const EdgeInsets allS = EdgeInsets.all(s);
  static const EdgeInsets allM = EdgeInsets.all(m);
  static const EdgeInsets allL = EdgeInsets.all(l);
  static const EdgeInsets allXl = EdgeInsets.all(xl);

  static const EdgeInsets hXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets hS = EdgeInsets.symmetric(horizontal: s);
  static const EdgeInsets hM = EdgeInsets.symmetric(horizontal: m);
  static const EdgeInsets hL = EdgeInsets.symmetric(horizontal: l);
  static const EdgeInsets hXl = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets vXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets vS = EdgeInsets.symmetric(vertical: s);
  static const EdgeInsets vM = EdgeInsets.symmetric(vertical: m);
  static const EdgeInsets vL = EdgeInsets.symmetric(vertical: l);
  static const EdgeInsets vXl = EdgeInsets.symmetric(vertical: xl);

  static const EdgeInsets tS = EdgeInsets.only(top: s);
  static const EdgeInsets tM = EdgeInsets.only(top: m);
  static const EdgeInsets tL = EdgeInsets.only(top: l);

  static const EdgeInsets bS = EdgeInsets.only(bottom: s);
  static const EdgeInsets bM = EdgeInsets.only(bottom: m);
  static const EdgeInsets bL = EdgeInsets.only(bottom: l);

  static const EdgeInsets lS = EdgeInsets.only(left: s);
  static const EdgeInsets lM = EdgeInsets.only(left: m);

  static const EdgeInsets rS = EdgeInsets.only(right: s);
  static const EdgeInsets rM = EdgeInsets.only(right: m);
}
