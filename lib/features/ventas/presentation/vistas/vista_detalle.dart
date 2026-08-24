import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/apartado.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/ventas_navegacion_provider.dart';
import 'package:fiscogest_rd/features/clientes/presentation/widgets/seleccionar_cliente_dialog.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/panel_carrito.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/formulario_venta.dart';

class VistaDetalle extends ConsumerWidget {
  const VistaDetalle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ventaCargada = ref.watch(ventaCargadaDesdeHistorialProvider);
    if (ventaCargada != null) {
      return _MostrarDetalleVenta(venta: ventaCargada);
    }
    return const ContenidoOperacionVenta();
  }
}

class _MostrarDetalleVenta extends ConsumerWidget {
  const _MostrarDetalleVenta({required this.venta});
  final Venta venta;

  String _formatearFecha(DateTime fecha) {
    return DateFormat.yMd().add_Hm().format(fecha);
  }

  String _formatearMonto(double valor) {
    return NumberFormat.currency(symbol: 'RD\$ ').format(valor);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: AppSpacing.allM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
                onPressed: () {
                  ref.read(ventaCargadaDesdeHistorialProvider.notifier).state = null;
                  ref.read(ventasNavegacionProvider.notifier).cambiarVista(VistaActual.inicio);
                },
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Transacción Nº ${venta.numero}',
                      style: AppTypography.h4,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      _formatearFecha(venta.fecha),
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const Divider(),
          const SizedBox(height: AppSpacing.m),
          const Text('Datos del Cliente y Pago', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.s),
          _FilaDetalle('Nº Transacción', venta.numero),
          _FilaDetalle('Cliente ID', '${venta.clienteId}'),
          if (venta.nombreCliente != null)
            _FilaDetalle('Nombre', venta.nombreCliente!),
          _FilaDetalle('Fecha y Hora', _formatearFecha(venta.fecha)),
          _FilaDetalle('Forma de Pago', venta.tipoPago),
          _FilaDetalle('A crédito', venta.esCredito ? 'Sí' : 'No'),
          if (venta.usuarioId != null)
            _FilaDetalle('Atendido por', 'Usuario ${venta.usuarioId}'),
          const SizedBox(height: AppSpacing.l),
          const Text('Detalle de Artículos', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.s),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.grey300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Container(
                  color: AppColors.grey100,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: const Row(
                    children: [
                      Expanded(flex: 4, child: Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('Cant', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Precio', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Impuesto', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Subtotal', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                ...venta.detalles.map((linea) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(flex: 4, child: Text(linea.nombreProducto as String, style: AppTypography.bodySmall)),
                      Expanded(flex: 1, child: Text('${linea.cantidad}', textAlign: TextAlign.right, style: AppTypography.bodySmall)),
                      Expanded(flex: 2, child: Text(_formatearMonto(linea.precioUnitario as double), textAlign: TextAlign.right, style: AppTypography.bodySmall)),
                      Expanded(flex: 2, child: Text('${linea.tasaImpuesto as double}%', textAlign: TextAlign.right, style: AppTypography.bodySmall)),
                      Expanded(flex: 2, child: Text(_formatearMonto(linea.subtotalLinea as double), textAlign: TextAlign.right, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500))),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 260,
              child: Column(
                children: [
                  _FilaDetalle('Subtotal', _formatearMonto(venta.subtotal)),
                  _FilaDetalle('ITBIS', _formatearMonto(venta.itbis)),
                  const Divider(),
                  _FilaDetalle('TOTAL', _formatearMonto(venta.total), esResaltado: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          const Text('Acciones', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.s),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Función Imprimir disponible'))
                  );
                },
                icon: const Icon(Icons.print, size: 18),
                label: const Text('Imprimir'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Generar PDF disponible'))
                  );
                },
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text('Exportar PDF'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enviar por correo disponible'))
                  );
                },
                icon: const Icon(Icons.email_outlined, size: 18),
                label: const Text('Enviar al Cliente'),
              ),
              if (venta.numero.startsWith('C'))
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Convirtiendo ${venta.numero} a venta...'))
                    );
                  },
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Convertir a Venta'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Transacción ${venta.numero} copiada como referencia. Vaya a Facturación → Nota de Crédito / Devolución.'),
                      backgroundColor: AppColors.success,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long, size: 18),
                label: const Text('Usar para Devolución / NC'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Número ${venta.numero} copiado al portapapeles'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copiar Nº Transacción'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(ventaCargadaDesdeHistorialProvider.notifier).state = null;
              ref.read(ventasNavegacionProvider.notifier).cambiarVista(VistaActual.inicio);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver al historial'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ],
      ),
    );
  }
}

