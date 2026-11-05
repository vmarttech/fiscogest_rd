import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  late final WebViewController _controller;
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

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(_url));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _titulo,
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
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
                    IconButton(
                      tooltip: 'Recargar',
                      onPressed: () => _controller.reload(),
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
