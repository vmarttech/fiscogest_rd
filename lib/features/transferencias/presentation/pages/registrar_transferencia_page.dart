import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/navigation/safe_back.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/features/almacenes/presentation/providers/almacen_providers.dart';
import 'package:fiscogest_rd/features/almacenes/presentation/widgets/plan_requerido.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/transferencias/presentation/providers/transferencia_form_provider.dart';
import 'package:fiscogest_rd/features/transferencias/presentation/widgets/selector_almacen_widget.dart';

class RegistrarTransferenciaPage extends ConsumerStatefulWidget {
  const RegistrarTransferenciaPage({super.key});

  static const String routeName = 'registrar-transferencia';

  @override
  ConsumerState<RegistrarTransferenciaPage> createState() =>
      _RegistrarTransferenciaPageState();
}

class _RegistrarTransferenciaPageState
    extends ConsumerState<RegistrarTransferenciaPage> {
  final _cantCtrl = TextEditingController();
  final _notaCtrl = TextEditingController();
  final _prodBusca = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(productoControllerProvider.notifier).cargarProductos();
    });
  }

  @override
  void dispose() {
    _cantCtrl.dispose();
    _notaCtrl.dispose();
    _prodBusca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(almacenesHabilitadosProvider)) {
      return const PlanRequeridoAlmacenes(titulo: 'Transferencias');
    }
    final form = ref.watch(transferenciaFormProvider);
    final historial = ref.watch(transferenciasHistorialProvider);
    final stockOrigen = ref.watch(stockOrigenProvider);
    final productos =
        ref.watch(productoControllerProvider).valueOrNull ?? <Producto>[];
    final q = _prodBusca.text.trim().toLowerCase();
    final filtrados = productos.where((p) {
      if (q.isEmpty) return true;
      return p.nombre.toLowerCase().contains(q) ||
          p.codigo.toLowerCase().contains(q);
    }).take(80).toList();
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    return AppScaffold(
      title: 'Transferencias',
      subtitle: 'Mover mercancía entre almacenes',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => safeBack(context, fallback: '/'),
        style: IconButton.styleFrom(foregroundColor: Colors.white),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SelectorAlmacenWidget(
                  label: 'Almacén origen',
                  initialValue: form.almacenOrigen,
                  excludeId: form.almacenDestino,
                  onChanged: (v) => ref
                      .read(transferenciaFormProvider.notifier)
                      .seleccionarAlmacenOrigen(v),
                ),
                const SizedBox(height: 12),
                SelectorAlmacenWidget(
                  label: 'Almacén destino',
                  initialValue: form.almacenDestino,
                  excludeId: form.almacenOrigen,
                  onChanged: (v) => ref
                      .read(transferenciaFormProvider.notifier)
                      .seleccionarAlmacenDestino(v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _prodBusca,
                  decoration: const InputDecoration(
                    labelText: 'Buscar producto',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Producto',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      hint: const Text('Seleccione producto'),
                      value: filtrados.any((p) => p.id == form.productoId)
                          ? form.productoId
                          : null,
                      items: [
                        for (final p in filtrados)
                          if (p.id != null)
                            DropdownMenuItem(
                              value: p.id,
                              child: Text('${p.codigo} — ${p.nombre}'),
                            ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          ref
                              .read(transferenciaFormProvider.notifier)
                              .seleccionarProducto(v);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                stockOrigen.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (s) => Text(
                    'Stock en origen: ${s.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: s > 0 ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _cantCtrl,
                  label: 'Cantidad',
                  hint: '0.00',
                  onChanged: (v) => ref
                      .read(transferenciaFormProvider.notifier)
                      .asignarCantidad(v),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _notaCtrl,
                  label: 'Nota (opcional)',
                  onChanged: (v) => ref
                      .read(transferenciaFormProvider.notifier)
                      .asignarNota(v),
                ),
                if (form.error != null) ...[
                  const SizedBox(height: 8),
                  Text(form.error!, style: const TextStyle(color: AppColors.error)),
                ],
                const SizedBox(height: 16),
                AppButton(
                  text: form.enviando ? 'Procesando…' : 'Procesar transferencia',
                  onPressed: form.esValido
                      ? () async {
                          final ok = await ref
                              .read(transferenciaFormProvider.notifier)
                              .enviar();
                          if (ok && mounted) {
                            _cantCtrl.clear();
                            _notaCtrl.clear();
                            FiscoGestNotifications.show(
                              const SnackBar(
                                content: Text('Transferencia registrada'),
                              ),
                            );
                          }
                        }
                      : null,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Historial reciente',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 8),
                historial.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error historial: $e'),
                  data: (rows) {
                    if (rows.isEmpty) {
                      return const Text('Aún no hay transferencias.');
                    }
                    return Column(
                      children: [
                        for (final t in rows)
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.swap_horiz),
                              title: Text(
                                '${t.productoCodigo ?? ''} ${t.productoNombre ?? 'Producto ${t.productoId}'}',
                              ),
                              subtitle: Text(
                                '${t.origenNombre ?? t.almacenOrigenId} → ${t.destinoNombre ?? t.almacenDestinoId}\n'
                                '${t.cantidad} · ${fmt.format(t.fecha)}'
                                '${t.nota == null ? '' : ' · ${t.nota}'}',
                              ),
                              isThreeLine: true,
                            ),
                          ),
                      ],
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