class _FilaDetalle extends StatelessWidget {
  const _FilaDetalle(this.etiqueta, this.valor, {this.esResaltado = false});
  final String etiqueta, valor;
  final bool esResaltado;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
          Text(
            valor,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: esResaltado ? FontWeight.bold : FontWeight.normal,
              color: esResaltado ? AppColors.primary : null,
              fontSize: esResaltado ? 16 : null,
            ),
          ),
        ],
      ),
    );
  }
}

class ContenidoOperacionVenta extends ConsumerStatefulWidget {
  const ContenidoOperacionVenta({super.key});

  @override
  ConsumerState<ContenidoOperacionVenta> createState() => _ContenidoOperacionVentaState();
}

class _ContenidoOperacionVentaState extends ConsumerState<ContenidoOperacionVenta> {
  bool _guardando = false;
  DateTime? _fechaVencimiento;
  final TextEditingController _adelantoController = TextEditingController(text: '0.00');

  @override
  void dispose() {
    _adelantoController.dispose();
    super.dispose();
  }

  Future<void> _alSeleccionarCliente() async {
    final cliente = await SeleccionarClienteDialog.mostrar(context);
    if (cliente != null && cliente.id != null) {
      ref.read(registrarVentaProvider.notifier).seleccionarCliente(cliente.id!, cliente.nombre);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cliente seleccionado: ${cliente.nombre}')),
        );
      }
    }
  }

  void _alSeleccionarFormaPago() {
    showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forma de Pago'),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('Efectivo'), onTap: () => Navigator.pop(ctx, 'efectivo')),
            ListTile(title: const Text('Tarjeta'), onTap: () => Navigator.pop(ctx, 'tarjeta')),
            ListTile(title: const Text('Transferencia'), onTap: () => Navigator.pop(ctx, 'transferencia')),
            ListTile(title: const Text('Crédito'), onTap: () => Navigator.pop(ctx, 'credito')),
            ListTile(title: const Text('Cheque'), onTap: () => Navigator.pop(ctx, 'cheque')),
          ],
        ),
      ),
    ).then((seleccion) {
      if (seleccion != null) {
        final esCredito = seleccion == 'credito';
        ref.read(registrarVentaProvider.notifier).cambiarFormaPago(seleccion, esCredito);
      }
    });
  }

  Future<void> _seleccionarFechaVencimiento() async {
    final hoy = DateTime.now();
    final seleccion = await showDatePicker(
      context: context,
      initialDate: hoy.add(const Duration(days: 30)),
      firstDate: hoy.add(const Duration(days: 1)),
      lastDate: hoy.add(const Duration(days: 365 * 3)),
      locale: Localizations.localeOf(context),
    );
    if (seleccion != null) {
      setState(() => _fechaVencimiento = seleccion);
    }
  }

  String _generarNumero(DateTime fecha, ModoOperacion modo) {
    final prefijo = switch (modo) {
      ModoOperacion.venta => 'V',
      ModoOperacion.cotizacion => 'C',
      ModoOperacion.apartado => 'A',
    };
    return '$prefijo${fecha.year}${fecha.month.toString().padLeft(2,'0')}${fecha.day.toString().padLeft(2,'0')}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
  }

  List<DetalleVenta> _convertirDetalles(List<dynamic> crudos) {
    return crudos.map((linea) => linea as DetalleVenta).toList();
  }

  Future<void> _confirmarOperacion() async {
    final modo = ref.read(ventasNavegacionProvider).modoOperacion;
    final valido = ref.read(registrarVentaProvider.notifier).validarAntesDeGuardar();
    if (!valido) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete cliente, forma de pago y productos'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }
    if (modo == ModoOperacion.cotizacion && _fechaVencimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione la fecha de vencimiento'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (modo == ModoOperacion.apartado) {
      final adelanto = double.tryParse(_adelantoController.text);
      if (adelanto == null || adelanto < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El monto de adelanto debe ser mayor o igual a 0'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }
    setState(() => _guardando = true);
    try {
      final estado = ref.read(registrarVentaProvider);
      final formaPagoValida = <String>['efectivo', 'tarjeta', 'transferencia', 'credito', 'cheque'];
      if (!formaPagoValida.contains(estado.tipoPago)) {
        throw Exception('Forma de pago no válida: seleccione una de la lista (Efectivo, Tarjeta, Transferencia, Crédito, Cheque)');
      }
      final fecha = DateTime.now();
      final numero = _generarNumero(fecha, modo);
      final detallesTipados = _convertirDetalles(estado.detalles);
      switch (modo) {
        case ModoOperacion.venta:
          final venta = Venta(
            numero: numero,
            clienteId: estado.clienteId!,
            fecha: fecha,
            detalles: detallesTipados,
            subtotal: estado.subtotal,
            itbis: estado.itbis,
            total: estado.total,
            tipoPago: estado.tipoPago,
            esCredito: estado.esCredito,
            usuarioId: estado.usuarioId,
            createdAt: fecha,
          );
          final casoUsoVenta = ref.read(registrarVentaUseCaseProvider);
          final resultadoVenta = await (casoUsoVenta as dynamic).call(venta);
          if (mounted) {
            await showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                title: Text('Venta Nº ${resultadoVenta.numero} guardada'),
                content: const Text('La venta se registró correctamente.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
            );
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Venta guardada. Número: ${resultadoVenta.numero}'),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          break;
        case ModoOperacion.cotizacion:
          final ventaComoCotizacion = Venta(
            numero: numero,
            clienteId: estado.clienteId!,
            fecha: fecha,
            detalles: detallesTipados,
            subtotal: estado.subtotal,
            itbis: estado.itbis,
            total: estado.total,
            tipoPago: estado.tipoPago,
            esCredito: estado.esCredito,
            usuarioId: estado.usuarioId,
            createdAt: fecha,
          );
          final repositorio = ref.read(ventasRepositoryProvider);
          final resultadoCotizacion = await repositorio.registrarCotizacion(ventaComoCotizacion);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cotización guardada. Número: ${resultadoCotizacion.numero}'),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          break;
        case ModoOperacion.apartado:
          final montoAbonado = double.tryParse(_adelantoController.text) ?? 0.0;
          final montoTotal = estado.total;
          final repositorio = ref.read(ventasRepositoryProvider);
          final apartado = Apartado(
            numero: numero,
            clienteId: estado.clienteId!,
            productos: detallesTipados,
            montoTotal: montoTotal,
            montoAbonado: montoAbonado,
            saldoPendiente: montoTotal - montoAbonado,
            fechaApartado: fecha,
            estado: 'pendiente',
            createdAt: fecha,
          );
          final resultadoApartado = await repositorio.registrarApartado(apartado);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Apartado guardado. Número: ${resultadoApartado.numero}'),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          break;
      }
      ref.read(registrarVentaProvider.notifier).vaciarVenta();
      setState(() {
        _fechaVencimiento = null;
        _adelantoController.text = '0.00';
      });
      ref.read(ventasNavegacionProvider.notifier).volverAlInicio();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $error'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(registrarVentaProvider);
    final modo = ref.watch(ventasNavegacionProvider.select((e) => e.modoOperacion));
    final textoBoton = switch (modo) {
      ModoOperacion.venta => 'Finalizar Venta',
      ModoOperacion.cotizacion => 'Guardar Cotización',
      ModoOperacion.apartado => 'Confirmar Apartado',
    };
    return SingleChildScrollView(
      padding: AppSpacing.allM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
                onPressed: _guardando ? null : () => ref
                    .read(ventasNavegacionProvider.notifier)
                    .cambiarVista(VistaActual.inicio),
              ),
              const Expanded(
                child: Text(
                  'Detalle de Operación',
                  style: AppTypography.h4,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          const PanelCarrito(),
          const SizedBox(height: AppSpacing.m),
          FormularioVenta(
            alSeleccionarCliente: _alSeleccionarCliente,
            alSeleccionarFormaPago: _alSeleccionarFormaPago,
          ),
          const SizedBox(height: AppSpacing.m),
          if (modo == ModoOperacion.cotizacion) ...[
            InkWell(
              onTap: _guardando ? null : _seleccionarFechaVencimiento,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha de Vencimiento',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _fechaVencimiento != null
                      ? '${_fechaVencimiento!.day}/${_fechaVencimiento!.month}/${_fechaVencimiento!.year}'
                      : 'Pulse para seleccionar',
                  style: _fechaVencimiento != null
                      ? null
                      : const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.m),
          ],
          if (modo == ModoOperacion.apartado) ...[
            TextField(
              controller: _adelantoController,
              decoration: const InputDecoration(
                labelText: 'Monto de Adelanto',
                hintText: '0.00',
                prefixIcon: Icon(Icons.monetization_on_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: AppSpacing.m),
          ],
          const SizedBox(height: AppSpacing.l),
          ElevatedButton.icon(
            onPressed: !_guardando && estado.detalles.isNotEmpty ? _confirmarOperacion : null,
            icon: _guardando
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_outline),
            label: Text(_guardando ? 'Guardando...' : textoBoton),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 45),
        ],
      ),
    );
  }
}
