import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';

/// PLANTILLA GRUPO DE BOTONES — Nunca se desborda
/// Usa Wrap → si no caben en línea, bajan ordenadamente
class PlantillaGrupoBotones extends StatelessWidget {

  const PlantillaGrupoBotones({
    super.key,
    required this.botones,
    this.alineacion = WrapAlignment.center,
  });
  final List<Widget> botones;
  final WrapAlignment alineacion;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: alineacion,
      spacing: AppSpacing.s,
      runSpacing: AppSpacing.s,
      children: botones,
    );
  }
}
