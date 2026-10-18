import 'package:flutter/material.dart';

enum TipoAlertaOperativa { creditoVencido, stockAgotado, cajaCerrada }

class AlertaOperativa {
  const AlertaOperativa({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.cuerpo,
    required this.ruta,
    required this.icon,
    required this.color,
  });

  final String id;
  final TipoAlertaOperativa tipo;
  final String titulo;
  final String cuerpo;
  final String ruta;
  final IconData icon;
  final Color color;
}
