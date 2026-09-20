import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/core/ui/app_sizes.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/detalle_compra.dart';
import 'package:fiscogest_rd/features/comercial/presentation/providers/compra/compra_usecase_providers.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/registrar_compra_page.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/detalle_compra_page.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';

class _FiltrosCompras {
  const _FiltrosCompras({
    this.textoBusqueda = '',
    this.soloCredito,
    this.estado,
    this.tipoComprobante,
    this.montoMin,
    this.montoMax,
    this.fechaDesde,
    this.fechaHasta,
  });

  final String textoBusqueda;
  final bool? soloCredito;
  final EstadoCompra? estado;
  final String? tipoComprobante;
  final double? montoMin;
  final double? montoMax;
  final DateTime? fechaDesde;
  final DateTime? fechaHasta;

  _FiltrosCompras copyWith({
    String? textoBusqueda,
    bool? soloCredito,
    EstadoCompra? estado,
    String? tipoComprobante,
    double? montoMin,
    double? montoMax,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    bool clearEstado = false,
    bool clearTipo = false,
    bool clearCredito = false,
    bool clearFechas = false,
    bool clearMontos = false,
  }) {
    return _FiltrosCompras(
      textoBusqueda: textoBusqueda ?? this.textoBusqueda,
      soloCredito: clearCredito ? null : (soloCredito ?? this.soloCredito),
      estado: clearEstado ? null : (estado ?? this.estado),
      tipoComprobante: clearTipo ? null : (tipoComprobante ?? this.tipoComprobante),
      montoMin: clearMontos ? null : (montoMin ?? this.montoMin),
      montoMax: clearMontos ? null : (montoMax ?? this.montoMax),
      fechaDesde: clearFechas ? null : (fechaDesde ?? this.fechaDesde),
      fechaHasta: clearFechas ? null : (fechaHasta ?? this.fechaHasta),
    );
  }

  bool get tieneFiltrosActivos =>
      textoBusqueda.isNotEmpty ||
      soloCredito != null ||
      estado != null ||
      (tipoComprobante != null && tipoComprobante!.isNotEmpty) ||
      montoMin != null ||
      montoMax != null ||
      fechaDesde != null ||
      fechaHasta != null;
}

final _filtrosComprasProvider = StateProvider.autoDispose<_FiltrosCompras>((ref) {
  return const _FiltrosCompras();
});

class ListaComprasPage extends ConsumerWidget {
  const ListaComprasPage({super.key});

  static const String routeName = 'lista-compras';

  String _limpiarId(dynamic id) => id.toString().replaceAll(RegExp(r'[^0-9]'), '');

