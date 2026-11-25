
// [ADMIN_FASE2]
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/features/admin_negocios/data/admin_negocios_remote.dart';
import 'package:fiscogest_rd/features/admin_negocios/presentation/providers/admin_negocios_providers.dart';

class AdminNegocioDetallePage extends ConsumerStatefulWidget {
  const AdminNegocioDetallePage({super.key, required this.negocioId});
  final String negocioId;
  static const routeName = 'admin-negocio-detalle';
  @override
  ConsumerState<AdminNegocioDetallePage> createState() => _DetalleState();
}

class _DetalleState extends ConsumerState<AdminNegocioDetallePage> {
  Future<void> _accion(Future<void> Function() accion, String ok) async {
    try {
      await accion();
      ref.read(adminNegociosTickProvider.notifier).state++;
      ref.invalidate(adminNegocioDetalleProvider(widget.negocioId));
      if (mounted) {
        FiscoGestNotifications.show(SnackBar(content: Text(ok)));
      }
    } catch (e) {
      if (mounted) {
        FiscoGestNotifications.show(SnackBar(
            content: Text('$e'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<bool> _confirmar(String titulo, String mensaje) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar')),
        ],
      ),
    );
    return r ?? false;
  }

  Future<String?> _dialogoMotivo(String titulo, String accion) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Motivo obligatorio'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) Navigator.pop(ctx, ctrl.text.trim());
              },
              child: Text(accion)),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _dialogoRenovar(AdminNegocioDetalle d) async {
    DateTime? fecha = d.fechaFin;
    final planCtrl = TextEditingController(text: d.plan);
    final vigCtrl = TextEditingController(text: d.vigenciaTipo);
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renovar licencia'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          StatefulBuilder(
            builder: (sctx, setS) => ListTile(
              leading: const Icon(Icons.calendar_month),
              title: Text(fecha == null
                  ? 'Elegir nueva fecha de fin'
                  : 'Vence: ${_fechaTxt(fecha)}'),
              onTap: () async {
                final f = await showDatePicker(
                  context: ctx,
                  initialDate: fecha ?? DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 1825)),
                );
                if (f != null) setS(() => fecha = f);
              },
            ),
          ),
          TextField(
              controller: planCtrl,
              decoration: const InputDecoration(labelText: 'Plan (opcional)')),
          TextField(
              controller: vigCtrl,
              decoration: const InputDecoration(
                  labelText: 'Vigencia: mensual / semestral / anual')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
              onPressed: () {
                if (fecha == null) return;
                Navigator.pop(ctx, {
                  'fecha': fecha,
                  'plan': planCtrl.text.trim().isEmpty ? null : planCtrl.text.trim(),
                  'vigencia':
                      vigCtrl.text.trim().isEmpty ? null : vigCtrl.text.trim(),
                });
              },
              child: const Text('Renovar')),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _dialogoConcesion(AdminNegocioDetalle d) async {
    String tipo = 'trial_30d';
    final DateTime inicio = DateTime.now();
    DateTime fin = DateTime.now().add(const Duration(days: 30));
    final motivoCtrl = TextEditingController();
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar beneficio / promoción'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            initialValue: tipo,
            items: const [
              DropdownMenuItem(value: 'trial_30d', child: Text('Prueba 30 días')),
              DropdownMenuItem(
                  value: 'free_six_months', child: Text('6 meses gratis')),
              DropdownMenuItem(value: 'otro', child: Text('Otro')),
            ],
            onChanged: (v) => tipo = v ?? tipo,
          ),
          StatefulBuilder(
            builder: (sctx, setS) => ListTile(
              leading: const Icon(Icons.date_range_outlined),
              title: Text('${_fechaTxt(inicio)} → ${_fechaTxt(fin)}'),
              onTap: () async {
                final f = await showDatePicker(
                  context: ctx,
                  initialDate: fin,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (f != null) setS(() => fin = f);
              },
            ),
          ),
          TextField(
              controller: motivoCtrl,
              decoration: const InputDecoration(labelText: 'Motivo / nota')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, {
                    'tipo': tipo,
                    'inicio': inicio,
                    'fin': fin,
                    'motivo': motivoCtrl.text.trim().isEmpty
                        ? null
                        : motivoCtrl.text.trim(),
                  }),
              child: const Text('Registrar')),
        ],
      ),
    );
  }

  Future<Map<String, String>?> _dialogoContacto(AdminNegocioDetalle d) async {
    final telCtrl = TextEditingController(text: d.telefono);
    final corrCtrl = TextEditingController(text: d.correo);
    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar contacto'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: telCtrl,
              decoration: const InputDecoration(labelText: 'Teléfono')),
          TextField(
              controller: corrCtrl,
              decoration: const InputDecoration(labelText: 'Correo')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, {
                    'telefono': telCtrl.text.trim(),
                    'correo': corrCtrl.text.trim(),
                  }),
              child: const Text('Guardar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminNegocioDetalleProvider(widget.negocioId));
    return AppScaffold(
      title: 'Detalle del negocio',
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$e', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  ref.read(adminNegociosTickProvider.notifier).state++,
              child: const Text('Reintentar'),
            ),
          ]),
        ),
        data: (d) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _cabecera(d),
            _acciones(d),
            _seccion('Contacto', [
              _fila('Teléfono', d.telefono.isEmpty ? '—' : d.telefono),
              _fila('Correo', d.correo.isEmpty ? '—' : d.correo),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar contacto'),
                  onPressed: () async {
                    if (await _dialogoContacto(d) case final c?) {
                      await _accion(
                          () => ref
                              .read(adminNegociosRemoteProvider)
                              .actualizarContacto(d.id,
                                  telefono: c['telefono'], correo: c['correo']),
                          'Contacto actualizado');
                    }
                  },
                ),
              ),
            ]),
            _seccion('Usuarios (${d.usuarios.length})',
                d.usuarios.isEmpty ? [const Text('Sin usuarios registrados.')] : [
                  ...d.usuarios.map((u) => ListTile(
                        dense: true,
                        leading: Icon(
                            u.activo
                                ? Icons.check_circle_outline
                                : Icons.remove_circle_outline,
                            color: u.activo
                                ? const Color(0xFF059669)
                                : Colors.grey),
                        title: Text(u.username),
                        subtitle: Text('${u.nombre} · ${u.rol}'),
                      )),
                ]),
            _seccion('Beneficios / promociones (${d.concesiones.length})',
                d.concesiones.isEmpty
                    ? [const Text('Beneficio no determinado.')]
                    : [
                        ...d.concesiones.map((c) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.card_giftcard_outlined),
                              title: Text(c.tipo),
                              subtitle: Text(
                                  '${_fechaTxt(c.fechaInicio)} → ${_fechaTxt(c.fechaFin)} · ${c.origen}${c.motivo.isEmpty ? '' : ' · ${c.motivo}'}'),
                            )),
                      ]),
            _seccion('Bitácora reciente (${d.bitacora.length})',
                d.bitacora.isEmpty
                    ? [const Text('Sin acciones registradas.')]
                    : [
                        ...d.bitacora.map((b) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.history),
                              title: Text(b.accion),
                              subtitle: Text(
                                  '${_fechaTxt(b.createdAt)}${b.motivo.isEmpty ? '' : ' · ${b.motivo}'}'),
                            )),
                      ]),
          ],
        ),
      ),
    );
  }

  Widget _cabecera(AdminNegocioDetalle d) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(d.nombre,
                      style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w900, fontSize: 18)),
                ),
                _chipEstado(d.estadoDerivado),
              ]),
              const SizedBox(height: 8),
              _fila('RNC', d.rnc),
              _fila('Plan', d.plan),
              _fila('Vigencia', d.vigenciaTipo),
              _fila('Inicio', _fechaTxt(d.fechaInicio)),
              _fila('Fin', _fechaTxt(d.fechaFin)),
              if (d.vitalicia)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('Licencia vitalicia',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, color: Color(0xFF059669))),
                ),
            ],
          ),
        ),
      );

  Widget _acciones(AdminNegocioDetalle d) {
    final suspendida = d.estadoDerivado == 'suspendida';
    return _seccion('Acciones administrativas', [
      Wrap(spacing: 8, runSpacing: 8, children: [
        FilledButton.icon(
          icon: const Icon(Icons.play_arrow),
          label: const Text('Activar'),
          onPressed: suspendida
              ? () async {
                  if (await _confirmar('Activar negocio',
                      '¿Reactivar este negocio y quitar la suspensión?')) {
                    await _accion(() => ref
                        .read(adminNegociosRemoteProvider)
                        .activar(d.id), 'Negocio activado');
                  }
                }
              : null,
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.block),
          label: const Text('Suspender'),
          onPressed: suspendida
              ? null
              : () async {
                  final motivo = await _dialogoMotivo('Suspender negocio', 'Suspender');
                  if (motivo == null) return;
                  await _accion(() => ref
                      .read(adminNegociosRemoteProvider)
                      .suspender(d.id, motivo), 'Negocio suspendido');
                },
        ),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.event_repeat_outlined),
          label: const Text('Renovar'),
          onPressed: suspendida
              ? null
              : () async {
                  final r = await _dialogoRenovar(d);
                  if (r == null) return;
                  await _accion(
                      () => ref.read(adminNegociosRemoteProvider).renovar(
                            d.id,
                            r['fecha'] as DateTime,
                            plan: r['plan'] as String?,
                            vigenciaTipo: r['vigencia'] as String?,
                          ),
                      'Licencia renovada');
                },
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.card_giftcard_outlined),
          label: const Text('Beneficio'),
          onPressed: () async {
            final r = await _dialogoConcesion(d);
            if (r == null) return;
            await _accion(
                () => ref.read(adminNegociosRemoteProvider).registrarConcesion(
                      id: d.id,
                      tipo: r['tipo'] as String,
                      inicio: r['inicio'] as DateTime,
                      fin: r['fin'] as DateTime,
                      motivo: r['motivo'] as String?,
                    ),
                'Beneficio registrado');
          },
        ),
      ]),
    ]);
  }

  Widget _seccion(String titulo, List<Widget> hijos) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  style:
                      AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              ...hijos,
            ],
          ),
        ),
      );

  Widget _fila(String etiqueta, String valor) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          SizedBox(
              width: 96,
              child: Text(etiqueta,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary))),
          Expanded(child: Text(valor, style: AppTypography.bodyMedium)),
        ]),
      );

  Widget _chipEstado(String e) {
    Color color;
    switch (e) {
      case 'activa':
        color = const Color(0xFF059669);
        break;
      case 'prueba':
        color = const Color(0xFF2563EB);
        break;
      case 'gracia':
        color = const Color(0xFFD97706);
        break;
      case 'vencida':
        color = const Color(0xFFDC2626);
        break;
      case 'suspendida':
        color = const Color(0xFF6B7280);
        break;
      default:
        color = const Color(0xFF64748B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(99)),
      child: Text(e,
          style:
              TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

String _fechaTxt(DateTime? d) => d == null
    ? '—'
    : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
