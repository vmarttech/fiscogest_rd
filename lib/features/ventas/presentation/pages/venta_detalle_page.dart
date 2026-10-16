import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/mostrar_detalle_venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

/// Detalle de venta montado en AppShell → menú lateral + barra superior.
class VentaDetallePage extends ConsumerStatefulWidget {
  const VentaDetallePage({super.key, this.venta, this.ventaId});

  static const String routeName = 'venta-detalle';

  final Venta? venta;
  final int? ventaId;

  @override
  ConsumerState<VentaDetallePage> createState() => _VentaDetallePageState();
}

class _VentaDetallePageState extends ConsumerState<VentaDetallePage> {
  Venta? _venta;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    try {
      Venta? v = widget.venta;
      final id = widget.ventaId ?? v?.id;
      if (id != null) {
        final full =
            await ref.read(ventasRepositoryProvider).obtenerVentaPorId(id);
        if (full != null) v = full;
      }
      if (!mounted) return;
      setState(() {
        _venta = v;
        _loading = false;
        if (v == null) _error = 'Venta no encontrada';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final desktop = AppBreakpoints.isDesktop(context);
    return AppScaffold(
      title: _venta?.numero ?? 'DETALLE DE VENTA',
      showAppBar: !desktop,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/ventas/historial');
          }
        },
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : MostrarDetalleVenta(venta: _venta!),
    );
  }
}
