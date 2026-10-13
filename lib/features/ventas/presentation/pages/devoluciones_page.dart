import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/features/facturacion/presentation/providers/facturacion_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/listas_ventas_providers.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';

class DevolucionesPage extends ConsumerStatefulWidget {
  const DevolucionesPage({super.key});
  static const String routeName = 'devoluciones';

  @override
  ConsumerState<DevolucionesPage> createState() => _DevolucionesPageState();
}

class _DevolucionesPageState extends ConsumerState<DevolucionesPage> {
  final _ncf = TextEditingController();
  final _motivo = TextEditingController();
  final _cants = <TextEditingController>[];
  Venta? _venta;
  var _busy = false;

  @override
  void dispose() {
    _ncf.dispose();
    _motivo.dispose();
    for (final c in _cants) {
      c.dispose();
    }
    super.dispose();
  }

  void _ponerVenta(Venta? venta) {
    for (final c in _cants) {
      c.dispose();
    }
    _cants.clear();
    if (venta != null) {
      for (final d in venta.detalles) {
        _cants.add(TextEditingController(text: d.cantidad.toString()));
      }
    }
    setState(() => _venta = venta);
  }

  Future<void> _buscar() async {
    final q = _ncf.text.trim().toUpperCase();
    if (q.isEmpty) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(ventasRepositoryProvider);
      Venta? encontrada;
      encontrada = await repo.buscarPorNumeroCotizacion(q);
      if (encontrada != null &&
          encontrada.detalles.isEmpty &&
          encontrada.id != null) {
        encontrada = await repo.obtenerVentaPorId(encontrada.id!) ?? encontrada;
      }
      if (!mounted) return;
      _ponerVenta(encontrada);
      if (encontrada == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay una factura con ese numero')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _emitir() async {
    final venta = _venta;
    if (venta == null || venta.id == null) return;
    final motivo = _motivo.text.trim();
    if (motivo.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Indique el motivo')));
      return;
    }
    final cantidades = <int, double>{};
    for (var i = 0; i < _cants.length; i++) {
      final q =
          double.tryParse(_cants[i].text.trim().replaceAll(',', '.')) ?? 0;
      if (q > 0) cantidades[i] = q;
    }
    if (cantidades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indique la cantidad a devolver')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final r = await ref
          .read(emitirNcServiceProvider)
          .emitir(
            facturaVentaId: venta.id!,
            motivo: motivo,
            cantidades: cantidades,
          );
      if (!mounted) return;
      final aviso = (r.avisoEcfe ?? '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(aviso.isEmpty ? 'Nota ${r.ncfNc}' : aviso)),
      );
      _ponerVenta(null);
      _motivo.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final venta = _venta;
    return AppScaffold(
      backgroundColor: AppColors.pageBackground,
      title: 'Devoluciones',
      body: SafeArea(
        bottom: true,
        child: Padding(
          padding: AppLayout.pantallaPadding,
          child: ListView(
            children: [
              const Text(
                'La devolucion emite una nota de credito y no borra la factura. Puede devolver una parte de las cantidades. En una venta a credito, la devolucion tiene que ser completa.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ncf,
                decoration: const InputDecoration(
                  labelText: 'Numero de cotizacion',
                ),
                onSubmitted: (_) => _buscar(),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _busy ? null : _buscar,
                child: const Text('Buscar factura'),
              ),
              if (venta != null) ...[
                const SizedBox(height: 16),
                Text(
                  (venta.numeroFactura ?? '').isNotEmpty
                      ? (venta.numeroFactura ?? '')
                      : venta.numeroCotizacion,
                ),
                Text(venta.nombreCliente ?? 'Consumidor final'),
                const SizedBox(height: 8),
                for (var i = 0; i < venta.detalles.length; i++) ...[
                  Text(venta.detalles[i].nombreProducto ?? 'Producto'),
                  Text('Vendido: ${venta.detalles[i].cantidad}'),
                  TextField(
                    controller: _cants[i],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Cantidad a devolver',
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: _motivo,
                  decoration: const InputDecoration(labelText: 'Motivo'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _busy ? null : _emitir,
                  child: const Text('Emitir nota de credito'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
