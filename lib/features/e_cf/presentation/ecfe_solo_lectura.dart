import 'package:flutter/material.dart';

/// Solo lectura en Android e iOS. En escritorio se emite.
bool get ecfeSoloLectura => false;

class EcfeSoloLecturaBanner extends StatelessWidget {
  const EcfeSoloLecturaBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
