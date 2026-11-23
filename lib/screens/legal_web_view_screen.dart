import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LegalWebViewScreen extends StatefulWidget {
  const LegalWebViewScreen({super.key, required this.title, required this.url});

  final String title;
  final String url;

  @override
  State<LegalWebViewScreen> createState() => _LegalWebViewScreenState();
}

class _LegalWebViewScreenState extends State<LegalWebViewScreen> {
  /// webview_flutter solo tiene implementación en Android / iOS / macOS.
  static bool get isWebViewSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  WebViewController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    if (isWebViewSupported) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted)
                setState(() {
                  _isLoading = true;
                });
            },
            onPageFinished: (_) {
              if (mounted)
                setState(() {
                  _isLoading = false;
                });
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.url));
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
                launchUrl(
                  Uri.parse(widget.url),
                  mode: LaunchMode.externalApplication,
                );
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_controller != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Recargar',
              onPressed: () => _controller?.reload(),
            ),
        ],
      ),
      body: Stack(
        children: [
          _controller != null
              ? WebViewWidget(controller: _controller!)
              : _buildUnsupportedFallback(),
          if (_isLoading && _controller != null)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
