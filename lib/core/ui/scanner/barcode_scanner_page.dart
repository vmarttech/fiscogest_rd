import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';

/// Pantalla única de escaneo de código de barras / QR (producto comercial).
///
/// Uso en toda la app:
/// ```dart
/// final codigo = await BarcodeScannerPage.abrir(context);
/// ```
///
/// Diseño endurecido para mobile_scanner 6.x en Android:
/// - Permiso antes de crear el controller
/// - autoStart: false → start() solo cuando el widget ya está montado
/// - Lifecycle (pausa/reanuda al salir/volver de la app)
/// - Reintento = dispose total + recrear (no start sobre controller roto)
/// - Entrada manual siempre disponible (POS real no depende solo de cámara)
class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({
    super.key,
    this.titulo = 'Escanear código',
    this.subtitulo = 'Apunte al código de barras del producto',
  });

  final String titulo;
  final String subtitulo;

  /// Abre el escáner y devuelve el código, o null si se cancela.
  static Future<String?> abrir(
    BuildContext context, {
    String titulo = 'Escanear código',
    String subtitulo = 'Apunte al código de barras del producto',
  }) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => BarcodeScannerPage(
          titulo: titulo,
          subtitulo: subtitulo,
        ),
      ),
    );
  }

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage>
    with WidgetsBindingObserver {
  MobileScannerController? _controller;

  /// Evita lecturas duplicadas.
  bool _yaLeido = false;

  /// true cuando el PlatformView puede mostrarse.
  bool _listo = false;

  /// true mientras se pide permiso / se crea controller.
  bool _arrancando = false;

  String? _error;

  final _manualCtrl = TextEditingController();
  final _manualFocus = FocusNode();

  /// Key para forzar reconstrucción limpia del PlatformView al reintentar.
  Key _scannerKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_prepararCamara());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _manualCtrl.dispose();
    _manualFocus.dispose();
    unawaited(_destruirController());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null || _error != null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        if (_listo && !_yaLeido) {
          unawaited(_startSeguro(c));
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        unawaited(c.stop().catchError((_) {}));
        break;
    }
  }

  Future<void> _destruirController() async {
    final c = _controller;
    _controller = null;
    if (c == null) return;
    try {
      await c.stop();
    } catch (_) {}
    try {
      await c.dispose();
    } catch (_) {}
  }

  Future<void> _prepararCamara() async {
    if (_arrancando) return;
    _arrancando = true;

    if (mounted) {
      setState(() {
        _error = null;
        _listo = false;
        _yaLeido = false;
      });
    }

    try {
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
      }

      if (!status.isGranted) {
        if (!mounted) return;
        setState(() {
          _error = status.isPermanentlyDenied
              ? 'Permiso de cámara bloqueado.\n'
                  'Actívalo en Ajustes del teléfono o ingresa el código manualmente.'
              : 'Se necesita permiso de cámara para escanear.\n'
                  'También puedes ingresar el código manualmente abajo.';
          _listo = false;
        });
        return;
      }

      // Liberar sesión nativa previa (evita NPE en reintentos).
      await _destruirController();

      // Pequeña pausa: deja que Android suelte el CameraService.
      await Future<void>.delayed(const Duration(milliseconds: 280));
      if (!mounted) return;

      final controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
        // CRÍTICO: no arrancar hasta que MobileScanner esté en el árbol.
        autoStart: false,
      );

      setState(() {
        _scannerKey = UniqueKey();
        _controller = controller;
        _listo = true;
        _error = null;
          });

      // Start diferido: el widget MobileScanner debe existir primero.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_startSeguro(controller));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error =
            'No se pudo inicializar la cámara.\n'
            'Usa la entrada manual o reintenta.\n\n$e';
        _listo = false;
      });
    } finally {
      _arrancando = false;
    }
  }

  Future<void> _startSeguro(MobileScannerController controller) async {
    if (!mounted || _yaLeido) return;
    if (!identical(_controller, controller)) return;

    // Esperar un frame extra para el PlatformView Android.
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted || !identical(_controller, controller) || _yaLeido) return;

    try {
      await controller.start();
    } catch (e) {
      if (!mounted) return;
      // Controller queda inservible → destruir y mostrar error con fallback.
      await _destruirController();
      if (!mounted) return;
      setState(() {
        _error =
            'No se pudo abrir la cámara.\n'
            'Cierra otras apps que usen la cámara, reintenta, '
            'o ingresa el código manualmente.\n\n$e';
        _listo = false;
      });
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_yaLeido || !mounted) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final raw = barcodes.first.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;

    _yaLeido = true;
    HapticFeedback.lightImpact();

    final c = _controller;
    unawaited(c?.stop().catchError((_) {}) ?? Future.value());

    if (mounted) {
      Navigator.of(context).pop(raw);
    }
  }

  void _confirmarManual() {
    final raw = _manualCtrl.text.trim();
    if (raw.isEmpty) return;
    if (_yaLeido) return;
    _yaLeido = true;
    final c = _controller;
    unawaited(c?.stop().catchError((_) {}) ?? Future.value());
    Navigator.of(context).pop(raw);
  }

  Future<void> _abrirAjustes() async {
    await openAppSettings();
  }

  Future<void> _reintentar() async {
    if (_arrancando) return;
    await _prepararCamara();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.titulo,
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (_controller != null && _error == null) ...[
            IconButton(
              tooltip: 'Linterna',
              icon: const Icon(Icons.flash_on),
              onPressed: () => unawaited(
                _controller?.toggleTorch().catchError((_) {}) ??
                    Future<void>.value(),
              ),
            ),
            IconButton(
              tooltip: 'Cambiar cámara',
              icon: const Icon(Icons.cameraswitch_outlined),
              onPressed: () => unawaited(
                _controller?.switchCamera().catchError((_) {}) ??
                    Future<void>.value(),
              ),
            ),
          ],
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Cámara / error / loading ──
          if (_error != null)
            _ErrorPanel(
              mensaje: _error!,
              onAjustes: _abrirAjustes,
              onReintentar: _reintentar,
            )
          else if (!_listo || _controller == null)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            MobileScanner(
              key: _scannerKey,
              controller: _controller!,
              onDetect: _onDetect,
              errorBuilder: (context, error, child) {
                // No setState síncrono aquí: programar limpieza total.
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (!mounted || _yaLeido) return;
                  await _destruirController();
                  if (!mounted) return;
                  setState(() {
                    _error =
                        'No se pudo abrir la cámara.\n'
                        'Revise el permiso, cierre otras apps que usen '
                        'la cámara, o ingrese el código manualmente.\n\n'
                        '$error';
                    _listo = false;
                  });
                });
                return const ColoredBox(
                  color: Colors.black,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white54),
                  ),
                );
              },
            ),

          // ── Marco de mira ──
          if (_listo && _error == null)
            IgnorePointer(
              child: CustomPaint(
                painter: _ScanFramePainter(),
                child: const SizedBox.expand(),
              ),
            ),

          // ── Pie: subtítulo + manual + cancelar ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              color: Colors.black.withValues(alpha: 0.82),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_error == null)
                      Text(
                        widget.subtitulo,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    const SizedBox(height: 12),
                    // Entrada manual (siempre visible) — requisito comercial POS
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _manualCtrl,
                            focusNode: _manualFocus,
                            style: const TextStyle(color: Colors.white),
                            cursorColor: Colors.white,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _confirmarManual(),
                            decoration: InputDecoration(
                              hintText: 'Ingresar código manualmente',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.08),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF21877C),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _confirmarManual,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF21877C),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white70),
                      label: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({
    required this.mensaje,
    required this.onAjustes,
    required this.onReintentar,
  });

  final String mensaje;
  final VoidCallback onAjustes;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_off_outlined,
              color: Colors.white54,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAjustes,
              icon: const Icon(Icons.settings),
              label: const Text('Abrir Ajustes'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF21877C),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: onReintentar,
              child: const Text(
                'Reintentar cámara',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF22C55E)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final w = size.width * 0.75;
    final h = size.height * 0.22;
    final left = (size.width - w) / 2;
    final top = (size.height - h) / 2 - 40;
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, w, h),
      const Radius.circular(12),
    );

    final overlay = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()..addRRect(r);
    final dim = Path.combine(PathOperation.difference, overlay, hole);
    canvas.drawPath(
      dim,
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );
    canvas.drawRRect(r, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
