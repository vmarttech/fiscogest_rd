import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';

/// Escáner comercial (cámara del celular).
///
/// Motor: package `camera` + `google_mlkit_barcode_scanning`
/// (ya no usa mobile_scanner / su start nativo intermitente).
///
/// API estable para toda la app:
/// ```dart
/// final codigo = await BarcodeScannerPage.abrir(context);
/// ```
class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({
    super.key,
    this.titulo = 'Escanear código',
    this.subtitulo = 'Apunte al código de barras del producto',
  });

  final String titulo;
  final String subtitulo;

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
  CameraController? _camera;
  BarcodeScanner? _barcodeScanner;

  bool _inicializando = true;
  bool _streamActivo = false;
  bool _analizando = false;
  bool _yaLeido = false;
  String? _error;

  final _manualCtrl = TextEditingController();
  final _manualFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_iniciarSesion());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _manualCtrl.dispose();
    _manualFocus.dispose();
    unawaited(_cerrarSesion());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      unawaited(_pausarStream());
    } else if (state == AppLifecycleState.resumed && !_yaLeido) {
      unawaited(_reanudarStream());
    }
  }

  Future<void> _iniciarSesion() async {
    if (!mounted) return;
    setState(() {
      _inicializando = true;
      _error = null;
      _yaLeido = false;
    });

    try {
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
      }
      if (!status.isGranted) {
        if (!mounted) return;
        setState(() {
          _inicializando = false;
          _error = status.isPermanentlyDenied
              ? 'Permiso de cámara bloqueado.\n'
                  'Actívalo en Ajustes o ingresa el código manualmente.'
              : 'Se necesita permiso de cámara.\n'
                  'También puedes ingresar el código abajo.';
        });
        return;
      }

      // Sesión limpia: cerrar cualquier resto antes de abrir.
      await _cerrarSesion();

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _inicializando = false;
          _error =
              'No se detectó cámara en este dispositivo.\n'
              'Usa la entrada manual.';
        });
        return;
      }

      final back = cameras.where(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      final descripcion = back.isNotEmpty ? back.first : cameras.first;

      final controller = CameraController(
        descripcion,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      final scanner = BarcodeScanner(
        formats: const [
          BarcodeFormat.ean13,
          BarcodeFormat.ean8,
          BarcodeFormat.upca,
          BarcodeFormat.upce,
          BarcodeFormat.code128,
          BarcodeFormat.code39,
          BarcodeFormat.code93,
          BarcodeFormat.codabar,
          BarcodeFormat.itf,
          BarcodeFormat.qrCode,
          BarcodeFormat.dataMatrix,
          BarcodeFormat.pdf417,
        ],
      );

      _camera = controller;
      _barcodeScanner = scanner;

      if (!mounted) {
        await _cerrarSesion();
        return;
      }

      setState(() {
        _inicializando = false;
        _error = null;
      });

      await _reanudarStream();
    } catch (e, st) {
      debugPrint('BarcodeScanner init error: $e\n$st');
      await _cerrarSesion();
      if (!mounted) return;
      setState(() {
        _inicializando = false;
        _error =
            'No se pudo abrir la cámara.\n'
            'Prueba de nuevo o ingresa el código manualmente.\n\n$e';
      });
    }
  }

  Future<void> _pausarStream() async {
    final cam = _camera;
    if (cam == null || !_streamActivo) return;
    try {
      if (cam.value.isStreamingImages) {
        await cam.stopImageStream();
      }
    } catch (_) {}
    _streamActivo = false;
  }

  Future<void> _reanudarStream() async {
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized || _yaLeido) return;
    if (_streamActivo || cam.value.isStreamingImages) return;

    try {
      await cam.startImageStream(_onFrame);
      _streamActivo = true;
    } catch (e) {
      debugPrint('startImageStream error: $e');
      if (!mounted) return;
      setState(() {
        _error =
            'No se pudo iniciar el análisis de cámara.\n'
            'Usa la entrada manual o reintenta.\n\n$e';
      });
    }
  }

  Future<void> _cerrarSesion() async {
    _streamActivo = false;
    final cam = _camera;
    _camera = null;
    final scanner = _barcodeScanner;
    _barcodeScanner = null;

    if (cam != null) {
      try {
        if (cam.value.isStreamingImages) {
          await cam.stopImageStream();
        }
      } catch (_) {}
      try {
        await cam.dispose();
      } catch (_) {}
    }
    if (scanner != null) {
      try {
        await scanner.close();
      } catch (_) {}
    }
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_yaLeido || _analizando || !mounted) return;
    final scanner = _barcodeScanner;
    final cam = _camera;
    if (scanner == null || cam == null) return;

    _analizando = true;
    try {
      final input = _toInputImage(image, cam.description);
      if (input == null) return;

      final barcodes = await scanner.processImage(input);
      if (_yaLeido || !mounted || barcodes.isEmpty) return;

      final raw = barcodes.first.rawValue?.trim();
      if (raw == null || raw.isEmpty) return;

      _yaLeido = true;
      HapticFeedback.lightImpact();
      await _pausarStream();
      if (mounted) {
        Navigator.of(context).pop(raw);
      }
    } catch (e) {
      // Frame suelto: no tumbar la sesión por un frame malo.
      debugPrint('Barcode frame error: $e');
    } finally {
      _analizando = false;
    }
  }

  InputImage? _toInputImage(CameraImage image, CameraDescription description) {
    try {
      final rotation =
          InputImageRotationValue.fromRawValue(description.sensorOrientation) ??
              InputImageRotation.rotation0deg;

      if (Platform.isAndroid) {
        final bytes = _yuv420ToNv21(image);
        if (bytes == null) return null;
        return InputImage.fromBytes(
          bytes: bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: InputImageFormat.nv21,
            bytesPerRow: image.width,
          ),
        );
      }

      // iOS: bgra8888, un plano.
      final plane = image.planes.first;
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('toInputImage error: $e');
      return null;
    }
  }

  /// NV21 a partir de planos YUV (Android).
  Uint8List? _yuv420ToNv21(CameraImage image) {
    try {
      if (image.planes.isEmpty) return null;

      // Si el plugin ya entrega NV21 en un solo plano.
      if (image.format.group == ImageFormatGroup.nv21 &&
          image.planes.length == 1) {
        return image.planes.first.bytes;
      }

      final width = image.width;
      final height = image.height;
      final yPlane = image.planes[0];
      final ySize = width * height;
      final uvSize = ySize ~/ 2;
      final nv21 = Uint8List(ySize + uvSize);

      // Copiar Y (teniendo en cuenta row stride).
      var out = 0;
      for (var row = 0; row < height; row++) {
        final start = row * yPlane.bytesPerRow;
        nv21.setRange(out, out + width, yPlane.bytes, start);
        out += width;
      }

      if (image.planes.length >= 3) {
        // YUV_420_888 → NV21 (VU intercalado).
        final uPlane = image.planes[1];
        final vPlane = image.planes[2];
        final uvRowStride = uPlane.bytesPerRow;
        final uvPixelStride = uPlane.bytesPerPixel ?? 1;
        var uvOut = ySize;
        for (var row = 0; row < height ~/ 2; row++) {
          for (var col = 0; col < width ~/ 2; col++) {
            final idx = row * uvRowStride + col * uvPixelStride;
            final v = vPlane.bytes[idx];
            final u = uPlane.bytes[idx];
            if (uvOut + 1 >= nv21.length) break;
            nv21[uvOut++] = v;
            nv21[uvOut++] = u;
          }
        }
      } else if (image.planes.length == 2) {
        final uv = image.planes[1].bytes;
        final copy = uv.length < uvSize ? uv.length : uvSize;
        nv21.setRange(ySize, ySize + copy, uv);
      } else {
        return image.planes.first.bytes;
      }

      return nv21;
    } catch (e) {
      debugPrint('yuv420ToNv21 error: $e');
      return null;
    }
  }

  void _confirmarManual() {
    final raw = _manualCtrl.text.trim();
    if (raw.isEmpty || _yaLeido) return;
    _yaLeido = true;
    unawaited(_pausarStream());
    Navigator.of(context).pop(raw);
  }

  Future<void> _reintentar() async {
    await _cerrarSesion();
    await _iniciarSesion();
  }

  Future<void> _abrirAjustes() async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final cam = _camera;
    final previewListo =
        cam != null && cam.value.isInitialized && _error == null;

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
          if (previewListo)
            IconButton(
              tooltip: 'Linterna',
              icon: Icon(
                cam.value.flashMode == FlashMode.torch
                    ? Icons.flash_on
                    : Icons.flash_off,
              ),
              onPressed: () async {
                try {
                  final next = cam.value.flashMode == FlashMode.torch
                      ? FlashMode.off
                      : FlashMode.torch;
                  await cam.setFlashMode(next);
                  if (mounted) setState(() {});
                } catch (_) {}
              },
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_error != null)
            _ErrorPanel(
              mensaje: _error!,
              onAjustes: _abrirAjustes,
              onReintentar: _reintentar,
            )
          else if (_inicializando || !previewListo)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            Center(
              child: AspectRatio(
                aspectRatio: cam.value.aspectRatio,
                child: CameraPreview(cam),
              ),
            ),
          if (previewListo)
            IgnorePointer(
              child: CustomPaint(
                painter: _ScanFramePainter(),
                child: const SizedBox.expand(),
              ),
            ),
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
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 140),
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
