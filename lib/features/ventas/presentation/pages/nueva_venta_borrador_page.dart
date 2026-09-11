import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_entity.dart';
import 'package:fiscogest_rd/features/clientes/presentation/widgets/seleccionar_cliente_dialog.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/panel_productos.dart';

class NuevaVentaBorradorPage extends ConsumerStatefulWidget {
  const NuevaVentaBorradorPage({super.key});
  static const String routeName = 'nueva-venta-borrador';

  @override
  ConsumerState<NuevaVentaBorradorPage> createState() =>
      _NuevaVentaBorradorPageState();
}

class _NuevaVentaBorradorPageState
    extends ConsumerState<NuevaVentaBorradorPage> {
  final TextEditingController _buscadorController = TextEditingController();
  DateTime? _fechaVencimientoSeleccionada;
  String? _numeroCotizacionGuardada;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ventaBorradorProvider.notifier).establecerConsumidorFinal();
    });
  }

  @override
  void dispose() {
    _buscadorController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarCliente() async {
    final ClienteEntity? cliente = await SeleccionarClienteDialog.mostrar(
      context,
    );
    if (cliente != null && mounted) {
      ref
          .read(ventaBorradorProvider.notifier)
          .seleccionarCliente(cliente.id ?? 0, cliente.nombre);
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
            content: Text('Agregue productos para cotizar'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }
    setState(() => _guardando = true);
    try {
      final numero = notificador.guardar();
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
          const SnackBar(
            content: Text('Guarde la cotización antes de imprimir'),
          ),
        );
      }
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imprimiendo cotización N° $_numeroCotizacionGuardada...',
          ),
        ),
      );
    }
  }

  Future<void> _exportarPDF() async {
    if (_numeroCotizacionGuardada == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guarde la cotización antes de exportar'),
          ),
        );
      }
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Generando PDF de cotización N° $_numeroCotizacionGuardada...',
          ),
        ),
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
        SnackBar(
          content: Text(
            'Enviando cotización N° $_numeroCotizacionGuardada por correo...',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(ventaBorradorProvider);
    final anchoPantalla = MediaQuery.of(context).size.width;
    final pantallaPequena = anchoPantalla < 720;

    return AppScaffold(
      body: SafeArea(
        bottom: true,
        child: Padding(
          padding: AppLayout.pantallaPadding,
          child: SingleChildScrollView(
            child: pantallaPequena
                ? _buildUnaColumna(estado)
                : _buildDosColumnas(estado),
          ),
        ),
      ),
    );
  }

  Widget _buildUnaColumna(VentaBorradorState estado) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCabecera(),
        const SizedBox(height: AppSpacing.m),
        _buildCliente(estado),
        const SizedBox(height: AppSpacing.m),
        _buildProductos(),
        const SizedBox(height: AppSpacing.m),
        _buildResumen(estado),
        const SizedBox(height: AppSpacing.l),
        _buildBotonera(),
      ],
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
            child: Column(
              children: [
                _buildCabecera(),
                const SizedBox(height: AppSpacing.m),
                _buildCliente(estado),
                const SizedBox(height: AppSpacing.m),
                _buildProductos(),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: AppSpacing.allM,
            child: Column(
              children: [
                _buildResumen(estado),
                const SizedBox(height: AppSpacing.l),
                _buildBotonera(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCabecera() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('NUEVA VENTA', style: AppTypography.h4),
        const SizedBox(height: AppSpacing.s),
        AppCard(
          padding: AppSpacing.allM,
          child: Column(
            children: [
              ListTile(
                title: const Text(
                  'Vencimiento',
                  style: AppTypography.bodyMedium,
                ),
                subtitle: Text(
                  _fechaVencimientoSeleccionada != null
                      ? '${_fechaVencimientoSeleccionada!.day}/${_fechaVencimientoSeleccionada!.month}/${_fechaVencimientoSeleccionada!.year}'
                      : 'Seleccione fecha (opcional)',
                  style: AppTypography.bodySmall,
                ),
                trailing: const Icon(Icons.calendar_today, size: 20),
                onTap: _seleccionarVencimiento,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCliente(VentaBorradorState estado) {
    final nombreCliente = estado.clienteNombre?.isNotEmpty == true
        ? estado.clienteNombre!
        : 'Consumidor Final';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cliente', style: AppTypography.h4),
        const SizedBox(height: AppSpacing.s),
        AppCard(
          padding: AppSpacing.allM,
          // ✅ Reemplazado ListTile → Row. Ningún gestor nativo interfiere
          child: Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombreCliente, style: AppTypography.labelMedium),
                    const Text(
                      'Predeterminado',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AppButton(
                text: 'Cambiar',
                onPressed: _seleccionarCliente,
                height: 36,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Productos', style: AppTypography.h4),
        const SizedBox(height: AppSpacing.s),
        PanelProductos(
          controlador: _buscadorController,
          alAgregar: (_) async {},
        ),
      ],
    );
  }

  Widget _buildResumen(VentaBorradorState estado) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                  Text(
                    'RD\$ ${estado.subtotal.toStringAsFixed(2)}',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ITBIS:', style: AppTypography.bodyMedium),
                  Text(
                    'RD\$ ${estado.itbis.toStringAsFixed(2)}',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Descuento:', style: AppTypography.bodyMedium),
                  Text(
                    'RD\$ ${(estado.descuento ?? 0.0).toStringAsFixed(2)}',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
              const Divider(height: AppSpacing.l),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL:', style: AppTypography.h4Bold),
                  Text(
                    'RD\$ ${estado.montoTotal.toStringAsFixed(2)}',
                    style: AppTypography.h4PrimaryBold,
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
          ],
        ),
      ],
    );
  }
}
