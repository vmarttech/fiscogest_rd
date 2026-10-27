import 'package:flutter/material.dart';
import 'package:fiscogest_rd/features/e_cf/data/gateways/dgii_endpoints.dart';

/// Solo lectura en Android e iOS. En escritorio se emite.
bool get ecfeSoloLectura => false;

class EcfeSoloLecturaBanner extends StatelessWidget {
  const EcfeSoloLecturaBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class EcfePracticaBanner extends StatelessWidget {
  const EcfePracticaBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!DgiiEndpoints.modoPractica) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      color: const Color(0xFFFFF4D6),
      child: const Text(
        'Modo practica. Se revisa en este equipo y no llega a la DGII.',
      ),
    );
  }
}
