import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/listas_ventas_providers.dart';

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
        EstadoDocumento.cotizado => AppColors.primary,
        EstadoDocumento.enCredito => const Color(0xFFE65100),
        EstadoDocumento.aprobado => AppColors.success,
        EstadoDocumento.anulado => AppColors.error,
        EstadoDocumento.facturado => AppColors.success,
      };

  Color _colorFondoEstado(EstadoDocumento estado) => switch (estado) {
        EstadoDocumento.borrador =>
          AppColors.textSecondary.withValues(alpha: 0.12),
        EstadoDocumento.cotizado => AppColors.primary.withValues(alpha: 0.12),
        EstadoDocumento.enCredito =>
          const Color(0xFFE65100).withValues(alpha: 0.12),
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
        onPressed: () => context.pop(),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton.icon(
            icon: const Icon(Icons.add, size: 20),
            label: Text(
              esPantallaPequena ? 'Nueva' : 'Nueva Cotización',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            onPressed: () => context.push('/ventas/cotizaciones/nueva'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ),
      ],
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
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(
                    'Error al cargar cotizaciones:\n$e',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.error),
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
                          backgroundColor: AppColors.primary,
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
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(listaCotizacionesProvider);
              },
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  padding,
                  padding,
                  padding,
                  padding + 32,
                ),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: lista.length,
                itemBuilder: (context, i) {
                  final cot = lista[i];
                  return _buildTarjetaCotizacion(cot, esPantallaPequena);
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
    final esCotizacionActiva = estado != EstadoDocumento.facturado && estado != EstadoDocumento.anulado;
    final tamanoCuerpo = esPantallaPequena ? 13.0 : 14.0;
    final tamanoTotal = esPantallaPequena ? 16.0 : 18.0;
    final tamanoEtiqueta = esPantallaPequena ? 11.0 : 12.0;

    return Padding(
      padding: EdgeInsets.only(bottom: esPantallaPequena ? 10 : 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: N° + badge estado + fecha
            Padding(
              padding: EdgeInsets.fromLTRB(
                esPantallaPequena ? 12 : 14,
                esPantallaPequena ? 12 : 14,
                esPantallaPequena ? 12 : 14,
                8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'N° $numero',
                          style: AppTypography.h4.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: esPantallaPequena ? 15 : 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
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
                  Text(
                    '${cot.fecha.day.toString().padLeft(2, '0')}/'
                    '${cot.fecha.month.toString().padLeft(2, '0')}/'
                    '${cot.fecha.year}',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: tamanoEtiqueta,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Cliente + Total
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: esPantallaPequena ? 12 : 14,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      cot.nombreCliente ?? 'Consumidor Final',
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: tamanoCuerpo,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'RD\$ ${cot.montoTotal.toStringAsFixed(2)}',
                    style: AppTypography.h4.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: tamanoTotal,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),

            // Acciones
            Padding(
              padding: EdgeInsets.fromLTRB(
                esPantallaPequena ? 8 : 10,
                8,
                esPantallaPequena ? 8 : 10,
                esPantallaPequena ? 10 : 12,
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (esCotizacionActiva) _chipAccion(
                    icon: Icons.print_outlined,
                    label: 'Imprimir',
                    onTap: () => _imprimirCotizacion(numero),
                    esPantallaPequena: esPantallaPequena,
                  ),
                  _chipAccion(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'PDF',
                    onTap: () => _exportarPDF(numero),
                    esPantallaPequena: esPantallaPequena,
                  ),
                  _chipAccion(
                    icon: Icons.email_outlined,
                    label: 'Correo',
                    onTap: () => _enviarPorCorreo(numero),
                    esPantallaPequena: esPantallaPequena,
                  ),
                  if (estado == EstadoDocumento.aprobado ||
                      estado == EstadoDocumento.cotizado)
                    _chipAccion(
                      icon: Icons.shopping_cart_checkout,
                      label: 'Convertir',
                      onTap: () => _convertirEnVenta(numero),
                      esPantallaPequena: esPantallaPequena,
                      destacado: true,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipAccion({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool esPantallaPequena,
    bool destacado = false,
  }) {
    return Material(
      color: destacado
          ? AppColors.success.withValues(alpha: 0.12)
          : AppColors.grey50,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: esPantallaPequena ? 10 : 12,
            vertical: esPantallaPequena ? 8 : 9,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: destacado ? AppColors.success : AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: esPantallaPequena ? 12 : 13,
                  color: destacado ? AppColors.success : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _imprimirCotizacion(String numero) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Imprimiendo cotización N° $numero...'),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _exportarPDF(String numero) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generando PDF de $numero...'),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _enviarPorCorreo(String numero) {
    ScaffoldMessenger.of(context).showSnackBar(
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    ref.invalidate(listaCotizacionesProvider);
  }

}