  String _formatearFecha(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

  List<Compra> _aplicarFiltros(List<Compra> compras, _FiltrosCompras f) {
    return compras.where((c) {
      if (f.textoBusqueda.isNotEmpty) {
        final q = f.textoBusqueda.toLowerCase();
        final match = c.nombreProveedor.toLowerCase().contains(q) ||
            c.ncf.toLowerCase().contains(q) ||
            c.numeroComprobante.toLowerCase().contains(q) ||
            c.id.toString().contains(q);
        if (!match) return false;
      }
      if (f.soloCredito != null) {
        if (f.soloCredito! && !c.esCredito) return false;
        if (!f.soloCredito! && c.esCredito) return false;
      }
      if (f.estado != null && c.estado != f.estado) return false;
      if (f.tipoComprobante != null &&
          f.tipoComprobante!.isNotEmpty &&
          c.tipoComprobante != f.tipoComprobante) {
        return false;
      }
      if (f.montoMin != null && c.totalCompra < f.montoMin!) return false;
      if (f.montoMax != null && c.totalCompra > f.montoMax!) return false;
      if (f.fechaDesde != null) {
        final d = DateTime(c.fechaEmision.year, c.fechaEmision.month, c.fechaEmision.day);
        final desde = DateTime(f.fechaDesde!.year, f.fechaDesde!.month, f.fechaDesde!.day);
        if (d.isBefore(desde)) return false;
      }
      if (f.fechaHasta != null) {
        final d = DateTime(c.fechaEmision.year, c.fechaEmision.month, c.fechaEmision.day);
        final hasta = DateTime(f.fechaHasta!.year, f.fechaHasta!.month, f.fechaHasta!.day);
        if (d.isAfter(hasta)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comprasAsync = ref.watch(listadoComprasProvider);
    final filtros = ref.watch(_filtrosComprasProvider);
    final confirmarCompra = ref.read(confirmarCompraUseCaseProvider);
    final anularCompra = ref.read(anularCompraProvider);
    final ancho = MediaQuery.of(context).size.width;
    final esPequena = ancho < 768;

    Widget infoItem(String etiqueta, String valor, {bool destacado = false}) {
      return RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$etiqueta: ',
              style: AppTypography.labelSmall.copyWith(
                color: destacado ? AppColors.error : AppColors.textSecondary,
              ),
            ),
            TextSpan(
              text: valor,
              style: AppTypography.labelSmall.copyWith(
                fontWeight: destacado ? FontWeight.bold : FontWeight.w500,
                color: destacado ? AppColors.error : null,
              ),
            ),
          ],
        ),
      );
    }

    Future<void> mostrarFiltros() async {
      final actual = ref.read(_filtrosComprasProvider);
      final textoCtrl = TextEditingController(text: actual.textoBusqueda);
      final montoMinCtrl = TextEditingController(
        text: actual.montoMin?.toStringAsFixed(0) ?? '',
      );
      final montoMaxCtrl = TextEditingController(
        text: actual.montoMax?.toStringAsFixed(0) ?? '',
      );
      EstadoCompra? estadoSel = actual.estado;
      bool? creditoSel = actual.soloCredito;
      String? tipoSel = actual.tipoComprobante;
      DateTime? desde = actual.fechaDesde;
      DateTime? hasta = actual.fechaHasta;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setModalState) {
              return SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: AppSpacing.l,
                    right: AppSpacing.l,
                    top: AppSpacing.m,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.l,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Filtros de compras', style: AppTypography.h4Bold),
                        const SizedBox(height: AppSpacing.m),
                        TextField(
                          controller: textoCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Buscar (proveedor, NCF, n°)',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        const Text('Condición de pago', style: AppTypography.bodyMediumSemiBold),
                        const SizedBox(height: AppSpacing.xs),
                        SegmentedButton<bool?>(
                          segments: const [
                            ButtonSegment(value: null, label: Text('Todos')),
                            ButtonSegment(value: false, label: Text('Contado')),
                            ButtonSegment(value: true, label: Text('Crédito')),
                          ],
                          selected: {creditoSel},
                          onSelectionChanged: (s) {
                            setModalState(() => creditoSel = s.first);
                          },
                        ),
                        const SizedBox(height: AppSpacing.s),
                        DropdownButtonFormField<EstadoCompra?>(
                          initialValue: estadoSel,
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Todos')),
                            ...EstadoCompra.values.map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e.name[0].toUpperCase() + e.name.substring(1)),
                              ),
                            ),
                          ],
                          onChanged: (v) => setModalState(() => estadoSel = v),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        DropdownButtonFormField<String?>(
                          initialValue: tipoSel,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de comprobante',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Todos')),
                            DropdownMenuItem(value: '01', child: Text('01 - Factura')),
                            DropdownMenuItem(value: '02', child: Text('02 - Nota de crédito')),
                            DropdownMenuItem(value: '03', child: Text('03 - Nota de débito')),
                            DropdownMenuItem(value: '04', child: Text('04 - Nota de entrega')),
                          ],
                          onChanged: (v) => setModalState(() => tipoSel = v),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: montoMinCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Monto mín.',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  prefixText: 'RD\$ ',
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s),
                            Expanded(
                              child: TextField(
                                controller: montoMaxCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Monto máx.',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  prefixText: 'RD\$ ',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_today, size: AppSizes.iconSm),
                                label: Text(
                                  desde == null ? 'Desde' : _formatearFecha(desde!),
                                ),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: ctx,
                                    initialDate: desde ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (picked != null) {
                                    setModalState(() => desde = picked);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_today, size: AppSizes.iconSm),
                                label: Text(
                                  hasta == null ? 'Hasta' : _formatearFecha(hasta!),
                                ),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: ctx,
                                    initialDate: hasta ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (picked != null) {
                                    setModalState(() => hasta = picked);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.l),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  ref.read(_filtrosComprasProvider.notifier).state =
                                      const _FiltrosCompras();
                                  Navigator.pop(ctx);
                                },
                                child: const Text('Limpiar'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                ),
                                onPressed: () {
                                  final min = double.tryParse(montoMinCtrl.text.trim());
                                  final max = double.tryParse(montoMaxCtrl.text.trim());
                                  ref.read(_filtrosComprasProvider.notifier).state =
                                      _FiltrosCompras(
                                    textoBusqueda: textoCtrl.text.trim(),
                                    soloCredito: creditoSel,
                                    estado: estadoSel,
                                    tipoComprobante: tipoSel,
                                    montoMin: min,
                                    montoMax: max,
                                    fechaDesde: desde,
                                    fechaHasta: hasta,
                                  );
                                  Navigator.pop(ctx);
                                },
                                child: const Text('Aplicar'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Badge(
                      isLabelVisible: filtros.tieneFiltrosActivos,
                      child: const Icon(Icons.filter_list),
                    ),
                    tooltip: 'Filtros',
                    onPressed: mostrarFiltros,
                  ),
                ],
              ),
            ),
            Expanded(
              child: comprasAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object error, StackTrace _) => Center(
                  child: Padding(
                    padding: AppLayout.pantallaPadding,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: AppSizes.iconXl, color: AppColors.error),
                        const SizedBox(height: AppSpacing.m),
                        const Text('Error al cargar compras', style: AppTypography.h4Bold),
                        const SizedBox(height: AppSpacing.xs),
                        Text('$error', textAlign: TextAlign.center, style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                ),
                data: (List<Compra> todas) {
                  final compras = _aplicarFiltros(todas, filtros);
                  if (todas.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: AppLayout.pantallaPadding,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shopping_cart_outlined, size: AppSizes.iconXl, color: AppColors.grey200),
                            const SizedBox(height: AppSpacing.m),
                            Text(
                              'No hay compras registradas.',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            const Text(
                              'Presiona el botón "+" para registrar tu primera compra.',
                              style: AppTypography.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (compras.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: AppLayout.pantallaPadding,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.filter_alt_off, size: AppSizes.iconXl, color: AppColors.grey200),
                            const SizedBox(height: AppSpacing.m),
                            Text(
                              'Ninguna compra coincide con los filtros.',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: AppSpacing.s),
                            TextButton(
                              onPressed: () {
                                ref.read(_filtrosComprasProvider.notifier).state =
                                    const _FiltrosCompras();
                              },
                              child: const Text('Limpiar filtros'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      if (filtros.tieneFiltrosActivos)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.s, AppSpacing.m, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${compras.length} de ${todas.length} compras',
                                  style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                                ),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.clear, size: AppSizes.iconSm),
                                label: const Text('Limpiar'),
                                onPressed: () {
                                  ref.read(_filtrosComprasProvider.notifier).state =
                                      const _FiltrosCompras();
                                },
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: ListView.separated(
                          padding: AppLayout.pantallaPadding,
                          itemCount: compras.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.m),
                          itemBuilder: (context, index) {
                            final compra = compras[index];
                            final idLimpio = _limpiarId(compra.id);
                            final vencida = compra.estaVencida;

                            Widget buildEstadoTag() {
                              if (vencida &&
                                  (compra.estado == EstadoCompra.registrada ||
                                      compra.estado == EstadoCompra.confirmada)) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xs),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Vencida',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }
                              Color color;
                              String texto;
                              switch (compra.estado) {
                                case EstadoCompra.borrador:
                                  color = AppColors.warning;
                                  texto = 'Borrador';
                                  break;
                                case EstadoCompra.registrada:
                                  color = AppColors.primary;
                                  texto = 'Registrada';
                                  break;
                                case EstadoCompra.confirmada:
                                  color = AppColors.success;
                                  texto = 'Confirmada';
                                  break;
                                case EstadoCompra.recibida:
                                  color = AppColors.secondary;
                                  texto = 'Recibida';
                                  break;
                                case EstadoCompra.pagada:
                                  color = AppColors.primaryDark;
                                  texto = 'Pagada';
                                  break;
                                case EstadoCompra.anulada:
                                  color = AppColors.error;
                                  texto = 'Anulada';
                                  break;
                                default:
                                  color = AppColors.grey500;
                                  texto = 'Desconocida';
                              }
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xs),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  texto,
                                  style: AppTypography.labelSmall.copyWith(color: color),
                                ),
                              );
                            }

                            void verDetalle() {
                              if (idLimpio.isNotEmpty) {
                                context.goNamed(
                                  DetalleCompraPage.routeName,
                                  pathParameters: {'compraId': idLimpio},
                                );
                              }
                            }

                            Future<void> confirmar() async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Confirmar Compra'),
                                  content: const Text(
                                    '¿Confirmar esta compra?\n\n'
                                    'Se actualizará inventario, Kardex, costos de producto '
                                    'y el saldo del proveedor.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        foregroundColor: AppColors.white,
                                      ),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Sí, Confirmar'),
                                    ),
                                  ],
                                ),
                              );
                              if (ok != true) return;
                              if (!context.mounted) return;
                              try {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Confirmando compra...')),
                                  );
                                }
                                await confirmarCompra(compra.id);
                                if (!context.mounted) return;
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Compra confirmada ✅'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                                ref.invalidate(listadoComprasProvider);
                                ref.invalidate(productoControllerProvider);
                              } catch (e) {
                                if (!context.mounted) return;
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            }

                            Future<void> duplicar() async {
                              try {
                                final repo = ref.read(compraRepositoryProvider);
                                final detalles = await repo.listarDetallesDeCompra(compra.id);
                                final ahora = DateTime.now();
                                final nuevoId = ahora.millisecondsSinceEpoch;
                                final nuevaCompra = compra.copyWith(
                                  id: nuevoId,
                                  numeroComprobante: '${compra.numeroComprobante}-COPIA',
                                  estado: EstadoCompra.borrador,
                                  fechaEmision: ahora,
                                  fechaConfirmacion: null,
                                  creadoEn: ahora,
                                  actualizadoEn: null,
                                  observaciones: 'Duplicado de #${compra.id}',
                                );
                                final nuevosDetalles = <DetalleCompra>[];
                                for (var i = 0; i < detalles.length; i++) {
                                  final d = detalles[i];
                                  nuevosDetalles.add(
                                    d.copyWith(
                                      id: nuevoId * 1000 + i,
                                      compraId: nuevoId,
                                    ),
                                  );
                                }
                                await repo.registrarCompra(
                                  compra: nuevaCompra,
                                  detalles: nuevosDetalles,
                                );
                                if (!context.mounted) return;
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Compra duplicada como borrador ✅'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                                ref.invalidate(listadoComprasProvider);
                              } catch (e) {
                                if (!context.mounted) return;
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error al duplicar: $e'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            }

                            Future<void> imprimir() async {
                              final buffer = StringBuffer();
                              buffer.writeln('══════════════════════════════════');
                              buffer.writeln('       COMPROBANTE DE COMPRA');
                              buffer.writeln('══════════════════════════════════');
                              buffer.writeln(
                                'N°: ${compra.numeroComprobante.isNotEmpty ? compra.numeroComprobante : compra.id}',
                              );
                              buffer.writeln('Fecha: ${_formatearFecha(compra.fechaEmision)}');
                              buffer.writeln('Proveedor: ${compra.nombreProveedor}');
                              if (compra.ncf.isNotEmpty) buffer.writeln('NCF: ${compra.ncf}');
                              buffer.writeln('Tipo: ${compra.tipoComprobante}');
                              buffer.writeln(
                                'Pago: ${compra.esCredito ? 'Crédito (${compra.diasCredito} días)' : 'Contado'}',
                              );
                              buffer.writeln('Estado: ${compra.estado.name}');
                              buffer.writeln('──────────────────────────────────');
                              buffer.writeln(
                                'Subtotal:  RD\$ ${compra.subtotalSinImpuestos.toStringAsFixed(2)}',
                              );
                              buffer.writeln(
                                'Descuento: RD\$ ${compra.montoDescuentoGlobal.toStringAsFixed(2)}',
                              );
                              buffer.writeln(
                                'ITBIS:     RD\$ ${compra.montoImpuesto.toStringAsFixed(2)}',
                              );
                              buffer.writeln(
                                'TOTAL:     RD\$ ${compra.totalCompra.toStringAsFixed(2)}',
                              );
                              buffer.writeln('══════════════════════════════════');
                              buffer.writeln('FiscoGest RD');
                              await Share.share(
                                buffer.toString(),
                                subject:
                                    'Compra ${compra.numeroComprobante.isNotEmpty ? compra.numeroComprobante : '#${compra.id}'}',
                              );
                            }

                            Future<void> anular() async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Anular Compra'),
                                  content: const Text(
                                    '¿Anular esta compra?\n\n'
                                    'Se revertirá el impacto en inventario, costos y saldo del proveedor.\n'
                                    'Si tiene abonos registrados no se podrá anular la cuenta por pagar.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.error,
                                        foregroundColor: AppColors.white,
                                      ),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Sí, Anular'),
                                    ),
                                  ],
                                ),
                              );
                              if (ok != true) return;
                              if (!context.mounted) return;
                              try {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Anulando compra...')),
                                  );
                                }
                                await anularCompra(compra.id);
                                if (!context.mounted) return;
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Compra anulada ✅'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                                ref.invalidate(listadoComprasProvider);
                                ref.invalidate(productoControllerProvider);
                              } catch (e) {
                                if (!context.mounted) return;
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            }

                            return AppCard(
                              padding: AppSpacing.allM,
                              color: vencida ? AppColors.error.withValues(alpha: 0.05) : null,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              compra.numeroComprobante.isNotEmpty
                                                  ? compra.numeroComprobante
                                                  : 'Compra #${compra.id}',
                                              style: AppTypography.bodyMediumBold.copyWith(fontSize: 15),
                                            ),
                                            const SizedBox(height: AppSpacing.xs),
                                            Text(compra.nombreProveedor, style: AppTypography.bodySmall),
                                          ],
                                        ),
                                      ),
                                      buildEstadoTag(),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, size: AppSizes.iconMd),
                                        onSelected: (value) async {
                                          switch (value) {
                                            case 'ver':
                                              verDetalle();
                                              break;
                                            case 'editar':
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Edición de borradores: próximamente',
                                                    ),
                                                  ),
                                                );
                                              }
                                              break;
                                            case 'duplicar':
                                              await duplicar();
                                              break;
                                            case 'imprimir':
                                              await imprimir();
                                              break;
                                            case 'confirmar':
                                              await confirmar();
                                              break;
                                            case 'anular':
                                              await anular();
                                              break;
                                          }
                                        },
                                        itemBuilder: (ctx) => [
                                          const PopupMenuItem(
                                            value: 'ver',
                                            child: ListTile(
                                              leading: Icon(Icons.visibility, size: AppSizes.iconMd),
                                              title: Text('Ver'),
                                              dense: true,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                          if (compra.estado == EstadoCompra.borrador)
                                            const PopupMenuItem(
                                              value: 'editar',
                                              child: ListTile(
                                                leading: Icon(Icons.edit, size: AppSizes.iconMd),
                                                title: Text('Editar'),
                                                dense: true,
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                            ),
                                          const PopupMenuItem(
                                            value: 'duplicar',
                                            child: ListTile(
                                              leading: Icon(Icons.copy, size: AppSizes.iconMd),
                                              title: Text('Duplicar'),
                                              dense: true,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'imprimir',
                                            child: ListTile(
                                              leading: Icon(Icons.print, size: AppSizes.iconMd),
                                              title: Text('Imprimir'),
                                              dense: true,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                          if (compra.estado == EstadoCompra.borrador)
                                            const PopupMenuItem(
                                              value: 'confirmar',
                                              child: ListTile(
                                                leading: Icon(
                                                  Icons.check_circle,
                                                  size: AppSizes.iconMd,
                                                  color: AppColors.success,
                                                ),
                                                title: Text('Confirmar'),
                                                dense: true,
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                            ),
                                          if (compra.estado != EstadoCompra.anulada &&
                                              compra.estado != EstadoCompra.borrador)
                                            const PopupMenuItem(
                                              value: 'anular',
                                              child: ListTile(
                                                leading: Icon(
                                                  Icons.cancel,
                                                  size: AppSizes.iconMd,
                                                  color: AppColors.error,
                                                ),
                                                title: Text('Anular'),
                                                dense: true,
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.s),
                                  Wrap(
                                    spacing: AppSpacing.m,
                                    runSpacing: AppSpacing.s,
                                    children: [
                                      infoItem('Fecha', _formatearFecha(compra.fechaEmision)),
                                      if (compra.ncf.isNotEmpty) infoItem('NCF', compra.ncf),
                                      infoItem('Tipo', compra.tipoComprobante),
                                      infoItem(
                                        'Pago',
                                        compra.esCredito ? 'Crédito' : 'Contado',
                                      ),
                                      if (compra.esCredito)
                                        infoItem(
                                          compra.diasCredito > 0 ? 'Plazo' : 'Vence',
                                          compra.fechaVencimientoCalculada != null
                                              ? _formatearFecha(compra.fechaVencimientoCalculada!)
                                              : '${compra.diasCredito} días',
                                          destacado: vencida,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.s),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total: RD\$ ${compra.totalCompra.toStringAsFixed(2)}',
                                        style: AppTypography.bodyMediumBold.copyWith(fontSize: 15),
                                      ),
                                      if (!esPequena)
                                        TextButton.icon(
                                          icon: const Icon(Icons.visibility, size: AppSizes.iconSm),
                                          label: const Text('Ver'),
                                          onPressed: verDetalle,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'nueva_compra',
        onPressed: () => context.goNamed(RegistrarCompraPage.routeName),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: const Text('Nueva Compra', style: TextStyle(color: AppColors.white)),
      ),
    );
  }
}
