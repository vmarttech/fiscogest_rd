import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/listas_ventas_providers.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/core/navigation/safe_back.dart';

class CotizacionesHistorialPage extends ConsumerStatefulWidget {
  const CotizacionesHistorialPage({super.key});
  static const String routeName = 'historial-cotizaciones';

  @override
  ConsumerState<CotizacionesHistorialPage> createState() =>
      _CotizacionesHistorialPageState();
}

class _CotizacionesHistorialPageState
    extends ConsumerState<CotizacionesHistorialPage> {
  String _etiquetaEstado(EstadoDocumento estado) => switch (estado) {
    EstadoDocumento.borrador => 'Borrador',
    EstadoDocumento.cotizado => 'Vigente',
    EstadoDocumento.enCredito => 'En aprobación',
    EstadoDocumento.aprobado => 'Aprobado',
    EstadoDocumento.anulado => 'Rechazado',
    EstadoDocumento.facturado => 'Facturada',
  };

  Color _colorEstado(EstadoDocumento estado) => switch (estado) {
    EstadoDocumento.borrador => AppColors.textSecondary,
    EstadoDocumento.cotizado => Theme.of(context).colorScheme.primary,
    EstadoDocumento.enCredito => const Color(0xFFE65100),
    EstadoDocumento.aprobado => AppColors.success,
    EstadoDocumento.anulado => AppColors.error,
    EstadoDocumento.facturado => AppColors.success,
  };

  Color _colorFondoEstado(EstadoDocumento estado) => switch (estado) {
    EstadoDocumento.borrador => AppColors.textSecondary.withValues(alpha: 0.12),
    EstadoDocumento.cotizado => Theme.of(
      context,
    ).colorScheme.primary.withValues(alpha: 0.12),
    EstadoDocumento.enCredito => const Color(
      0xFFE65100,
    ).withValues(alpha: 0.12),
    EstadoDocumento.aprobado => AppColors.success.withValues(alpha: 0.12),
    EstadoDocumento.anulado => AppColors.error.withValues(alpha: 0.12),
    EstadoDocumento.facturado => AppColors.success.withValues(alpha: 0.12),
  };

  @override
  Widget build(BuildContext context) {
    final cotizacionesAsync = ref.watch(listaCotizacionesProvider);
    final esPantallaPequena = MediaQuery.of(context).size.width < 600;
    final padding = esPantallaPequena ? 12.0 : 16.0;

    return AppScaffold(
      title: 'HISTORIAL DE COTIZACIONES',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Atrás',
        onPressed: () => safeBack(context, fallback: '/ventas'),
      ),
      body: SafeArea(
        bottom: true,
        maintainBottomViewPadding: true,
        child: cotizacionesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(
                    'Error al cargar cotizaciones:\n$e',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          data: (lista) {
            if (lista.isEmpty) {
              return Center(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: esPantallaPequena ? 48 : 56,
                        color: AppColors.grey300,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'No hay cotizaciones',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Cree una desde "Nueva Cotización"',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: esPantallaPequena ? 13 : 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('NUEVA COTIZACIÓN'),
                        onPressed: () =>
                            context.push('/ventas/cotizaciones/nueva'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              color: Theme.of(context).colorScheme.primary,
              onRefresh: () async {
                ref.invalidate(listaCotizacionesProvider);
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columnas = constraints.maxWidth >= 900 ? 2 : 1;
                  return GridView.builder(
                    padding: EdgeInsets.fromLTRB(
                      padding,
                      padding,
                      padding,
                      padding + 32,
                    ),
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columnas,
                      crossAxisSpacing: columnas == 2 ? 16 : 0,
                      mainAxisSpacing: esPantallaPequena ? 10 : 14,
                      mainAxisExtent: esPantallaPequena ? 174 : 178,
                    ),
                    itemCount: lista.length,
                    itemBuilder: (context, i) => _buildTarjetaCotizacion(
                      lista[i],
                      esPantallaPequena,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTarjetaCotizacion(Venta cot, bool esPantallaPequena) {
    final numero = cot.numeroCotizacion;
    final estado = cot.estadoDocumento;
    final esCotizacionActiva =
        estado != EstadoDocumento.facturado && estado != EstadoDocumento.anulado;
    final tamanoEtiqueta = esPantallaPequena ? 11.0 : 12.0;
    final tamanoTotal = esPantallaPequena ? 16.0 : 18.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'N° $numero',
                    style: AppTypography.h4.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: esPantallaPequena ? 15 : 16,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _colorFondoEstado(estado),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _etiquetaEstado(estado),
                    style: AppTypography.labelSmall.copyWith(
                      color: _colorEstado(estado),
                      fontWeight: FontWeight.w600,
                      fontSize: tamanoEtiqueta,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    cot.nombreCliente ?? 'Consumidor Final',
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: esPantallaPequena ? 13 : 14,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.grey600),
                const SizedBox(width: 6),
                Text(
                  '${cot.fecha.day.toString().padLeft(2, '0')}/'
                  '${cot.fecha.month.toString().padLeft(2, '0')}/'
                  '${cot.fecha.year}',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: tamanoEtiqueta,
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    formatRd(cot.montoTotal),
                    style: AppTypography.h4.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: tamanoTotal,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                if (esCotizacionActiva)
                  _iconoAccion(
                    icon: Icons.print_outlined,
                    label: 'Imprimir',
                    onTap: () => _imprimirCotizacion(numero),
                  ),
                _iconoAccion(
                  icon: Icons.email_outlined,
                  label: 'Enviar por correo',
                  onTap: () => _enviarPorCorreo(numero),
                ),
                if (estado == EstadoDocumento.aprobado || estado == EstadoDocumento.cotizado)
                  _iconoAccion(
                    icon: Icons.shopping_cart_checkout,
                    label: 'Convertir en venta',
                    onTap: () => _convertirEnVenta(numero),
                    destacado: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconoAccion({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool destacado = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Material(
        color: destacado ? AppColors.success.withValues(alpha: 0.12) : AppColors.grey50,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Tooltip(
            message: label,
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Icon(
                icon,
                size: 18,
                color: destacado ? AppColors.success : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _imprimirCotizacion(String numero) {
    FiscoGestNotifications.show(
      SnackBar(
        content: Text('Imprimiendo cotización N° $numero...'),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _enviarPorCorreo(String numero) {
    FiscoGestNotifications.show(
      SnackBar(
        content: Text('Enviando $numero por correo...'),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _convertirEnVenta(String numero) async {
    final tipo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Convertir a Venta', style: AppTypography.h4),
        content: Text(
          '¿Cómo deseas convertir la cotización N° $numero?\n\n'
          'Se descontará inventario y generará el documento.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            style: TextButton.styleFrom(foregroundColor: AppColors.grey600),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'credito'),
            child: const Text('A Crédito'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'contado'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
            ),
            child: const Text('De Contado'),
          ),
        ],
      ),
    );

    if (tipo == null) return;
    if (!mounted) return;

    final msg = tipo == 'contado'
        ? '$numero convertida en Venta de Contado.'
        : '$numero enviada a Crédito.';

    FiscoGestNotifications.show(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    ref.invalidate(listaCotizacionesProvider);
  }
}
