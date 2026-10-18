import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/facturacion/presentation/providers/facturacion_providers.dart';

/// Configuración de rangos NCF B01 (crédito fiscal) y B02 (consumidor final).
class SecuenciasNcfPage extends ConsumerWidget {
  const SecuenciasNcfPage({super.key});

  static const path = '/sales/secuencias-ncf';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(secuenciasNcfListProvider);

    final desktop = AppBreakpoints.isDesktop(context);
    return AppScaffold(
      title: 'SECUENCIAS NCF',
      showAppBar: !desktop,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/sales');
          }
        },
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (filas) {
            return ListView(
              padding: AppLayout.pantallaPadding,
              children: [
                AppLayout.centerConstrained(
                  maxWidth: 1200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const EnterprisePageHeader(
                        title: 'Secuencias NCF',
                        subtitle:
                            'B01 crédito fiscal · B02 consumidor final · prefijo + 8 dígitos',
                        showBack: true,
                        backFallbackRoute: '/sales',
                      ),
                      if (!desktop) ...[
                        Text(
                          'Rangos autorizados DGII',
                          style: AppTypography.h4.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        AppLayout.vXs,
                        Text(
                          'B01 = Crédito fiscal (cliente con RNC). '
                          'B02 = Consumidor final. '
                          'El NCF se forma: prefijo + 8 dígitos (ej. B0100000001).',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        AppLayout.vL,
                      ],
                      LayoutBuilder(
                        builder: (context, c) {
                          final w = c.maxWidth;
                          final cols = w > 900 ? 3 : (w > 560 ? 2 : 1);
                          const gap = 14.0;
                          final tileW = (w - gap * (cols - 1)) / cols;
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              for (final f in filas)
                                SizedBox(
                                  width: tileW,
                                  child: _TarjetaSecuencia(
                                    tipo: f.tipo,
                                    prefijo: f.prefijo,
                                    actual: f.secuenciaActual,
                                    desde: f.secuenciaDesde,
                                    hasta: f.secuenciaHasta,
                                    activo: f.activo,
                                    onGuardar: (p) async {
                                      final dao = ref.read(
                                        secuenciasNcfDaoProvider,
                                      );
                                      await dao.guardar(
                                        tipo: f.tipo,
                                        prefijo: p.prefijo,
                                        secuenciaActual: p.actual,
                                        secuenciaDesde: p.desde,
                                        secuenciaHasta: p.hasta,
                                        activo: p.activo,
                                      );
                                      ref.invalidate(secuenciasNcfListProvider);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('${f.tipo} guardado'),
                                            backgroundColor: AppColors.success,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
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

class _Params {
  _Params({
    required this.prefijo,
    required this.actual,
    required this.desde,
    required this.hasta,
    required this.activo,
  });
  final String prefijo;
  final int actual;
  final int desde;
  final int hasta;
  final bool activo;
}

class _TarjetaSecuencia extends StatefulWidget {
  const _TarjetaSecuencia({
    required this.tipo,
    required this.prefijo,
    required this.actual,
    required this.desde,
    required this.hasta,
    required this.activo,
    required this.onGuardar,
  });

  final String tipo;
  final String prefijo;
  final int actual;
  final int desde;
  final int hasta;
  final bool activo;
  final Future<void> Function(_Params) onGuardar;

  @override
  State<_TarjetaSecuencia> createState() => _TarjetaSecuenciaState();
}

class _TarjetaSecuenciaState extends State<_TarjetaSecuencia> {
  late final TextEditingController _prefijo;
  late final TextEditingController _actual;
  late final TextEditingController _desde;
  late final TextEditingController _hasta;
  late bool _activo;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _prefijo = TextEditingController(text: widget.prefijo);
    _actual = TextEditingController(text: '${widget.actual}');
    _desde = TextEditingController(text: '${widget.desde}');
    _hasta = TextEditingController(text: '${widget.hasta}');
    _activo = widget.activo;
  }

  @override
  void dispose() {
    _prefijo.dispose();
    _actual.dispose();
    _desde.dispose();
    _hasta.dispose();
    super.dispose();
  }

  String get _preview {
    final n = int.tryParse(_actual.text) ?? 0;
    final sig = n + 1;
    final p = _prefijo.text.trim().isEmpty ? widget.tipo : _prefijo.text.trim();
    return '$p${sig.toString().padLeft(8, '0')}';
  }

  String get _etiquetaTipo {
    return switch (widget.tipo) {
      'B01' => 'B01 — Crédito fiscal',
      'B02' => 'B02 — Consumidor final',
      'B04' => 'B04 — Nota de crédito',
      'B11' => 'B11 — Compras',
      'B13' => 'B13 — Gastos menores',
      'B14' => 'B14 — Regímenes especiales',
      _ => widget.tipo,
    };
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await widget.onGuardar(
        _Params(
          prefijo: _prefijo.text.trim().isEmpty
              ? widget.tipo
              : _prefijo.text.trim(),
          actual: int.tryParse(_actual.text) ?? 0,
          desde: int.tryParse(_desde.text) ?? 1,
          hasta: int.tryParse(_hasta.text) ?? 99999999,
          activo: _activo,
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _etiquetaTipo,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Switch.adaptive(
                value: _activo,
                onChanged: (v) => setState(() => _activo = v),
              ),
              Text(
                _activo ? 'Activo' : 'Inactivo',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
          AppLayout.vS,
          Text(
            'Próximo NCF: $_preview',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          AppLayout.vM,
          AppTextField(
            label: 'Prefijo',
            controller: _prefijo,
            onChanged: (_) => setState(() {}),
          ),
          AppLayout.vS,
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Secuencia actual',
                  controller: _actual,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                ),
              ),
              AppLayout.hS,
              Expanded(
                child: AppTextField(
                  label: 'Desde',
                  controller: _desde,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              AppLayout.hS,
              Expanded(
                child: AppTextField(
                  label: 'Hasta',
                  controller: _hasta,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
          AppLayout.vM,
          AppButton(
            text: _guardando ? 'Guardando…' : 'Guardar ${widget.tipo}',
            onPressed: _guardando ? null : _guardar,
          ),
        ],
      ),
    );
  }
}
