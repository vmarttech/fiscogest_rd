import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/services/usb_barcode_scanner_service.dart';

/// Servicio singleton del scanner USB.
final usbBarcodeScannerProvider = Provider<UsbBarcodeScannerService>((ref) {
  final svc = UsbBarcodeScannerService.instance;
  // En desktop se arranca al primer uso; en móvil no hace daño.
  svc.start();
  ref.onDispose(() {
    // No dispose del singleton global; solo dejamos de usarlo.
  });
  return svc;
});

/// Stream de códigos leídos por scanners USB.
final usbBarcodeScanStreamProvider = StreamProvider<String>((ref) {
  final svc = ref.watch(usbBarcodeScannerProvider);
  return svc.onScan;
});
