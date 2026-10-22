import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';

/// Pantalla de cámara para leer código de barras / QR.
/// Devuelve el texto leído con [Navigator.pop(context, codigo)].
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
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  bool _yaLeido = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_yaLeido || !mounted) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;
    _yaLeido = true;
    Navigator.of(context).pop(raw);
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
          IconButton(
            tooltip: 'Linterna',
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            tooltip: 'Cambiar cámara',
            icon: const Icon(Icons.cameraswitch_outlined),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            )
          else
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error, child) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No se pudo abrir la cámara.\n'
                      'Revise el permiso de cámara en Ajustes.\n\n$error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          // Marco guía
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
    // Oscurecer fuera del marco
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
