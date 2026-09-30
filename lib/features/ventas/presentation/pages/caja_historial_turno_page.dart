import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/caja/domain/repositories/i_caja_repository.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart';

class CajaHistorialTurnoPage extends ConsumerStatefulWidget {
  const CajaHistorialTurnoPage({super.key, this.desde});

  static const String routeName = 'caja-historial-turno';
  static const String path = '/ventas/cobro/historial-turno';

  final DateTime? desde;

  @override
  ConsumerState<CajaHistorialTurnoPage> createState() =>
      _CajaHistorialTurnoPageState();
}

class _CajaHistorialTurnoPageState
    extends ConsumerState<CajaHistorialTurnoPage> {
  List<CajaMovimientoResumen> _items = [];
  bool _cargando = true;
  String? _error;
  DateTime? _desdeUsado;

  static final _fmt = DateFormat('dd/MM/yyyy HH:mm');
  static final _fmtMonto = NumberFormat('#,##0.00', 'es_DO');

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final repo = ref.read(cajaRepositoryProvider);
      var desde = widget.desde;
      if (desde == null) {
        final sesion = await repo.obtenerSesionAbierta();
        desde =
            sesion?.fechaApertura ??
            DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
            );
      }
      final lista = await repo.listarMovimientosDesde(desde);
      if (!mounted) return;
      setState(() {
        _desdeUsado = desde;
        _items = lista;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);
    final maxW = desktop ? 920 : (mobile ? 520 : 720);

    return AppScaffold(
      title: 'MOVIMIENTOS DEL TURNO',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/ventas/cobro');
          }
        },
      ),
      body: SafeArea(
        child: AppLayout.centerConstrained(
          maxWidth: maxW,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: AppLayout.pantallaPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historial del turno',
                      style: AppTypography.h4.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (_desdeUsado != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Desde ${_fmt.format(_desdeUsado!)}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.grey600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: _cargando
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      )
                    : _items.isEmpty
                    ? Center(
                        child: Text(
                          'Sin movimientos en este turno',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : Padding(
                        padding: AppLayout.pantallaPadding,
                        child: AppCard(
                          padding: EdgeInsets.zero,
                          child: RefreshIndicator(
                            onRefresh: _cargar,
                            child: ListView.separated(
                              itemCount: _items.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                color: AppColors.border,
                              ),
                              itemBuilder: (_, i) {
                                final m = _items[i];
                                final esIngreso = m.tipo.toLowerCase().contains(
                                  'ingreso',
                                );
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: mobile ? 14 : 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        esIngreso
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        color: esIngreso
                                            ? AppColors.success
                                            : AppColors.error,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${m.tipo.toUpperCase()} · ${m.formaPago}',
                                              style: AppTypography.labelMedium
                                                  .copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                            ),
                                            Text(
                                              '${m.referenciaTipo} #${m.referenciaId} · ${_fmt.format(m.fecha)}',
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                    color: AppColors.grey600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'RD\$ ${_fmtMonto.format(m.monto)}',
                                            style: AppTypography.labelMedium
                                                .copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: esIngreso
                                                      ? AppColors.success
                                                      : AppColors.error,
                                                ),
                                          ),
                                          Text(
                                            'Saldo ${_fmtMonto.format(m.saldoNuevo)}',
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                                  color: AppColors.grey600,
                                                  fontSize: 11,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
