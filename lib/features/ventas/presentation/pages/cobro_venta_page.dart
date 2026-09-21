import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/caja_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/listas_ventas_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart' as venta_providers;

class CobroVentaPage extends ConsumerStatefulWidget {
  const CobroVentaPage({super.key});
  static const String routeName = 'cobro-venta';
  @override
  ConsumerState<CobroVentaPage> createState() => _CobroVentaPageState();
}

class _CobroVentaPageState extends ConsumerState<CobroVentaPage> {
  final TextEditingController _abonoController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();
  late final int ventaId;
  late final double montoTotal;
  late final bool esCredito;
  late final String numeroCotizacion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      ventaId = args?['ventaId'] as int? ?? 0;
      montoTotal = (args?['montoTotal'] as double?) ?? 0.0;
      esCredito = args?['esCredito'] as bool? ?? false;
      numeroCotizacion = args?['numeroCotizacion'] as String? ?? 'N/A';
      ref.read(cajaProvider.notifier).inicializarVenta(montoTotal, esCredito);
      if (esCredito) {
        final abonoMinimo = montoTotal * 0.30;
        _abonoController.text = abonoMinimo.toStringAsFixed(2);
        ref.read(cajaProvider.notifier).establecerAbono(abonoMinimo);
      } else {
        _abonoController.text = montoTotal.toStringAsFixed(2);
        ref.read(cajaProvider.notifier).establecerAbono(montoTotal);
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
          ventaId,
          estado.abono,
          estado.referencia,
        );
      } else {
        await repositorio.confirmarVentaBorrador(ventaId);
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
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final esCreditoPantalla = args?['esCredito'] as bool? ?? false;
    final numeroCotizacionPantalla = args?['numeroCotizacion'] as String? ?? 'N/A';
    final montoTotalPantalla = (args?['montoTotal'] as double?) ?? 0.0;
    final titulo = esCreditoPantalla ? 'Venta a Crédito' : 'Cobro de Venta';

    return AppScaffold(
      title: titulo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _FilaResumen('N° Cotización', numeroCotizacionPantalla),
                      const Divider(height: 24),
                      _FilaResumen('Monto Total', 'RD\$ ${montoTotalPantalla.toStringAsFixed(2)}'),
                      const Divider(height: 24),
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
