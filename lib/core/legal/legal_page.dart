import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:fiscogest_rd/core/legal/legal_texts.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';

enum LegalDocumento { privacidad, terminos, eliminarCuenta }

class LegalPage extends StatefulWidget {
  const LegalPage({super.key, required this.documento});

  final LegalDocumento documento;

  static const routePrivacidad = 'legal-privacidad';
  static const routeTerminos = 'legal-terminos';
  static const routeEliminarCuenta = 'legal-eliminar-cuenta';
  static const pathPrivacidad = '/legal/privacidad';
  static const pathTerminos = '/legal/terminos';
  static const pathEliminarCuenta = '/legal/eliminar-cuenta';

  @override
  State<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  /// webview_flutter solo tiene implementación en Android / iOS / macOS.
  /// En Linux WebViewPlatform.instance es null → crash.
  static bool get isWebViewSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  WebViewController? _controller;
  bool _isLoading = true;

  String get _url {
    switch (widget.documento) {
      case LegalDocumento.privacidad:
        return kUrlPrivacidad;
      case LegalDocumento.terminos:
        return kUrlTerminos;
      case LegalDocumento.eliminarCuenta:
        return kUrlEliminarCuenta;
    }
  }

  String get _titulo {
    switch (widget.documento) {
      case LegalDocumento.privacidad:
        return 'Privacidad';
      case LegalDocumento.terminos:
        return 'Términos de uso';
      case LegalDocumento.eliminarCuenta:
        return 'Eliminar cuenta';
    }
  }

  @override
  void initState() {
    super.initState();

    if (isWebViewSupported) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) setState(() { _isLoading = true; });
            },
            onPageFinished: (_) {
              if (mounted) setState(() { _isLoading = false; });
            },
          ),
        )
        ..loadRequest(Uri.parse(_url));
    }
  }

  Widget _buildUnsupportedFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.language, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'WebView no disponible en esta plataforma',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Se abrirá en el navegador del sistema',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                launchUrl(Uri.parse(_url), mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Abrir en el navegador'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _titulo,
      body: Stack(
        children: [
          _controller != null
              ? WebViewWidget(controller: _controller!)
              : _buildUnsupportedFallback(),
          if (_isLoading && _controller != null)
            const Center(child: CircularProgressIndicator()),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Container(
                color: AppColors.surface.withValues(alpha: 0.95),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/login');
                          }
                        },
                        child: const Text('Volver'),
                      ),
                    ),
                    if (_controller != null)
                      IconButton(
                        tooltip: 'Recargar',
                        onPressed: () => _controller?.reload(),
                        icon: const Icon(Icons.refresh),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
