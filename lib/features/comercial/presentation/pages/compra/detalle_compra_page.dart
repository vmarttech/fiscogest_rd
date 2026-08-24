import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/detalle_compra.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart';
import 'package:fiscogest_rd/features/comercial/presentation/providers/compra/compra_usecase_providers.dart';

class DetalleCompraPage extends ConsumerStatefulWidget {
  const DetalleCompraPage({super.key, required this.compraId});

  static const String routeName = 'detalle-compra';
  final String compraId;

  @override
  ConsumerState<DetalleCompraPage> createState() => _DetalleCompraPageState();
}

class _DetalleCompraPageState extends ConsumerState<DetalleCompraPage> {
  Compra? _compra;
  List<DetalleCompra> _detalles = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final repo = ref.read(compraRepositoryProvider);
      _compra = await repo.obtenerCompraPorId(widget.compraId);
      _detalles = await repo.listarDetallesDeCompra(widget.compraId);
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _confirmar() async {
    final confirmar = ref.read(confirmarCompraUseCaseProvider);
    try {
      setState(() => _cargando = true);
      await confirmar(widget.compraId);
      await _cargarDatos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compra confirmada con éxito')),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $_error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget cuerpo;
    if (_cargando) {
      cuerpo = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      cuerpo = Center(
        child: Padding(
          padding: AppSpacing.allM,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error'),
              const SizedBox(height: AppSpacing.m),
              AppButton(text: 'Reintentar', onPressed: _cargarDatos),
            ],
          ),
        ),
      );
    } else if (_compra == null) {
      cuerpo = const Center(child: Text('Compra no encontrada'));
    } else {
      final compra = _compra!;
      cuerpo = SingleChildScrollView(
        padding: AppSpacing.allM,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Compra ${compra.numeroComprobante}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.s),
            _etiquetaEstado(compra.estado),
            const SizedBox(height: AppSpacing.m),
            Text('Proveedor: ${compra.nombreProveedor}'),
            Text('Fecha Emisión: ${compra.fechaEmision.toString().split(' ')[0]}'),
            if (compra.fechaConfirmacion != null)
              Text('Confirmada: ${compra.fechaConfirmacion.toString().split(' ')[0]}'),
            const SizedBox(height: AppSpacing.m),
            const Text('Totales', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.s),
            Text('Subtotal: \$${compra.subtotalSinImpuestos.toStringAsFixed(2)}'),
            Text('Impuesto: \$${compra.montoImpuesto.toStringAsFixed(2)}'),
            Text('Total: \$${compra.totalCompra.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.l),
            const Text('Detalle', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.s),
            if (_detalles.isEmpty)
              const Text('Sin líneas de detalle')
            else
              ..._detalles.map((d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('${d.cantidad} x ${d.nombreProducto} = \$${d.subtotalLinea.toStringAsFixed(2)}'),
              )),
            const SizedBox(height: 40),
            if (compra.esBorrador)
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Confirmar Compra',
                  onPressed: _cargando ? null : _confirmar,
                ),
              ),
          ],
        ),
      );
    }

    return AppScaffold(
      title: 'Detalle de Compra',
      body: cuerpo,
    );
  }

  Widget _etiquetaEstado(EstadoCompra estado) {
    Color color;
    String texto;
    switch (estado) {
      case EstadoCompra.borrador:
        color = Colors.orange;
        texto = 'Borrador';
        break;
      case EstadoCompra.confirmada:
        color = Colors.green;
        texto = 'Confirmada';
        break;
      case EstadoCompra.anulada:
        color = Colors.red;
        texto = 'Anulada';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(texto, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }
}
