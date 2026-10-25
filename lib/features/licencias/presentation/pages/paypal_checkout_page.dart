
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:fiscogest_rd/features/licencias/domain/paypal_config.dart';
import 'package:fiscogest_rd/features/licencias/data/paypal_service.dart';

/// Resultado del checkout dentro de la app (no abre Chrome externo).
class PaypalCheckoutResult {
  const PaypalCheckoutResult({
    required this.success,
    this.orderId,
    this.capture,
    this.cancelled = false,
    this.error,
  });
  final bool success;
  final String? orderId;
  final Map<String, dynamic>? capture;
  final bool cancelled;
  final String? error;
}

class PaypalCheckoutPage extends StatefulWidget {
  const PaypalCheckoutPage({
    super.key,
    required this.approveUrl,
    required this.orderId,
  });

  final String approveUrl;
  final String orderId;

  @override
  State<PaypalCheckoutPage> createState() => _PaypalCheckoutPageState();
}

class _PaypalCheckoutPageState extends State<PaypalCheckoutPage> {
  late final WebViewController _ctrl;
  bool _busy = false;
  final _paypal = PaypalService();

  @override
  void initState() {
    super.initState();
    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (req) {
            final url = req.url;
            if (url.startsWith(PaypalConfig.returnUrl) ||
                url.contains('/paypal/return')) {
              _onReturn();
              return NavigationDecision.prevent;
            }
            if (url.startsWith(PaypalConfig.cancelUrl) ||
                url.contains('/paypal/cancel')) {
              Navigator.of(context).pop(
                const PaypalCheckoutResult(success: false, cancelled: true),
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.approveUrl));
  }

  Future<void> _onReturn() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final capture = await _paypal.captureOrder(widget.orderId);
      // Solo COMPLETED = dinero capturado. APPROVED NO basta (no hay cobro).
      final status = '${capture['status'] ?? ''}'.toUpperCase();
      final capturesOk = _capturesCompleted(capture);
      if (status == 'COMPLETED' && capturesOk) {
        if (mounted) {
          Navigator.of(context).pop(
            PaypalCheckoutResult(
              success: true,
              orderId: widget.orderId,
              capture: capture,
            ),
          );
        }
      } else {
        if (mounted) {
          Navigator.of(context).pop(
            PaypalCheckoutResult(
              success: false,
              orderId: widget.orderId,
              error:
                  'Pago no confirmado (estado: $status). '
                  'No se activó ninguna licencia. Completa el pago en PayPal.',
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(
          PaypalCheckoutResult(
            success: false,
            orderId: widget.orderId,
            error: e.toString(),
          ),
        );
      }
    }
  }

  bool _capturesCompleted(Map<String, dynamic> capture) {
    try {
      final units = capture['purchase_units'] as List<dynamic>? ?? [];
      for (final u in units) {
        final payments = (u as Map)['payments'] as Map? ?? {};
        final caps = payments['captures'] as List<dynamic>? ?? [];
        for (final c in caps) {
          final st = '${(c as Map)['status'] ?? ''}'.toUpperCase();
          if (st == 'COMPLETED') return true;
        }
      }
    } catch (_) {}
    return '${capture['status'] ?? ''}'.toUpperCase() == 'COMPLETED';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagar con PayPal'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(
            const PaypalCheckoutResult(success: false, cancelled: true),
          ),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _ctrl),
          if (_busy)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
