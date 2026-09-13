import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/caja_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/listas_ventas_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart' as venta_providers;

class CobroVentaPage extends ConsumerStatefulWidget {
  const CobroVentaPage({super.key, required this.ventaId, required this.montoTotal, required this.esCredito});

  final int ventaId;
  final double montoTotal;
  final bool esCredito;

  static const String routeName = 'cobro-venta';

  @override
  ConsumerState<CobroVentaPage> createState() => _CobroVentaPageState();
}

class _CobroVentaPageState extends ConsumerState<CobroVentaPage> {
  final TextEditingController _abonoController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cajaProvider.notifier).inicializarVenta(widget.montoTotal, widget.esCredito);
      if (widget.esCredito) {
        final abonoMinimo = widget.montoTotal * 0.30;
        _abonoController.text = abonoMinimo.toStringAsFixed(2);
        ref.read(cajaProvider.notifier).establecerAbono(abonoMinimo);
      } else {
        _abonoController.text = widget.montoTotal.toStringAsFixed(2);
        ref.read(cajaProvider.notifier).establecerAbono(widget.montoTotal);
      }
    });
  }

  @override
  void dispose() {
    _abonoController.dispose();
    _referenciaController.dispose();
    super.dispose();
  }

  Future<void> _confirmarVenta() async {
    if (!mounted) return;
    final cajaNotifier = ref.read(cajaProvider.notifier);
    final estado = ref.read(cajaProvider);
    final esCredito = widget.esCredito;

    if (!cajaNotifier.validarCobroCompleto()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(esCredito
                ? 'El abono debe ser mayor a RD\$ 0 y no exceder el total'
                : 'Debe pagar el monto total'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    try {
      final repositorio = ref.read(venta_providers.ventasRepositoryProvider);

      if (esCredito) {
        await repositorio.registrarVentaConAbono(
          widget.ventaId,
          estado.abono,
          estado.referencia,
        );
      } else {
        await repositorio.confirmarVentaBorrador(widget.ventaId);
      }

      ref.invalidate(listaVentasBorradorProvider);
      ref.invalidate(listaCotizacionesProvider);

      if (!mounted) return;
      final saldo = estado.saldoPendiente;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(esCredito
                ? '✅ Venta registrada. Abono: RD\$ ${estado.abono.toStringAsFixed(2)} · Saldo: RD\$ ${saldo.toStringAsFixed(2)}'
                : '✅ Venta confirmada y cobrada'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar venta: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esCredito = widget.esCredito;

    return Scaffold(
      appBar: AppBar(
        title: Text(esCredito ? 'Venta a Crédito' : 'Cobro de Venta'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppCard(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _FilaResumen('Monto Total', ''),
                      Divider(height: 24),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _confirmarVenta,
                  child: const Text('Confirmar Venta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilaResumen extends StatelessWidget {
  const _FilaResumen(this.etiqueta, this.valor);
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: const TextStyle(color: Color(0xFF616161), fontSize: 14)),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF212121),
            ),
          ),
        ],
      ),
    );
  }
}
