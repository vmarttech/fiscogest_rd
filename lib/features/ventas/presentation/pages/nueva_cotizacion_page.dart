import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_entity.dart';
import 'package:fiscogest_rd/features/clientes/presentation/widgets/seleccionar_cliente_dialog.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/panel_productos.dart';

class NuevaCotizacionPage extends ConsumerStatefulWidget {
  const NuevaCotizacionPage({super.key});
  static const String routeName = 'nueva-cotizacion';

  @override
  ConsumerState<NuevaCotizacionPage> createState() => _NuevaCotizacionPageState();
}

class _NuevaCotizacionPageState extends ConsumerState<NuevaCotizacionPage> {
  final TextEditingController _buscadorController = TextEditingController();
  DateTime? _fechaVencimientoSeleccionada;

  @override
  void dispose() {
    _buscadorController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarCliente() async {
    final ClienteEntity? cliente = await SeleccionarClienteDialog.mostrar(context);
    if (cliente != null && mounted) {
      ref.read(cotizacionProvider.notifier).seleccionarCliente(
        cliente.id ?? 0,
        cliente.nombre,
      );
    }
  }

  Future<void> _seleccionarVencimiento() async {
    final hoy = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: hoy.add(const Duration(days: 30)),
      firstDate: hoy.add(const Duration(days: 1)),
      lastDate: hoy.add(const Duration(days: 365)),
    );
    if (fecha != null) {
      setState(() => _fechaVencimientoSeleccionada = fecha);
      ref.read(cotizacionProvider.notifier).establecerVencimiento(fecha);
    }
  }

  Future<void> _alAgregar(String textoBusqueda) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Buscando producto: $textoBusqueda')),
    );
  }

  Future<void> _guardarCotizacion() async {
    final validador = ref.read(cotizacionProvider.notifier);
    if (!validador.validarAntesDeGuardar()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Seleccione cliente, fecha de vencimiento futura y al menos un producto'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Cotización guardada'), backgroundColor: AppColors.success),
    );
    ref.invalidate(listaCotizacionesProvider);
    ref.read(cotizacionProvider.notifier).vaciar();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(cotizacionProvider);
    return AppScaffold(
      title: 'Nueva Cotización',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final esPantallaAncha = constraints.maxWidth >= 720;
                return _buildCuerpo(esPantallaAncha, estado);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCuerpo(bool esPantallaAncha, CotizacionState estado) {
    if (esPantallaAncha) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              padding: AppSpacing.allM,
              child: _buildColumnaIzquierda(estado),
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              padding: AppSpacing.allM,
              child: _buildColumnaDerecha(estado),
            ),
          ),
        ],
      );
    }
    return SingleChildScrollView(
      padding: AppSpacing.allM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildColumnaIzquierda(estado),
          const SizedBox(height: AppSpacing.m),
          _buildColumnaDerecha(estado),
        ],
      ),
    );
  }

  Widget _buildColumnaIzquierda(CotizacionState estado) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Datos Generales', style: AppTypography.h4),
        const SizedBox(height: AppSpacing.s),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: AppSpacing.allM,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  title: const Text('Cliente'),
                  subtitle: Text(estado.clienteNombre ?? 'No seleccionado'),
                  trailing: const Icon(Icons.search),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  onTap: _seleccionarCliente,
                ),
                const SizedBox(height: AppSpacing.m),
                ListTile(
                  title: const Text('Vencimiento'),
                  subtitle: Text(_fechaVencimientoSeleccionada != null
                      ? '${_fechaVencimientoSeleccionada!.day}/${_fechaVencimientoSeleccionada!.month}/${_fechaVencimientoSeleccionada!.year}'
                      : 'Seleccione fecha'),
                  trailing: const Icon(Icons.calendar_today),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  onTap: _seleccionarVencimiento,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        const Text('Productos', style: AppTypography.h4),
        const SizedBox(height: AppSpacing.s),
        PanelProductos(
          controlador: _buscadorController,
          alAgregar: _alAgregar,
        ),
      ],
    );
  }

  Widget _buildColumnaDerecha(CotizacionState estado) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Resumen', style: AppTypography.h4),
        const SizedBox(height: AppSpacing.s),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: AppSpacing.allM,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:', style: AppTypography.labelMedium),
                    Text('RD\$ ${estado.subtotal.toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ITBIS:', style: AppTypography.labelMedium),
                    Text('RD\$ ${estado.itbis.toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Descuento:', style: AppTypography.labelMedium),
                    Text('RD\$ ${estado.descuento.toStringAsFixed(2)}'),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total:', style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      'RD\$ ${estado.montoTotal.toStringAsFixed(2)}',
                      style: AppTypography.h4.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('Guardar Cotización'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
          ),
          onPressed: _guardarCotizacion,
        ),
      ],
    );
  }
}
