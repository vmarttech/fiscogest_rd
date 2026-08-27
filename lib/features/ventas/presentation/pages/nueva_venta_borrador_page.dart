import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_entity.dart';
import 'package:fiscogest_rd/features/clientes/presentation/widgets/seleccionar_cliente_dialog.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/panel_productos.dart';

class NuevaVentaBorradorPage extends ConsumerStatefulWidget {
  const NuevaVentaBorradorPage({super.key});
  static const String routeName = 'nueva-venta-borrador';

  @override
  ConsumerState<NuevaVentaBorradorPage> createState() => _NuevaCotizacionPageState();
}

class _NuevaCotizacionPageState extends ConsumerState<NuevaVentaBorradorPage> {
  final TextEditingController _buscadorController = TextEditingController();
  DateTime? _fechaVencimientoSeleccionada;
  String? _numeroCotizacionGuardada;
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
            content: Text('Seleccione cliente y complete los datos'),
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
      setState(() => _numeroCotizacionGuardada = numero);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cotización guardada — N° $numero'),
          backgroundColor: AppColors.success,
        ),
      );
      notificador.vaciar();
      setState(() => _fechaVencimientoSeleccionada = null);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  Future<void> _imprimir() async {
    if (_numeroCotizacionGuardada == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guarde la cotización antes de imprimir')),
        );
      }
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imprimiendo cotización N° $_numeroCotizacionGuardada...')),
      );
    }
  }

  Future<void> _exportarPDF() async {
    if (_numeroCotizacionGuardada == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guarde la cotización antes de exportar')),
        );
      }
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generando PDF de cotización N° $_numeroCotizacionGuardada...')),
      );
    }
  }

  Future<void> _enviarPorCorreo() async {
    if (_numeroCotizacionGuardada == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guarde la cotización antes de enviar')),
        );
      }
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enviando cotización N° $_numeroCotizacionGuardada por correo...')),
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
            child: Column(children: [
              _buildDatosGenerales(estado),
              const SizedBox(height: AppSpacing.m),
              _buildProductos(),
            ]),
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: AppSpacing.allM,
            child: Column(children: [
              _buildResumen(estado),
              const SizedBox(height: AppSpacing.l),
              _buildBotonera(),
            ]),
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
        AppCard(
          padding: AppSpacing.allM,
          child: Column(
            children: [
              ListTile(
                title: const Text('Cliente', style: AppTypography.bodyMedium),
                subtitle: Text(estado.clienteNombre ?? 'Sin nombre', style: AppTypography.bodySmall),
                trailing: const Icon(Icons.search, size: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                onTap: _seleccionarCliente,
              ),
              const SizedBox(height: AppSpacing.m),
              ListTile(
                title: const Text('Vencimiento', style: AppTypography.bodyMedium),
                subtitle: Text(
                  _fechaVencimientoSeleccionada != null
                      ? '${_fechaVencimientoSeleccionada!.day}/${_fechaVencimientoSeleccionada!.month}/${_fechaVencimientoSeleccionada!.year}'
                      : 'Seleccione fecha',
                  style: AppTypography.bodySmall,
                ),
                trailing: const Icon(Icons.calendar_today, size: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                onTap: _seleccionarVencimiento,
              ),
            ],
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
        AppCard(
          padding: AppSpacing.allM,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal:', style: AppTypography.bodyMedium),
                  Text('RD\$ ${estado.subtotal.toStringAsFixed(2)}', style: AppTypography.bodyMedium),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ITBIS:', style: AppTypography.bodyMedium),
                  Text('RD\$ ${estado.itbis.toStringAsFixed(2)}', style: AppTypography.bodyMedium),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Descuento:', style: AppTypography.bodyMedium),
                  Text('RD\$ ${estado.descuento.toStringAsFixed(2)}', style: AppTypography.bodyMedium),
                ],
              ),
              const Divider(height: AppSpacing.l),
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
      ],
    );
  }

  Widget _buildBotonera() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          text: _guardando ? 'Guardando...' : 'Guardar Cotización',
          onPressed: _guardando ? null : _guardarCotizacion,
          isLoading: _guardando,
          icon: Icons.save,
        ),
        const SizedBox(height: AppSpacing.m),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.print, size: 18),
                label: const Text('Imprimir'),
                onPressed: _imprimir,
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text('PDF'),
                onPressed: _exportarPDF,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.email, size: 18),
                label: const Text('Enviar'),
                onPressed: _enviarPorCorreo,
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }
}
