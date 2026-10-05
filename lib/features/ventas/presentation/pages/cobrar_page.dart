import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

final listadoCuentasCobrarProvider =
    FutureProvider.family<List<CuentaCobrarItem>, int>((
      ref,
      clienteIdFiltro,
    ) async {
      final db = ref.watch<AppDatabase>(appDatabaseProvider);
      final dao = CuentasCobrarDao(db);
      final registros = await dao.listarCuentasPorCobrar();
      final registrosFiltrados = registros.where((r) {
        final tieneSaldo = r.saldoPendiente > 0.001;
        final coincideCliente =
            clienteIdFiltro <= 0 || r.clienteId == clienteIdFiltro;
        return tieneSaldo && coincideCliente;
      }).toList();
      final idsClientes = registrosFiltrados.map((r) => r.clienteId).toSet();
      final List<ClientesTableData> registrosClientes = idsClientes.isNotEmpty
          ? await (db.select(
              db.clientesTable,
            )..where((t) => t.id.isIn(idsClientes))).get()
          : <ClientesTableData>[];
      final mapaClientes = <int, ClientesTableData>{
        for (final row in registrosClientes) row.id: row,
      };
      return Future.wait(
        registrosFiltrados.map((reg) async {
          final cliente = mapaClientes[reg.clienteId];
          final nombreCliente = cliente?.nombre ?? 'Cliente #${reg.clienteId}';
          final estadoTexto = switch (reg.estado) {
            CobrarEstado.pagado => 'Pagado',
            CobrarEstado.vencido => 'Vencido',
            CobrarEstado.parcial => 'Parcial',
            _ => 'Pendiente',
          };
          final cuotas = await dao.listarCuotas(reg.id);
          CuotaCobrarItem? proximaCuota;
          for (final cuota in cuotas) {
            if (cuota.estado != 'pagada') {
              proximaCuota = CuotaCobrarItem(
                monto: (cuota.monto - cuota.montoPagado).clamp(
                  0.0,
                  double.infinity,
                ),
                fecha: cuota.fechaVencimiento,
              );
              break;
            }
          }
          return CuentaCobrarItem(
            id: reg.id,
            ventaId: reg.ventaId,
            proximaCuota: proximaCuota,
            clienteId: reg.clienteId,
            clienteNombre: nombreCliente,
            clienteDocumento: cliente?.rncCedula ?? '',
            montoOriginal: reg.montoOriginal,
            montoAbonado: reg.montoAbonado,
            saldoPendiente: reg.saldoPendiente,
            fechaVencimiento: reg.fechaVencimiento,
            estado: estadoTexto,
          );
        }),
      );
    });

class CuentaCobrarItem {
  const CuentaCobrarItem({
    required this.id,
    required this.clienteId,
    this.ventaId,
    this.proximaCuota,
    required this.clienteNombre,
    this.clienteDocumento = '',
    required this.montoOriginal,
    required this.montoAbonado,
    required this.saldoPendiente,
    required this.fechaVencimiento,
    required this.estado,
  });
  final int id;
  final int clienteId;
  final int? ventaId;
  final CuotaCobrarItem? proximaCuota;
  final String clienteNombre;
  final String clienteDocumento;
  final double montoOriginal;
  final double montoAbonado;
  final double saldoPendiente;
  final DateTime fechaVencimiento;
  final String estado;
}

class CuotaCobrarItem {
  const CuotaCobrarItem({required this.monto, required this.fecha});

  final double monto;
  final DateTime fecha;
}

class CobrarPage extends ConsumerStatefulWidget {
  const CobrarPage({
    super.key,
    this.clienteIdFiltro = 0,
    this.onVolver,
    this.onIrACredito,
  });

  final int clienteIdFiltro;
  final VoidCallback? onVolver;
  final VoidCallback? onIrACredito;

  static const String routeName = 'cobrar';

  @override
  ConsumerState<CobrarPage> createState() => _CobrarPageState();
}

