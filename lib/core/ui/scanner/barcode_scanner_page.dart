import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';

/// Pantalla de cámara para leer código de barras / QR.
/// Devuelve el texto leído con [Navigator.pop(context, codigo)].
///
/// Ajuste global: solicita permiso, gestiona ciclo de vida y evita el NPE
/// típico de mobile_scanner 6.x en Android.
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

class _BarcodeScannerPageState extends State<BarcodeScannerPage>
    with WidgetsBindingObserver {
  MobileScannerController? _controller;
  bool _yaLeido = false;
  bool _listo = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _prepararCamara();
  }

  Future<void> _prepararCamara() async {
    try {
      // 1. Pedir permiso de cámara de forma explícita
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
        });
        return;
      }

      // 2. Crear el controller solo cuando ya hay permiso
      final controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
        autoStart: true,
      );

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _listo = true;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo inicializar la cámara.\n$e';
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null || !_listo) return;

    // Evita crashes al ir a segundo plano / volver
    switch (state) {
      case AppLifecycleState.resumed:
        c.start().catchError((_) {});
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        c.stop().catchError((_) {});
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final c = _controller;
    _controller = null;
    c?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_yaLeido || !mounted) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;
    _yaLeido = true;
    // Parar la cámara antes de salir evita fugas / crashes
    _controller?.stop().catchError((_) {});
    Navigator.of(context).pop(raw);
  }

  Future<void> _abrirAjustes() async {
    await openAppSettings();
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
          if (_controller != null) ...[
            IconButton(
              tooltip: 'Linterna',
              icon: const Icon(Icons.flash_on),
              onPressed: () => _controller?.toggleTorch(),
            ),
            IconButton(
              tooltip: 'Cambiar cámara',
              icon: const Icon(Icons.cameraswitch_outlined),
              onPressed: () => _controller?.switchCamera(),
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
                      onPressed: () {
                        setState(() {
                          _error = null;
                          _listo = false;
                        });
                        _prepararCamara();
                      },
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
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  setState(() {
                    _error =
                        'No se pudo abrir la cámara.\n'
                        'Revise el permiso de cámara en Ajustes.\n\n'
                        '$error';
                  });
                });
                return const SizedBox.shrink();
              },
            ),

          // Marco guía (solo si la cámara está activa)
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
