import 'package:flutter/material.dart';

abstract class AppRadius {
  static const double xs = 2;
  static const double s = 4;
  static const double m = 8;
  static const double l = 12;
  static const double xl = 16;
  static const double xxl = 24;
  static const double circular = 9999;

  static final BorderRadius allXs = BorderRadius.circular(xs);
  static final BorderRadius allS = BorderRadius.circular(s);
  static final BorderRadius allM = BorderRadius.circular(m);
  static final BorderRadius allL = BorderRadius.circular(l);
  static final BorderRadius allXl = BorderRadius.circular(xl);
  static final BorderRadius allXxl = BorderRadius.circular(xxl);
  static final BorderRadius allCircular = BorderRadius.circular(circular);

  static const BorderRadius tS = BorderRadius.vertical(top: Radius.circular(s));
  static const BorderRadius tM = BorderRadius.vertical(top: Radius.circular(m));
  static const BorderRadius tL = BorderRadius.vertical(top: Radius.circular(l));

  static const BorderRadius bS = BorderRadius.vertical(
    bottom: Radius.circular(s),
  );
  static const BorderRadius bM = BorderRadius.vertical(
    bottom: Radius.circular(m),
  );
  static const BorderRadius bL = BorderRadius.vertical(
    bottom: Radius.circular(l),
  );
}
