import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/configuracion/presentation/providers/configuracion_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/detalle_compra.dart';
import 'package:fiscogest_rd/features/comercial/presentation/providers/compra/compra_usecase_providers.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/registrar_compra_page.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/detalle_compra_page.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/cuentas_pagar/lista_cuentas_pagar_page.dart';

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
      tipoComprobante:
          clearTipo ? null : (tipoComprobante ?? this.tipoComprobante),
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

final _filtrosComprasProvider =
    StateProvider.autoDispose<_FiltrosCompras>((ref) => const _FiltrosCompras());

/// Lista de compras — layout analítica (HTML mock).
class ListaComprasPage extends ConsumerWidget {
  const ListaComprasPage({super.key});

  static const String routeName = 'lista-compras';

  String _limpiarId(dynamic id) =>
      id.toString().replaceAll(RegExp(r'[^0-9]'), '');

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
        final d = DateTime(
          c.fechaEmision.year,
          c.fechaEmision.month,
          c.fechaEmision.day,
        );
        final desde = DateTime(
          f.fechaDesde!.year,
          f.fechaDesde!.month,
          f.fechaDesde!.day,
        );
        if (d.isBefore(desde)) return false;
      }
      if (f.fechaHasta != null) {
        final d = DateTime(
          c.fechaEmision.year,
          c.fechaEmision.month,
          c.fechaEmision.day,
        );
        final hasta = DateTime(
          f.fechaHasta!.year,
          f.fechaHasta!.month,
          f.fechaHasta!.day,
        );
        if (d.isAfter(hasta)) return false;
      }
      return true;
    }).toList();
  }

  (String, Color, Color) _estadoChip(EstadoCompra estado, bool vencida) {
    if (vencida &&
        (estado == EstadoCompra.registrada ||
            estado == EstadoCompra.confirmada)) {
      return (
        'Vencida',
        const Color(0xFFFFEBEE),
        const Color(0xFFC62828),
      );
    }
    return switch (estado) {
      EstadoCompra.pagada => (
          'Pagada',
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
        ),
      EstadoCompra.confirmada => (
          'Confirmada',
          const Color(0xFFE3F2FD),
          const Color(0xFF1565C0),
        ),
      EstadoCompra.registrada => (
          'Registrada',
          const Color(0xFFE3F2FD),
          const Color(0xFF1565C0),
        ),
      EstadoCompra.recibida => (
          'Recibida',
          const Color(0xFFF3E5F5),
          const Color(0xFF7B1FA2),
        ),
      EstadoCompra.borrador => (
          'Borrador',
          const Color(0xFFFFF8E1),
          const Color(0xFFF9A825),
        ),
      EstadoCompra.anulada => (
          'Anulada',
          const Color(0xFFFFEBEE),
          const Color(0xFFC62828),
        ),
      EstadoCompra.vencida => (
          'Vencida',
          const Color(0xFFFFEBEE),
          const Color(0xFFC62828),
        ),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comprasAsync = ref.watch(listadoComprasProvider);
    final filtros = ref.watch(_filtrosComprasProvider);
    final confirmarCompra = ref.read(confirmarCompraUseCaseProvider);
    final anularCompra = ref.read(anularCompraProvider);
    final isMobile = AppBreakpoints.isMobile(context);
    final modoSimplificado = ref
            .watch(configuracionControllerProvider)
            .valueOrNull
            ?.modoSimplificado ??
        false;

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
        backgroundColor: Colors.white,
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
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Filtros de compras',
                          style: AppTypography.h4
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: textoCtrl,
                          decoration: InputDecoration(
                            labelText: modoSimplificado
                                ? 'Buscar proveedor o número'
                                : 'Buscar (proveedor, NCF, n°)',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<bool?>(
                          segments: const [
                            ButtonSegment(value: null, label: Text('Todos')),
                            ButtonSegment(
                                value: false, label: Text('Contado')),
                            ButtonSegment(
                                value: true, label: Text('Crédito')),
                          ],
                          selected: {creditoSel},
                          onSelectionChanged: (s) =>
                              setModalState(() => creditoSel = s.first),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<EstadoCompra?>(
                          initialValue: estadoSel,
                          decoration: InputDecoration(
                            labelText: 'Estado',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Todos'),
                            ),
                            ...EstadoCompra.values.map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(
                                  e.name[0].toUpperCase() + e.name.substring(1),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) =>
                              setModalState(() => estadoSel = v),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: montoMinCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Monto mín.',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  isDense: true,
                                  prefixText: 'RD\$ ',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: montoMaxCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Monto máx.',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  isDense: true,
                                  prefixText: 'RD\$ ',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_today,
                                    size: 16),
                                label: Text(
                                  desde == null
                                      ? 'Desde'
                                      : _formatearFecha(desde!),
                                ),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: ctx,
                                    initialDate: desde ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 365)),
                                  );
                                  if (picked != null) {
                                    setModalState(() => desde = picked);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_today,
                                    size: 16),
                                label: Text(
                                  hasta == null
                                      ? 'Hasta'
                                      : _formatearFecha(hasta!),
                                ),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: ctx,
                                    initialDate: hasta ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 365)),
                                  );
                                  if (picked != null) {
                                    setModalState(() => hasta = picked);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  ref
                                      .read(_filtrosComprasProvider.notifier)
                                      .state = const _FiltrosCompras();
                                  Navigator.pop(ctx);
                                },
                                child: const Text('Limpiar'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF00796B),
                                ),
                                onPressed: () {
                                  ref
                                      .read(_filtrosComprasProvider.notifier)
                                      .state = _FiltrosCompras(
                                    textoBusqueda: textoCtrl.text.trim(),
                                    soloCredito: creditoSel,
                                    estado: estadoSel,
                                    tipoComprobante: tipoSel,
                                    montoMin: double.tryParse(
                                      montoMinCtrl.text.trim(),
                                    ),
                                    montoMax: double.tryParse(
                                      montoMaxCtrl.text.trim(),
                                    ),
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

    return AppScaffold(
      title: isMobile ? 'Lista de Compras' : null,
      showAppBar: isMobile,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Atrás',
        onPressed: () => context.go('/compras'),
      ),
      actions: [
        IconButton(
          icon: Badge(
            isLabelVisible: filtros.tieneFiltrosActivos,
            child: const Icon(Icons.filter_list),
          ),
          tooltip: 'Filtros',
          onPressed: mostrarFiltros,
        ),
      ],
      body: ColoredBox(
        color: const Color(0xFFF8FAFC),
        child: SafeArea(
          child: comprasAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
            data: (todas) {
              final compras = _aplicarFiltros(todas, filtros);
              final now = DateTime.now();
              final delMes = todas.where(
                (c) =>
                    c.fechaEmision.year == now.year &&
                    c.fechaEmision.month == now.month &&
                    c.estado != EstadoCompra.borrador &&
                    c.estado != EstadoCompra.anulada,
              );
              final totalMes =
                  delMes.fold<double>(0, (s, c) => s + c.totalCompra);
              final porPagar = todas
                  .where(
                    (c) =>
                        c.esCredito &&
                        c.estado != EstadoCompra.pagada &&
                        c.estado != EstadoCompra.anulada &&
                        c.estado != EstadoCompra.borrador,
                  )
                  .fold<double>(0, (s, c) => s + c.totalCompra);
              final proveedores =
                  todas.map((c) => c.nombreProveedor).toSet().length;
              final mesLabel = switch (now.month) {
                1 => 'Enero',
                2 => 'Febrero',
                3 => 'Marzo',
                4 => 'Abril',
                5 => 'Mayo',
                6 => 'Junio',
                7 => 'Julio',
                8 => 'Agosto',
                9 => 'Septiembre',
                10 => 'Octubre',
                11 => 'Noviembre',
                _ => 'Diciembre',
              };

              void setVistaRapida({
                EstadoCompra? estado,
                bool? credito,
                bool clear = false,
              }) {
                if (clear) {
                  ref.read(_filtrosComprasProvider.notifier).state =
                      const _FiltrosCompras();
                  return;
                }
                ref.read(_filtrosComprasProvider.notifier).state =
                    filtros.copyWith(
                  estado: estado,
                  soloCredito: credito,
                  clearEstado: estado == null && credito == null,
                  clearCredito: credito == null && estado != null,
                );
              }

              Widget compraCard(Compra compra) {
                final idLimpio = _limpiarId(compra.id);
                final vencida = compra.estaVencida;
                final (estadoTexto, bg, fg) =
                    _estadoChip(compra.estado, vencida);
                final titulo = compra.numeroComprobante.isNotEmpty
                    ? compra.numeroComprobante
                    : 'Compra #${compra.id}';

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
                        'Se actualizará inventario, Kardex, costos y saldo del proveedor.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Sí, Confirmar'),
                        ),
                      ],
                    ),
                  );
                  if (ok != true || !context.mounted) return;
                  try {
                    await confirmarCompra(compra.id);
                    if (!context.mounted) return;
                    FiscoGestNotifications.show(
                      const SnackBar(
                        content: Text('Compra confirmada ✅'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    ref.invalidate(listadoComprasProvider);
                    ref.invalidate(productoControllerProvider);
                  } catch (e) {
                    if (!context.mounted) return;
                    FiscoGestNotifications.show(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }

                Future<void> duplicar() async {
                  try {
                    final repo = ref.read(compraRepositoryProvider);
                    final detalles =
                        await repo.listarDetallesDeCompra(compra.id);
                    final ahora = DateTime.now();
                    final nuevoId = ahora.millisecondsSinceEpoch;
                    final nuevaCompra = compra.copyWith(
                      id: nuevoId,
                      numeroComprobante:
                          '${compra.numeroComprobante}-COPIA',
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
                    FiscoGestNotifications.show(
                      const SnackBar(
                        content: Text('Compra duplicada como borrador ✅'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    ref.invalidate(listadoComprasProvider);
                  } catch (e) {
                    if (!context.mounted) return;
                    FiscoGestNotifications.show(
                      SnackBar(
                        content: Text('Error al duplicar: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }

                Future<void> imprimir() async {
                  final buffer = StringBuffer()
                    ..writeln('COMPROBANTE DE COMPRA')
                    ..writeln(
                      'N°: ${compra.numeroComprobante.isNotEmpty ? compra.numeroComprobante : compra.id}',
                    )
                    ..writeln(
                      'Fecha: ${_formatearFecha(compra.fechaEmision)}',
                    )
                    ..writeln('Proveedor: ${compra.nombreProveedor}')
                    ..writeln(
                      'Pago: ${compra.esCredito ? 'Crédito' : 'Contado'}',
                    )
                    ..writeln('TOTAL: ${formatRd(compra.totalCompra)}');
                  await Share.share(
                    buffer.toString(),
                    subject: 'Compra ${compra.id}',
                  );
                }

                Future<void> anular() async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Anular Compra'),
                      content: const Text(
                        '¿Anular esta compra?\n\n'
                        'Se revertirá el impacto en inventario, costos y saldo.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Sí, Anular'),
                        ),
                      ],
                    ),
                  );
                  if (ok != true || !context.mounted) return;
                  try {
                    await anularCompra(compra.id);
                    if (!context.mounted) return;
                    FiscoGestNotifications.show(
                      const SnackBar(
                        content: Text('Compra anulada ✅'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    ref.invalidate(listadoComprasProvider);
                    ref.invalidate(productoControllerProvider);
                  } catch (e) {
                    if (!context.mounted) return;
                    FiscoGestNotifications.show(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }

                final borderColor = vencida
                    ? const Color(0xFFC62828)
                    : switch (compra.estado) {
                        EstadoCompra.pagada => const Color(0xFF2E7D32),
                        EstadoCompra.confirmada => const Color(0xFF1565C0),
                        EstadoCompra.registrada => const Color(0xFF1565C0),
                        EstadoCompra.recibida => const Color(0xFF7B1FA2),
                        EstadoCompra.borrador => const Color(0xFFF9A825),
                        EstadoCompra.anulada => const Color(0xFFC62828),
                        EstadoCompra.vencida => const Color(0xFF00796B),
                      };
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: verDetalle,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: borderColor.withValues(alpha: 0.10),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // .compra-row-top
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  titulo,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  estadoTexto,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: fg,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                iconSize: 18,
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Color(0xFF94A3B8),
                                ),
                                onSelected: (value) async {
                                  switch (value) {
                                    case 'ver':
                                      verDetalle();
                                    case 'duplicar':
                                      await duplicar();
                                    case 'imprimir':
                                      await imprimir();
                                    case 'confirmar':
                                      await confirmar();
                                    case 'anular':
                                      await anular();
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'ver',
                                    child: Text('Ver detalle'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'duplicar',
                                    child: Text('Duplicar'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'imprimir',
                                    child: Text('Imprimir'),
                                  ),
                                  if (compra.estado == EstadoCompra.borrador)
                                    const PopupMenuItem(
                                      value: 'confirmar',
                                      child: Text('Confirmar'),
                                    ),
                                  if (compra.estado != EstadoCompra.anulada &&
                                      compra.estado != EstadoCompra.borrador)
                                    const PopupMenuItem(
                                      value: 'anular',
                                      child: Text('Anular'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // .compra-proveedor
                          Row(
                            children: [
                              const Icon(
                                Icons.account_circle_outlined,
                                size: 18,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  compra.nombreProveedor.isEmpty
                                      ? 'Sin proveedor'
                                      : compra.nombreProveedor,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // .compra-detalles
                          Text(
                            'Fecha: ${_formatearFecha(compra.fechaEmision)}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                              height: 1.4,
                            ),
                          ),
                          Text(
                            'Tipo: ${compra.tipoComprobante.isEmpty ? '—' : compra.tipoComprobante}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                              height: 1.4,
                            ),
                          ),
                          Text(
                            'Pago: ${compra.esCredito ? 'Crédito' : 'Contado'}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // .compra-footer
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Total: ${formatRd(compra.totalCompra)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: verDetalle,
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.visibility_outlined,
                                      size: 15,
                                      color: Color(0xFF00796B),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Ver más',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: Color(0xFF00796B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }







              Widget kpi({
                required String title,
                required String value,
                required String sub,
                IconData icon = Icons.show_chart,
                Color? valueColor,
                Color accent = const Color(0xFF00796B),
              }) {
                final accentColor = valueColor ?? accent;
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accentColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: accentColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, size: 16, color: accentColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sub,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                );
              }

              Widget vistaTag(String label, bool active, VoidCallback onTap) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: active
                        ? const Color(0xFF00796B)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              final aside = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Vistas Rápidas',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  vistaTag(
                    'Todo',
                    !filtros.tieneFiltrosActivos,
                    () => setVistaRapida(clear: true),
                  ),
                  vistaTag(
                    'Por Pagar',
                    filtros.soloCredito == true &&
                        filtros.estado != EstadoCompra.pagada,
                    () => setVistaRapida(credito: true),
                  ),
                  vistaTag(
                    'Vencidas',
                    filtros.estado == EstadoCompra.vencida,
                    () => setVistaRapida(estado: EstadoCompra.vencida),
                  ),
                  vistaTag(
                    'Pagadas',
                    filtros.estado == EstadoCompra.pagada,
                    () => setVistaRapida(estado: EstadoCompra.pagada),
                  ),
                  vistaTag(
                    'Confirmadas',
                    filtros.estado == EstadoCompra.confirmada,
                    () => setVistaRapida(estado: EstadoCompra.confirmada),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Acciones Rápidas',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: mostrarFiltros,
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      foregroundColor: const Color(0xFF1E293B),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: const Text('Filtros avanzados'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () =>
                        context.goNamed(ListaCuentasPagarPage.routeName),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      foregroundColor: const Color(0xFF1E293B),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: const Text('Cuentas por pagar'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () =>
                          context.goNamed(RegistrarCompraPage.routeName),
                      icon: const Icon(Icons.add),
                      label: const Text('Nueva Compra / Gasto'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF00796B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              );

              if (isMobile) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () =>
                              context.go('/compras'),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const Expanded(
                          child: Text(
                            'Lista de Compras',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    kpi(
                      title: 'Resumen del Mes ($mesLabel)',
                      value: formatRd(totalMes),
                      sub: 'Total Compras',
                    ),
                    const SizedBox(height: 10),
                    kpi(
                      title: 'Pendiente de Pago',
                      value: formatRd(porPagar),
                      sub: 'Crédito no pagado',
                      icon: Icons.description_outlined,
                      valueColor: porPagar > 0
                          ? const Color(0xFFC62828)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    aside,
                    const SizedBox(height: 16),
                    if (compras.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Sin compras con estos filtros',
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      for (final c in compras) ...[
                        SizedBox(height: 160, child: compraCard(c)),
                        const SizedBox(height: 10),
                      ],
                  ],
                );
              }

              // Desktop HTML layout
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () =>
                              context.go('/compras'),
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Atrás',
                        ),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Text(
                            'Panel de Analítica de Compras',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        Text(
                          'Periodo: Este Mes ($mesLabel)',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: mostrarFiltros,
                          child: const Text('Rango Personalizado'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(right: 8, bottom: 16),
                            child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: kpi(
                                      title: 'Resumen del Mes ($mesLabel)',
                                      value: formatRd(totalMes),
                                      sub: 'Total Compras',
                                      accent: const Color(0xFF00796B),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: kpi(
                                      title: 'Pendiente de Pago',
                                      value: formatRd(porPagar),
                                      sub: 'Cuentas por pagar (crédito)',
                                      icon: Icons.description_outlined,
                                      accent: const Color(0xFFC62828),
                                      valueColor: const Color(0xFFC62828),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: kpi(
                                      title: 'Proveedores Activos',
                                      value: '$proveedores',
                                      sub: 'Total Proveedores',
                                      icon: Icons.people_outline,
                                      accent: const Color(0xFF1565C0),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: kpi(
                                      title: 'Filtradas',
                                      value: '${compras.length}',
                                      sub: 'de ${todas.length} totales',
                                      icon: Icons.filter_list,
                                      accent: const Color(0xFF5B21B6),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (compras.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(40),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: const Text(
                                    'Ninguna compra coincide con los filtros',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Color(0xFF64748B)),
                                  ),
                                )
                              else
                                LayoutBuilder(
                                  builder: (context, c) {
                                    // 2 pares por fila en desktop: [compra|notas] [compra|notas]
                                    final cols = 2; // HTML: grid-template-columns: repeat(2, 1fr)
                                    return GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: compras.length,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: cols,
                                        mainAxisExtent: 220,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                      ),
                                      itemBuilder: (_, i) =>
                                          compraCard(compras[i]),
                                    );
                                  },
                                ),
                            ],
                            ), // Column (scroll izq)
                          ), // SingleChildScrollView izq
                        ), // Expanded izq
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 200,
                          child: aside, // fijo: no va dentro del scroll
                        ),
                      ], // Row children
                    ), // Row
                    ), // Expanded body
                  ], // Column padding
                ), // Column
              ); // Padding
            },
          ),
        ),
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton.extended(
              heroTag: 'nueva_compra',
              onPressed: () =>
                  context.goNamed(RegistrarCompraPage.routeName),
              backgroundColor: const Color(0xFF00796B),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Nueva Compra',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }
}
