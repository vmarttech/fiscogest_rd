import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';

/// Solo lectura en Android e iOS. En escritorio se emite.
bool get ecfeSoloLectura {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

const String avisoEcfePc =
    'Esta área es solo de consulta. Para generar, firmar, enviar o anular '
    'comprobantes electrónicos descarga FiscoGest versión PC.';

void avisoEcfeVersionPc(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('e-CF · versión PC'),
      content: const Text(avisoEcfePc),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}

class EcfeSoloLecturaBanner extends StatelessWidget {
  const EcfeSoloLecturaBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!ecfeSoloLectura) return const SizedBox.shrink();
    // Solo visible en móvil/tablet estrecha — en PC la app ya es versión escritorio.
    if (!AppBreakpoints.isMobile(context)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Material(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Color(0xFF8A5A00)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  avisoEcfePc,
                  style: TextStyle(color: Color(0xFF5C3B00), height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
