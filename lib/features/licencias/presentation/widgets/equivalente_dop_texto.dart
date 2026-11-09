import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fiscogest_rd/features/licencias/domain/tasa_cambio_service.dart';

/// Texto pequeño bajo el precio USD. Solo informativo; no afecta PayPal.
class EquivalenteDopTexto extends StatefulWidget {
  const EquivalenteDopTexto({
    super.key,
    required this.montoUsd,
    this.compacto = true,
    this.permitirCopiar = false,
    this.color,
  });

  final double montoUsd;
  final bool compacto;
  final bool permitirCopiar;
  final Color? color;

  @override
  State<EquivalenteDopTexto> createState() => _EquivalenteDopTextoState();
}

class _EquivalenteDopTextoState extends State<EquivalenteDopTexto> {
  TasaUsdDop? _tasa;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void didUpdateWidget(covariant EquivalenteDopTexto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.montoUsd != widget.montoUsd) setState(() {});
  }

  Future<void> _cargar() async {
    final t = await TasaCambioService.instance.obtenerUsdDop();
    if (!mounted) return;
    setState(() {
      _tasa = t;
      _cargando = false;
    });
  }

  String _hora(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final mo = d.month.toString().padLeft(2, '0');
    return '$dd/$mo $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color ?? Colors.white70;
    if (_cargando && _tasa == null) {
      return Text(
        'Consultando tasa DOP…',
        style: TextStyle(fontSize: widget.compacto ? 11 : 12, color: c),
      );
    }
    if (_tasa == null) {
      return Text(
        'Equivalente DOP no disponible (sin red ni tasa guardada)',
        style: TextStyle(fontSize: widget.compacto ? 11 : 12, color: c),
      );
    }

    final dopStr = _tasa!.formatoDop(widget.montoUsd);
    final desact = _tasa!.desdeCache;
    final meta = desact
        ? 'tasa guardada ${_hora(_tasa!.actualizadoEn)} · puede estar desactualizada'
        : 'tasa 1 USD = ${_tasa!.tasa.toStringAsFixed(2)} DOP · ${_hora(_tasa!.actualizadoEn)}';

    final texto = widget.compacto
        ? '≈ $dopStr · $meta'
        : 'Monto orientativo a transferir: $dopStr\n$meta';

    final child = Text(
      texto,
      style: TextStyle(
        fontSize: widget.compacto ? 11 : 13,
        height: 1.25,
        color: desact ? Colors.orange.shade200 : c,
        fontWeight: widget.compacto ? FontWeight.w400 : FontWeight.w600,
      ),
    );

    if (!widget.permitirCopiar) return child;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: child),
        IconButton(
          tooltip: 'Copiar monto en RD\$',
          icon: const Icon(Icons.copy, size: 18),
          color: c,
          onPressed: () async {
            // Solo el número para pegar en la app del banco
            final num = _tasa!.aDop(widget.montoUsd).toStringAsFixed(2);
            await Clipboard.setData(ClipboardData(text: num));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Copiado: RD\$ $num')),
              );
            }
          },
        ),
      ],
    );
  }
}
