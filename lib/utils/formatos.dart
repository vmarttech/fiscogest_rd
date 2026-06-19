import 'package:intl/intl.dart';

class Formatos {
  // Formato de moneda dominicana: RD$ 1,234.56
  static final NumberFormat moneda = NumberFormat.currency(
    locale: 'es_DO',
    symbol: 'RD\$ ', // ✅ CORREGIDO: Escapamos el símbolo $
    decimalDigits: 2,
  );

  // Formato de fecha: 14 de Junio de 2026
  static final DateFormat fechaLarga = DateFormat(
    'dd \'de\' MMMM \'de\' yyyy',
    'es_DO',
  );

  // Formato fecha corta: 14/06/2026
  static final DateFormat fechaCorta = DateFormat('dd/MM/yyyy');

  // Formato número con separador de miles
  static final NumberFormat numero = NumberFormat('#,##0.00', 'es_DO');
}
