import 'package:intl/intl.dart';

/// Formato unificado de moneda dominicana en toda la app.
/// Uso: Text(formatRd(1234.5)) → RD$ 1,234.50
final NumberFormat appRdFormat = NumberFormat('#,##0.00', 'es_DO');
final NumberFormat appEnteroFormat = NumberFormat('#,##0', 'es_DO');

String formatRd(num value) => 'RD\$ ${appRdFormat.format(value)}';

/// Sin prefijo (campos de entrada, ejes de gráfico).
String formatRdNumero(num value) => appRdFormat.format(value);

String formatEntero(num value) => appEnteroFormat.format(value);
