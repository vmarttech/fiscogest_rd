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
        desde = sesion?.fechaApertura ??
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
    final maxW = desktop ? 960 : (mobile ? 600 : 720);

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
                child: SectionHeader(
                  title: 'Historial del turno',
                  subtitle: _desdeUsado != null
                      ? 'Desde ${_fmt.format(_desdeUsado!)}'
                      : null,
                ),
              ),
              Expanded(
                child: _cargando
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Text(
                              _error!,
                              style: AppTypography.bodyMedium
                                  .copyWith(color: AppColors.error),
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
                            : RefreshIndicator(
                                onRefresh: _cargar,
                                child: ListView.separated(
                                  padding: AppLayout.pantallaPadding,
                                  itemCount: _items.length,
                                  separatorBuilder: (_, __) => AppLayout.vS,
                                  itemBuilder: (_, i) {
                                    final m = _items[i];
                                    final esIngreso = m.tipo
                                        .toLowerCase()
                                        .contains('ingreso');
                                    return AppCard(
                                      borderColor: AppColors.border,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: mobile ? 14 : 18,
                                        vertical: mobile ? 12 : 14,
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
                                            size: mobile ? 22 : 24,
                                          ),
                                          AppLayout.hM,
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${m.tipo.toUpperCase()} · ${m.formaPago}',
                                                  style: AppTypography
                                                      .labelMedium
                                                      .copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  '${m.referenciaTipo} #${m.referenciaId} · ${_fmt.format(m.fecha)}',
                                                  style: AppTypography.bodySmall
                                                      .copyWith(
                                                    color: AppColors
                                                        .textSecondary,
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
                                                style: AppTypography.bodyMedium
                                                    .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: esIngreso
                                                      ? AppColors.success
                                                      : AppColors.error,
                                                ),
                                              ),
                                              Text(
                                                'Saldo ${_fmtMonto.format(m.saldoNuevo)}',
                                                style: AppTypography.bodySmall
                                                    .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
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
            ],
          ),
        ),
      ),
    );
  }
}
