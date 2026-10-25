
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:fiscogest_rd/features/licencias/domain/paypal_config.dart';

class PaypalOrderResult {
  const PaypalOrderResult({
    required this.orderId,
    required this.approveUrl,
  });
  final String orderId;
  final String approveUrl;
}

class PaypalService {
  String? _token;
  DateTime? _tokenExp;

  Future<String> _accessToken() async {
    if (_token != null &&
        _tokenExp != null &&
        DateTime.now().isBefore(_tokenExp!)) {
      return _token!;
    }
    if (!PaypalConfig.configurado) {
      throw Exception(
        'PayPal no configurado. Usa --dart-define=PAYPAL_CLIENT_ID=... '
        'y --dart-define=PAYPAL_SECRET=...',
      );
    }
    final basic = base64Encode(
      utf8.encode('${PaypalConfig.clientId}:${PaypalConfig.secret}'),
    );
    final res = await http.post(
      Uri.parse('${PaypalConfig.baseUrl}/v1/oauth2/token'),
      headers: {
        'Authorization': 'Basic $basic',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'grant_type=client_credentials',
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('PayPal auth ${res.statusCode}: ${res.body}');
    }
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    _token = map['access_token'] as String;
    final secs = (map['expires_in'] as num?)?.toInt() ?? 300;
    _tokenExp = DateTime.now().add(Duration(seconds: secs - 30));
    return _token!;
  }

  /// Crea orden CAPTURE en USD. Guest checkout vía landing_page.
  Future<PaypalOrderResult> createOrder({
    required double amountUsd,
    required String reference,
    required String description,
  }) async {
    final token = await _accessToken();
    final value = amountUsd.toStringAsFixed(2);
    final body = {
      'intent': 'CAPTURE',
      'purchase_units': [
        {
          'reference_id': reference,
          'description': description,
          'custom_id': reference,
          'amount': {
            'currency_code': 'USD',
            'value': value,
          },
        }
      ],
      'payment_source': {
        'paypal': {
          'experience_context': {
            'brand_name': 'FiscoGest',
            'locale': 'es-DO',
            'landing_page': 'GUEST_CHECKOUT',
            'payment_method_preference': 'UNRESTRICTED',
            'shipping_preference': 'NO_SHIPPING',
            'user_action': 'PAY_NOW',
            'return_url': PaypalConfig.returnUrl,
            'cancel_url': PaypalConfig.cancelUrl,
          },
        },
      },
    };

    final res = await http.post(
      Uri.parse('${PaypalConfig.baseUrl}/v2/checkout/orders'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      },
      body: jsonEncode(body),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('PayPal create order ${res.statusCode}: ${res.body}');
    }
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final id = map['id'] as String;
    String? approve;
    final links = map['links'] as List<dynamic>? ?? [];
    for (final l in links) {
      final m = l as Map<String, dynamic>;
      if (m['rel'] == 'payer-action' || m['rel'] == 'approve') {
        approve = m['href'] as String?;
        break;
      }
    }
    if (approve == null || approve.isEmpty) {
      throw Exception('PayPal: no approve URL en respuesta');
    }
    return PaypalOrderResult(orderId: id, approveUrl: approve);
  }

  Future<Map<String, dynamic>> captureOrder(String orderId) async {
    final token = await _accessToken();
    final res = await http.post(
      Uri.parse(
        '${PaypalConfig.baseUrl}/v2/checkout/orders/$orderId/capture',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      },
      body: '{}',
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('PayPal capture ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
