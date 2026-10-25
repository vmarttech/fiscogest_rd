
/// Credenciales PayPal (Sandbox). En producción: solo backend.
///
/// Ejecutar:
///   flutter run --dart-define=PAYPAL_CLIENT_ID=xxx --dart-define=PAYPAL_SECRET=yyy
///
/// Obtén Client ID / Secret en https://developer.paypal.com → Apps & Credentials.
library;

class PaypalConfig {
  PaypalConfig._();

  static const clientId = String.fromEnvironment(
    'PAYPAL_CLIENT_ID',
    defaultValue: '',
  );
  static const secret = String.fromEnvironment(
    'PAYPAL_SECRET',
    defaultValue: '',
  );

  /// true = api-m.sandbox.paypal.com
  static const sandbox = bool.fromEnvironment(
    'PAYPAL_SANDBOX',
    defaultValue: true,
  );

  static String get baseUrl => sandbox
      ? 'https://api-m.sandbox.paypal.com'
      : 'https://api-m.paypal.com';

  static const returnUrl = 'https://fiscogest.local/paypal/return';
  static const cancelUrl = 'https://fiscogest.local/paypal/cancel';

  static bool get configurado =>
      clientId.isNotEmpty && secret.isNotEmpty;
}
