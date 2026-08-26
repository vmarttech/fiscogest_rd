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

class NuevaVentaBorradorPage extends ConsumerStatefulWidget {
  const NuevaVentaBorradorPage({super.key});
  static const String routeName = 'nueva-cotizacion';

  @override
  ConsumerState<NuevaVentaBorradorPage> createState() => _NuevaCotizacionPageState();
}

class _NuevaCotizacionPageState extends ConsumerState<NuevaVentaBorradorPage> {
  final TextEditingController _buscadorController = TextEditingController();
  DateTime? _fechaVencimientoSeleccionada;
  bool _guardando = false;

  @override
  void dispose() {
    _buscadorController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarCliente() async {
    final ClienteEntity? cliente = await SeleccionarClienteDialog.mostrar(context);
    if (cliente != null && mounted) {
      ref.read(ventaBorradorProvider.notifier).seleccionarCliente(
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
      ref.read(ventaBorradorProvider.notifier).establecerVencimiento(fecha);
    }
  }

  Future<void> _guardarCotizacion() async {
    final notificador = ref.read(ventaBorradorProvider.notifier);
    if (!notificador.validarAntesDeGuardar()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Seleccione cliente y complete los datos'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }
    setState(() => _guardando = true);
    try {
      final numero = await notificador.guardar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Cotización guardada — N° $numero'),
          backgroundColor: AppColors.success,
        ),
      );
      notificador.vaciar();
      setState(() => _fechaVencimientoSeleccionada = null);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
    return;
  }

  void _imprimir() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ℹ️ Guarde la cotización antes de imprimir')),
      );
    }
  }

  void _exportarPDF() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ℹ️ Guarde la cotización antes de exportar')),
      );
    }
  }

  void _enviarPorCorreo() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ℹ️ Guarde la cotización antes de enviar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(ventaBorradorProvider);
    return AppScaffold(
      title: 'Nueva Cotización',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final ancha = constraints.maxWidth >= 720;
                return ancha ? _buildDosColumnas(estado) : _buildUnaColumna(estado);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnaColumna(VentaBorradorState estado) {
    return SingleChildScrollView(
      padding: AppSpacing.allM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDatosGenerales(estado),
          const SizedBox(height: AppSpacing.m),
          _buildProductos(),
          const SizedBox(height: AppSpacing.m),
          _buildResumen(estado),
          const SizedBox(height: AppSpacing.l),
          _buildBotonera(),
        ],
      ),
    );
  }

  Widget _buildDosColumnas(VentaBorradorState estado) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: AppSpacing.allM,
            child: Column(children: [_buildDatosGenerales(estado), const SizedBox(height: AppSpacing.m), _buildProductos()]),
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: AppSpacing.allM,
            child: Column(children: [_buildResumen(estado), const SizedBox(height: AppSpacing.l), _buildBotonera()]),
          ),
        ),
      ],
    );
  }

  Widget _buildDatosGenerales(VentaBorradorState estado) {
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
              children: [
                ListTile(
                  title: const Text('Cliente'),
                  subtitle: Text(estado.clienteNombre ?? 'Sin nombre'),
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
      ],
    );
  }

  Widget _buildProductos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Productos', style: AppTypography.h4),
        const SizedBox(height: AppSpacing.s),
        PanelProductos(controlador: _buscadorController, alAgregar: (_) async {}),
      ],
    );
  }

  Widget _buildResumen(VentaBorradorState estado) {
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
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal:'), Text('RD\$ ${estado.subtotal.toStringAsFixed(2)}')]),
                const SizedBox(height: AppSpacing.xs),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('ITBIS:'), Text('RD\$ ${estado.itbis.toStringAsFixed(2)}')]),
                const SizedBox(height: AppSpacing.xs),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Descuento:'), Text('RD\$ ${estado.descuento.toStringAsFixed(2)}')]),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text('Total:', style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold)), Text('RD\$ ${estado.montoTotal.toStringAsFixed(2)}', style: AppTypography.h4.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold))],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBotonera() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          icon: _guardando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
          label: Text(_guardando ? 'Guardando...' : 'Guardar Cotización'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48), backgroundColor: AppColors.success, foregroundColor: Colors.white),
          onPressed: _guardando ? null : _guardarCotizacion,
        ),
        const SizedBox(height: AppSpacing.m),
        Row(
          children: [
            Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.print, size: 18), label: const Text('Imprimir'), onPressed: _imprimir)),
            const SizedBox(width: AppSpacing.s),
            Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.picture_as_pdf, size: 18), label: const Text('PDF'), onPressed: _exportarPDF)),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        Row(
          children: [
            Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.email, size: 18), label: const Text('Enviar'), onPressed: _enviarPorCorreo)),
            const SizedBox(width: AppSpacing.s),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }
}
