import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';

/// Pantalla de cámara para leer código de barras / QR.
///
/// Punto único de entrada del producto: [BarcodeScannerPage.abrir].
/// Ciclo de vida endurecido para mobile_scanner 6.x en Android
/// (evita NPE getClass() on null al iniciar demasiado pronto).
class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({
    super.key,
    this.titulo = 'Escanear código',
    this.subtitulo = 'Apunte al código de barras del producto',
  });

  final String titulo;
  final String subtitulo;

  /// Abre el escáner y devuelve el código o null si se cancela.
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

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  MobileScannerController? _controller;
  bool _yaLeido = false;
  bool _listo = false;
  bool _arrancando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Esperar al primer frame antes de solicitar el permiso.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_prepararCamara());
    });
  }

  Future<void> _prepararCamara() async {
    if (_arrancando) return;
    _arrancando = true;
    try {
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
      }
      if (!status.isGranted) {
        if (!mounted) return;
        setState(() {
          _error = status.isPermanentlyDenied
              ? 'Permiso de cámara denegado permanentemente.\n'
                  'Ábrelo en Ajustes del teléfono.'
              : 'Se necesita permiso de cámara para escanear.\n'
                  'Actívalo en Ajustes.';
          _listo = false;
        });
        return;
      }

      await _recrearControllerYArrancar();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo inicializar la cámara.\n$e';
        _listo = false;
      });
    } finally {
      _arrancando = false;
    }
  }

  Future<void> _recrearControllerYArrancar() async {
    final prev = _controller;
    _controller = null;

    if (prev != null) {
      try {
        await prev.dispose();
      } catch (_) {}
    }

    if (!mounted) return;

    final controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
      // MobileScanner gestiona el inicio y el ciclo de vida.
      autoStart: true,
    );

    setState(() {
      _controller = controller;
      _listo = true;
      _error = null;
    });
  }

  @override
  void dispose() {
    final c = _controller;
    _controller = null;
    if (c != null) {
      unawaited(c.dispose());
    }
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_yaLeido || !mounted) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;
    _yaLeido = true;
    final c = _controller;
    unawaited(c?.stop().catchError((_) {}) ?? Future.value());
    Navigator.of(context).pop(raw);
  }

  Future<void> _abrirAjustes() async {
    await openAppSettings();
  }

  Future<void> _reintentar() async {
    setState(() {
      _error = null;
      _listo = false;
      _yaLeido = false;
    });
    await _prepararCamara();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
                _controller?.toggleTorch().catchError((_) {}) ?? Future.value(),
              ),
            ),
            IconButton(
              tooltip: 'Cambiar cámara',
              icon: const Icon(Icons.cameraswitch_outlined),
              onPressed: () => unawaited(
                _controller?.switchCamera().catchError((_) {}) ?? Future.value(),
              ),
            ),
          ],
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _abrirAjustes,
                      icon: const Icon(Icons.settings),
                      label: const Text('Abrir Ajustes'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF21877C),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _reintentar,
                      child: const Text(
                        'Reintentar',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (!_listo || _controller == null)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            MobileScanner(
              controller: _controller!,
              onDetect: _onDetect,
              errorBuilder: (context, error, child) {
                // No setState durante build: programar en el siguiente frame.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || _yaLeido) return;
                  setState(() {
                    _error =
                        'No se pudo abrir la cámara.\n'
                        'Revise el permiso o cierre otras apps que usen la cámara.\n\n'
                        '$error';
                    _listo = false;
                  });
                });
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white54),
                );
              },
            ),
          if (_listo && _error == null)
            IgnorePointer(
              child: CustomPaint(
                painter: _ScanFramePainter(),
                child: const SizedBox.expand(),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 48,
            child: Column(
              children: [
                Text(
                  widget.subtitulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final h = size.height * 0.28;
    final left = (size.width - w) / 2;
    final top = (size.height - h) / 2;
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