class _CobrarPageState extends ConsumerState<CobrarPage> {
  static final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy');
  final TextEditingController _busquedaController = TextEditingController();
  String _textoBusqueda = '';

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  String _normalizarDocumento(String valor) =>
      valor.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  Color _colorEstado(String estado) {
    return switch (estado) {
      'Pendiente' => AppColors.warning,
      'Parcial' => AppColors.info,
      'Pagado' => AppColors.success,
      'Vencido' => AppColors.error,
      _ => AppColors.grey500,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cuentasAsync = ref.watch(
      listadoCuentasCobrarProvider(widget.clienteIdFiltro),
    );
    final esPantallaPequena = MediaQuery.of(context).size.width < 600;
    final paddingTexto = esPantallaPequena ? 12.0 : 16.0;
    final tamanoCuerpo = esPantallaPequena ? 13.0 : 14.0;
    final tamanoEtiqueta = esPantallaPequena ? 11.0 : 12.0;
    final espaciadoTarjeta = esPantallaPequena ? 8.0 : 12.0;

    return AppScaffold(
      title: widget.clienteIdFiltro > 0
          ? 'Cuentas por Cobrar — Cliente'
          : 'Cuentas por Cobrar',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (widget.onVolver != null) {
            widget.onVolver!();
          } else if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      ),
      actions: [
        if (widget.onIrACredito != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: widget.onIrACredito,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('NUEVO CRÉDITO'),
            ),
          ),
      ],
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(listadoCuentasCobrarProvider(widget.clienteIdFiltro));
        },
        child: cuentasAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: EdgeInsets.all(paddingTexto),
              child: Text(
                'Error: $e',
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: tamanoCuerpo,
                ),
              ),
            ),
          ),
          data: (cuentas) {
            final consulta = _textoBusqueda.trim().toLowerCase();
            final consultaDocumento = _normalizarDocumento(consulta);
            final cuentasFiltradas = consulta.isEmpty
                ? cuentas
                : cuentas.where((cuenta) {
                    final nombre = cuenta.clienteNombre.toLowerCase();
                    final documento = _normalizarDocumento(
                      cuenta.clienteDocumento,
                    );
                    return nombre.contains(consulta) ||
                        (consultaDocumento.isNotEmpty &&
                            documento.contains(consultaDocumento));
                  }).toList();
            if (cuentas.isEmpty) {
              return Center(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppLayout.pantallaPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 48,
                        color: AppColors.textSecondary.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.clienteIdFiltro > 0
                            ? 'Este cliente no tiene cuentas por cobrar'
                            : 'No hay cuentas por cobrar',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Al registrar una venta a crédito, aparecerá aquí.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: esPantallaPequena ? 560 : 340,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextField(
                        controller: _busquedaController,
                        onChanged: (valor) =>
                            setState(() => _textoBusqueda = valor),
                        decoration: InputDecoration(
                          hintText: 'Buscar nombre, RNC o cédula',
                          isDense: true,
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _textoBusqueda.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Limpiar búsqueda',
                                  onPressed: () {
                                    _busquedaController.clear();
                                    setState(() => _textoBusqueda = '');
                                  },
                                  icon: const Icon(Icons.clear, size: 18),
                                ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: cuentasFiltradas.isEmpty
                      ? Center(
                          child: Text(
                            'No hay clientes que coincidan con la búsqueda.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : GridView.builder(
                          padding: AppLayout.pantallaPadding,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: esPantallaPequena ? 2 : 3,
                                crossAxisSpacing: espaciadoTarjeta,
                                mainAxisSpacing: espaciadoTarjeta,
                                mainAxisExtent: esPantallaPequena ? 300 : 270,
                              ),
                          itemCount: cuentasFiltradas.length,
                          itemBuilder: (context, i) {
                            final c = cuentasFiltradas[i];
                            final vencida = c.estado == 'Vencido';
                            return Card(
                              margin: EdgeInsets.zero,
                              color: vencida
                                  ? AppColors.grey100
                                  : AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.allM,
                                side: const BorderSide(color: AppColors.border),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                borderRadius: AppRadius.allM,
                                onTap: () async {
                                  await context.push(
                                    '/creditos/cuentas/${c.id}',
                                  );
                                  ref.invalidate(
                                    listadoCuentasCobrarProvider(
                                      widget.clienteIdFiltro,
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(paddingTexto),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.clienteNombre,
                                        style: AppTypography.bodyMediumSemiBold,
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      if (c.ventaId != null)
                                        Text(
                                          'Venta relacionada: #${c.ventaId}',
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                        ),
                                      Text(
                                        'Total: ${formatRd(c.montoOriginal)}',
                                        style: AppTypography.bodyMedium
                                            .copyWith(fontSize: tamanoCuerpo),
                                      ),
                                      Text(
                                        'Abonado: ${formatRd(c.montoAbonado)}',
                                        style: AppTypography.bodyMedium
                                            .copyWith(fontSize: tamanoCuerpo),
                                      ),
                                      Text(
                                        'Saldo pendiente: ${formatRd(c.saldoPendiente)}',
                                        style: AppTypography.bodyMedium
                                            .copyWith(
                                              fontSize: tamanoCuerpo,
                                              fontWeight: FontWeight.w600,
                                              color: vencida
                                                  ? AppColors.error
                                                  : AppColors.primary,
                                            ),
                                      ),
                                      Text(
                                        'Vence: ${_formatoFecha.format(c.fechaVencimiento)}',
                                        style: AppTypography.bodyMedium
                                            .copyWith(fontSize: tamanoCuerpo),
                                      ),
                                      if (c.proximaCuota != null)
                                        Text(
                                          'Próxima cuota: ${formatRd(c.proximaCuota!.monto)} · ${_formatoFecha.format(c.proximaCuota!.fecha)}',
                                          style: AppTypography.bodyMedium
                                              .copyWith(
                                                fontSize: tamanoCuerpo,
                                                color: AppColors.info,
                                              ),
                                        ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.s,
                                          vertical: AppSpacing.xs,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _colorEstado(c.estado),
                                          borderRadius: AppRadius.allM,
                                        ),
                                        child: Text(
                                          c.estado,
                                          style: AppTypography.labelSmall
                                              .copyWith(
                                                fontSize: tamanoEtiqueta,
                                                color: AppColors.white,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        'Ver cuotas, pagos y estado de cuenta  ›',
                                        style: AppTypography.labelSmall
                                            .copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
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
    );
  }
}
