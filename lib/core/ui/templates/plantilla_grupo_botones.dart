import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';

///== PLANTILLA GRUPO DE BOTONES — NUNCA SE DESBORDA ==
/// Cumplimiento automático:
/// ✅ Wrap → si no caben en una línea, bajan ordenadamente
/// ✅ AppSpacing → espaciado uniforme horizontal y vertical
/// ✅ Alineación configurable → center / start / end

class PlantillaGrupoBotones extends StatelessWidget {
  const PlantillaGrupoBotones({
    super.key,
    required this.botones,
    this.alineacion = WrapAlignment.center,
  });

  /// Constructor rápido para botones de texto simples
  factory PlantillaGrupoBotones.textos({
    Key? key,
    required List<String> textos,
    required List<VoidCallback> onPressed,
    List<IconData>? iconos,
    WrapAlignment alineacion = WrapAlignment.center,
  }) {
    assert(
      textos.length == onPressed.length,
      'Textos y callbacks deben coincidir',
    );
    return PlantillaGrupoBotones(
      key: key,
      alineacion: alineacion,
      botones: List.generate(textos.length, (i) {
        return AppButton(
          text: textos[i],
          icon: iconos?[i],
          onPressed: onPressed[i],
        );
      }),
    );
  }
  final List<Widget> botones;
  final WrapAlignment alineacion;

  @override
  Widget build(BuildContext context) {
    // === PASO 4: Wrap → anti-desborde garantizado ===
    return Wrap(
      alignment: alineacion,
      spacing: AppSpacing.s, // Espacio HORIZONTAL entre botones
      runSpacing: AppSpacing.s, // Espacio VERTICAL si bajan de línea
      children: botones,
    );
  }
}
