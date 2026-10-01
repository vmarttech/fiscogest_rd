import 'package:intl/intl.dart';

/// Formato unificado de moneda dominicana en toda la app.
/// Ejemplo: formatRd(1234.5) → RD$1.234.50
final NumberFormat appRdFormat = NumberFormat('#,##0', 'de_DE');
final NumberFormat appEnteroFormat = NumberFormat('#,##0', 'es_DO');

String formatRd(num value) => 'RD\$${formatRdNumero(value)}';

/// Sin prefijo (campos de entrada, ejes de gráfico).
String formatRdNumero(num value) {
  final centavos = (value.abs() * 100).round();
  final entero = centavos ~/ 100;
  final decimal = (centavos % 100).toString().padLeft(2, '0');
  final signo = value < 0 ? '-' : '';
  return '$signo${appRdFormat.format(entero)}.$decimal';
}

String formatEntero(num value) => appEnteroFormat.format(value);
