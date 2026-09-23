import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/cobro_venta_page.dart';

/// Hub de la estación de Caja (no es el POS del vendedor).
class CajaInicioPage extends ConsumerStatefulWidget {
  const CajaInicioPage({super.key});

  static const String routeName = 'caja-inicio';
  static const String path = '/ventas/cobro';

  @override
  ConsumerState<CajaInicioPage> createState() => _CajaInicioPageState();
}

class _CajaInicioPageState extends ConsumerState<CajaInicioPage> {
  double? _saldo;
  bool _cargandoSaldo = true;
  String? _errorSaldo;

  @override
  void initState() {
    super.initState();
    _cargarSaldo();
  }

  Future<void> _cargarSaldo() async {
    setState(() {
      _cargandoSaldo = true;
      _errorSaldo = null;
    });
    try {
      final saldo =
          await ref.read(cajaRepositoryProvider).obtenerSaldoActual();
      if (!mounted) return;
      setState(() {
        _saldo = saldo ?? 0.0;
        _cargandoSaldo = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorSaldo = '$e';
        _cargandoSaldo = false;
        _saldo = null;
      });
    }
  }

  void _irACobrarCotizacion() {
    context.push(CobroVentaPage.pathOperacion);
  }

  void _irACuentasPorCobrar() {
    context.push('/ventas/cobrar');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final padding = isMobile ? 16.0 : 24.0;
    final tamanoSaldo = isMobile ? 28.0 : 34.0;

    return AppScaffold(
      title: 'CAJA',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargarSaldo,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(padding, padding, padding, padding + 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Estado / saldo ───
                    Container(
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estación de caja',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: isMobile ? 12 : 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Saldo registrado',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: isMobile ? 14 : 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_cargandoSaldo)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              ),
                            )
                          else if (_errorSaldo != null)
                            Text(
                              'No se pudo leer el saldo',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
                            )
                          else
                            Text(
                              'RD\$ ${(_saldo ?? 0).toStringAsFixed(2)}',
                              style: AppTypography.h3.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: tamanoSaldo,
                                color: AppColors.primary,
                              ),
                            ),
                          const SizedBox(height: 10),
                          Text(
                            'Abrir / cerrar turno se agregará en una fase siguiente.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: isMobile ? 12 : 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isMobile ? 20 : 24),
                    Text(
                      'Operaciones',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: isMobile ? 13 : 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ─── Cobrar cotización ───
                    _AccionCaja(
                      icono: Icons.point_of_sale,
                      titulo: 'Cobrar cotización',
                      subtitulo:
                          'Buscar por N° o cliente y generar factura fiscal',
                      color: AppColors.success,
                      isMobile: isMobile,
                      onTap: _irACobrarCotizacion,
                    ),
                    const SizedBox(height: 10),
                    // ─── CXC (no es caja, pero acceso útil) ───
                    _AccionCaja(
                      icono: Icons.account_balance_wallet_outlined,
                      titulo: 'Cuentas por cobrar',
                      subtitulo: 'Saldos y abonos de clientes',
                      color: AppColors.info,
                      isMobile: isMobile,
                      onTap: _irACuentasPorCobrar,
                    ),
                    SizedBox(height: isMobile ? 28 : 32),
                    Text(
                      'El cobro de cotizaciones es la única vía que asigna '
                      'N° de factura e impacta inventario.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: isMobile ? 12 : 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccionCaja extends StatelessWidget {
  const _AccionCaja({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.isMobile,
    required this.onTap,
  });

  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Color color;
  final bool isMobile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 14 : 16,
            vertical: isMobile ? 14 : 16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: isMobile ? 44 : 48,
                height: isMobile ? 44 : 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icono, color: color, size: isMobile ? 22 : 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: isMobile ? 14 : 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: isMobile ? 12 : 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: isMobile ? 22 : 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
