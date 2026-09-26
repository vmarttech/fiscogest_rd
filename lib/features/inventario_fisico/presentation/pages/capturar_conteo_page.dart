import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/diferencia_conteo.dart';
import 'package:fiscogest_rd/features/inventario_fisico/presentation/providers/inventario_fisico_provider.dart';

class CapturarConteoPage extends ConsumerStatefulWidget {
  const CapturarConteoPage({super.key, required this.conteoId});

  static const String routeName = 'capturar-conteo-fisico';

  final int conteoId;

  @override
  ConsumerState<CapturarConteoPage> createState() => _CapturarConteoPageState();
}

class _CapturarConteoPageState extends ConsumerState<CapturarConteoPage> {
  final _busquedaCtrl = TextEditingController();
  final _fisicoCtrl = TextEditingController();
  Producto? _seleccionado;
  bool _guardando = false;
  String _filtro = '';

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    _fisicoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardarLinea() async {
    final p = _seleccionado;
    if (p == null || p.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un producto')),
      );
      return;
    }
    final fisico = double.tryParse(_fisicoCtrl.text.replaceAll(',', '.'));
    if (fisico == null || fisico < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cantidad física inválida')),
      );
      return;
    }

    final sistema = p.stock ?? 0.0;
    final dif = fisico - sistema;

    setState(() => _guardando = true);
    try {
      await ref.read(guardarDiferenciaProvider).call(
            DiferenciaConteo(
              id: 0,
              conteoId: widget.conteoId,
              productoId: p.id!,
              codigoProducto: p.codigo,
              nombreProducto: p.nombre,
              stockSistema: sistema,
              stockFisico: fisico,
              diferencia: dif,
              motivo: null,
              estado: 'pendiente',
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Guardado: ${p.nombre} · Dif: ${dif.toStringAsFixed(2)}',
          ),
        ),
      );
      setState(() {
        _seleccionado = null;
        _fisicoCtrl.clear();
        _busquedaCtrl.clear();
        _filtro = '';
      });
      ref.invalidate(listaConteosProvider);
      ref.invalidate(diferenciasConteoProvider(widget.conteoId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final productosAsync = ref.watch(productoControllerProvider);
    final difsAsync = ref.watch(diferenciasConteoProvider(widget.conteoId));

    return AppScaffold(
      title: 'Capturar conteo #${widget.conteoId}',
      subtitle: isMobile ? null : 'Registre cantidades físicas por producto',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            onPressed: () => context.push(
              '/diferencias-conteo-fisico/${widget.conteoId}',
            ),
            icon: const Icon(Icons.difference_outlined, color: Colors.white),
            label: const Text(
              'Ver diferencias',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                isMobile ? 16 : 24,
                isMobile ? 16 : 24,
                32,
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.grey900.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Producto',
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _busquedaCtrl,
                        hint: 'Buscar por código o nombre...',
                        prefixIcon: Icons.search,
                        onChanged: (v) =>
                            setState(() => _filtro = v.trim().toLowerCase()),
                      ),
                      const SizedBox(height: 12),
                      productosAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('Error productos: $e'),
                        data: (lista) {
                          final filtrados = _filtro.isEmpty
                              ? lista.take(8).toList()
                              : lista
                                  .where(
                                    (p) =>
                                        p.codigo.toLowerCase().contains(_filtro) ||
                                        p.nombre.toLowerCase().contains(_filtro),
                                  )
                                  .take(12)
                                  .toList();
                          if (filtrados.isEmpty) {
                            return Text(
                              'Sin resultados',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            );
                          }
                          return Column(
                            children: filtrados.map((p) {
                              final sel = _seleccionado?.id == p.id;
                              return Material(
                              color: sel
                                  ? AppColors.primary.withValues(alpha: 0.08)
                                  : AppColors.white,
                              child: ListTile(
                                dense: true,
                                selected: sel,
                                title: Text(p.nombre),
                                subtitle: Text(
                                  '${p.codigo} · Stock sistema: ${p.stock ?? 0}',
                                ),
                                onTap: () {
                                  setState(() {
                                    _seleccionado = p;
                                    _fisicoCtrl.text =
                                        (p.stock ?? 0).toString();
                                  });
                                },
                              ),
                            );
                            }).toList(),
                          );
                        },
                      ),
                      if (_seleccionado != null) ...[
                        const Divider(height: 28),
                        Text(
                          _seleccionado!.nombre,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Sistema: ${(_seleccionado!.stock ?? 0).toStringAsFixed(2)}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _fisicoCtrl,
                          label: 'Cantidad física',
                          hint: '0',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Align(
                          alignment: isMobile
                              ? Alignment.center
                              : Alignment.centerRight,
                          child: SizedBox(
                            width: isMobile ? double.infinity : 200,
                            child: AppButton(
                              text: 'Guardar línea',
                              onPressed: _guardando ? null : _guardarLinea,
                              isLoading: _guardando,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Líneas registradas',
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                difsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => Text('Error: $e'),
                  data: (difs) {
                    if (difs.isEmpty) {
                      return Text(
                        'Aún no hay líneas en este conteo.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      );
                    }
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: difs.map((d) {
                          return ListTile(
                            title: Text(d.nombreProducto),
                            subtitle: Text(
                              'Sis: ${d.stockSistema.toStringAsFixed(2)} · '
                              'Fís: ${d.stockFisico.toStringAsFixed(2)}',
                            ),
                            trailing: Text(
                              d.diferencia.toStringAsFixed(2),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: d.diferencia == 0
                                    ? AppColors.textSecondary
                                    : (d.diferencia > 0
                                        ? AppColors.success
                                        : AppColors.error),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
