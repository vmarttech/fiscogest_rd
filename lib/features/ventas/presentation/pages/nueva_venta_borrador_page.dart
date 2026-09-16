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
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/cobro_venta_page.dart';
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
  int? _ventaIdGenerado;
  bool _esCredito = false;
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

  Future<void> _irACobrar() async {
    if (_ventaIdGenerado == null || !mounted || _numeroCotizacionGuardada == null) return;
    final estado = ref.read(ventaBorradorProvider);
    await Navigator.pushNamed(
      context,
      CobroVentaPage.routeName,
      arguments: {
        'ventaId': _ventaIdGenerado!,
        'montoTotal': estado.montoTotal,
        'esCredito': _esCredito,
        'numeroCotizacion': _numeroCotizacionGuardada!,
      },
    );
  }

  Future<void> _guardarCotizacion() async {
    final notificador = ref.read(ventaBorradorProvider.notifier);
    final repositorio = ref.read(ventasRepositoryProvider);
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
      final numeroCotizacion = await repositorio.siguienteNumeroCotizacion(esCredito: _esCredito);
      notificador.establecerNumeroCotizacion(numeroCotizacion);
      notificador.establecerEstadoDocumento(EstadoDocumento.cotizado);
      final numeroGuardado = notificador.guardar();
      if (!mounted) return;
      setState(() {
        _numeroCotizacionGuardada = numeroGuardado;
        _ventaIdGenerado = int.tryParse(numeroGuardado?.replaceAll(RegExp(r'[^0-9]'), '') ?? '0');
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Cotización N° $numeroGuardado generada.\nPuede proceder a cobrar.',
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
        ),
      );
      notificador.vaciar();
      setState(() {
        _fechaVencimientoSeleccionada = null;
        _esCredito = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar cotización: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
    return;
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
        _buildTipoVenta(),
        const SizedBox(height: AppSpacing.m),
        _buildCliente(estado),
        const SizedBox(height: AppSpacing.m),
        _buildProductos(),
        const SizedBox(height: AppSpacing.m),
        _buildResumen(estado),
        const SizedBox(height: AppSpacing.l),
        _buildBotonera(estado),
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
                _buildTipoVenta(),
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
                _buildBotonera(estado),
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
        const Text('NUEVA COTIZACIÓN', style: AppTypography.h4),
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

  Widget _buildTipoVenta() {
    return AppCard(
      padding: AppSpacing.allM,
      child: SwitchListTile(
        title: const Text('Venta a Crédito', style: AppTypography.bodyMedium),
        subtitle: Text(
          _esCredito ? 'Genera cotización con prefijo CR' : 'Genera cotización con prefijo C',
          style: AppTypography.bodySmall,
        ),
        value: _esCredito,
        onChanged: (valor) => setState(() => _esCredito = valor),
        secondary: Icon(
          _esCredito ? Icons.schedule : Icons.payments_outlined,
          color: AppColors.primary,
        ),
      ),
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
          alAgregar: null,
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

  Widget _buildBotonera(VentaBorradorState estado) {
    final mostrarBotonCobro = _ventaIdGenerado != null &&
        estado.estadoDocumento == EstadoDocumento.cotizado;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mostrarBotonCobro) ...[
          AppButton(
            text: 'IR A COBRAR / FACTURAR',
            onPressed: _irACobrar,
            icon: Icons.payment,
          ),
          const SizedBox(height: AppSpacing.m),
        ],
        AppButton(
          text: _guardando ? 'Generando...' : 'GENERAR COTIZACIÓN',
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
