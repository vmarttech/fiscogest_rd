import 'package:flutter/material.dart';

/// Tarjeta consolidada: total fiado por cliente + color al dia / atrasado.
class TarjetaConsolidadaCliente extends StatelessWidget {
  const TarjetaConsolidadaCliente({
    super.key, required this.nombreCliente, required this.totalPendiente,
    required this.cantidadFios, this.fechaCompromisoMasCercana, this.onTap,
  });

  final String nombreCliente;
  final double totalPendiente;
  final int cantidadFios;
  final DateTime? fechaCompromisoMasCercana;
  final VoidCallback? onTap;

  bool get estaAtrasado {
    final f = fechaCompromisoMasCercana;
    if (f == null) return false;
    return f.isBefore(DateTime.now()) && totalPendiente > 0.001;
  }

  @override
  Widget build(BuildContext context) {
    final atrasado = estaAtrasado;
    final color = atrasado ? Colors.red.shade50 : Colors.green.shade50;
    final borde = atrasado ? Colors.red.shade300 : Colors.green.shade300;
    final textoColor = atrasado ? Colors.red.shade800 : Colors.green.shade800;
    return Card(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borde, width: 1.2),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(nombreCliente, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('$cantidadFios fio(s) pendiente(s)'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('RD\$${totalPendiente.toStringAsFixed(2)}',
                style: TextStyle(fontWeight: FontWeight.w800, color: textoColor)),
            Text(atrasado ? 'ATRASADO' : 'AL DIA',
                style: TextStyle(fontSize: 11, color: textoColor, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
