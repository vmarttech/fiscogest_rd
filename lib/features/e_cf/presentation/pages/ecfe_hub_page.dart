import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/features/e_cf/domain/entities/ecfe_config.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/ambiente_dgii.dart';
import 'package:fiscogest_rd/features/e_cf/presentation/providers/ecfe_providers.dart';

/// Hub del módulo e-CF. No interviene en ventas ni caja.
class EcfeHubPage extends ConsumerStatefulWidget {
  const EcfeHubPage({super.key});
  static const routeName = 'ecfe-hub';

  @override
  ConsumerState<EcfeHubPage> createState() => _EcfeHubPageState();
}

class _EcfeHubPageState extends ConsumerState<EcfeHubPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    return AppScaffold(
      actions: [
        IconButton(
          tooltip: 'Especificación y checklist',
          icon: const Icon(Icons.rule_folder_outlined),
          onPressed: () => context.push('/ecfe/spec'),
        ),
      ],

      title: 'e-CF · DGII',
      subtitle: 'Facturación electrónica (módulo independiente)',
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: mobile ? 720 : 960),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      'Este módulo es independiente de ventas y caja. '
                      'Mientras esté deshabilitado o en preparación, '
                      'las operaciones diarias no se ven afectadas.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabs,
                  labelColor: AppColors.primary,
                  tabs: const [
                    Tab(text: 'Cola'),
                    Tab(text: 'Configuración'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: const [
                      _ColaTab(),
                      _ConfigTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ColaTab extends ConsumerWidget {
  const _ColaTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ecfeColaProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (lista) {
        if (lista.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_outlined,
                      size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text(
                    'Sin comprobantes e-CF en cola',
                    style: AppTypography.h4.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fase 0: estructura lista. El encolado desde ventas '
                    'se activará solo cuando el módulo esté habilitado.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: lista.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final d = lista[i];
            return ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              title: Text('${d.tipoEcf.codigo} · ${d.tipoEcf.descripcion}'),
              subtitle: Text(
                '${d.estado.etiqueta}'
                '${d.encf != null ? ' · ${d.encf}' : ''}'
                '${d.ventaId != null ? ' · venta #${d.ventaId}' : ''}'
                '${d.ultimoError != null ? '\n${d.ultimoError}' : ''}',
              ),
              isThreeLine: d.ultimoError != null,
              trailing: const Icon(Icons.chevron_right),
              onTap: d.id == null
                  ? null
                  : () => context.push('/ecfe/${d.id}'),
            );
          },
        );
      },
    );
  }
}

class _ConfigTab extends ConsumerStatefulWidget {
  const _ConfigTab();
  @override
  ConsumerState<_ConfigTab> createState() => _ConfigTabState();
}

class _ConfigTabState extends ConsumerState<_ConfigTab> {
  final _rnc = TextEditingController();
  final _razon = TextEditingController();
  final _rutaCert = TextEditingController();
  final _claveCert = TextEditingController();
  bool _habilitado = false;
  AmbienteDgii _ambiente = AmbienteDgii.deshabilitado;
  bool _loaded = false;

  @override
  void dispose() {
    _rnc.dispose();
    _razon.dispose();
    _rutaCert.dispose();
    _claveCert.dispose();
    super.dispose();
  }

  void _hydrate(EcfeConfig c) {
    if (_loaded) return;
    _habilitado = c.habilitado;
    _ambiente = c.ambiente;
    _rnc.text = c.rncEmisor;
    _razon.text = c.razonSocialEmisor;
    _rutaCert.text = c.rutaCertificado;
    _claveCert.text = c.claveCertificado;
    _loaded = true;
  }

  Future<void> _guardar() async {
    final c = EcfeConfig(
      habilitado: _habilitado,
      ambiente: _ambiente,
      rncEmisor: _rnc.text.trim(),
      razonSocialEmisor: _razon.text.trim(),
      rutaCertificado: _rutaCert.text.trim(),
      claveCertificado: _claveCert.text,
    );
    await ref.read(ecfeRepositoryProvider).guardarConfig(c);
    ref.invalidate(ecfeConfigProvider);
    ref.invalidate(ecfeHabilitadoProvider);
    if (!mounted) return;
    FiscoGestNotifications.show(
      const SnackBar(
        content: Text('Configuración e-CF guardada (no afecta ventas)'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ecfeConfigProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (cfg) {
        _hydrate(cfg);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: const Text('Habilitar módulo e-CF'),
              subtitle: const Text(
                'Desactivado por defecto. No encola ni envía nada.',
              ),
              value: _habilitado,
              onChanged: (v) => setState(() => _habilitado = v),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<AmbienteDgii>(
              initialValue: _ambiente,
              decoration: const InputDecoration(
                labelText: 'Ambiente DGII',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final a in AmbienteDgii.values)
                  DropdownMenuItem(value: a, child: Text(a.etiqueta)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _ambiente = v);
              },
            ),
            const SizedBox(height: 12),
            AppTextField(label: 'RNC emisor', controller: _rnc),
            const SizedBox(height: 12),
            AppTextField(label: 'Razón social emisor', controller: _razon),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Ruta certificado (.p12 / .pfx)',
              controller: _rutaCert,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Clave del certificado',
              controller: _claveCert,
              obscureText: true,
            ),
            const SizedBox(height: 8),
            Text(
              'El certificado lo emite un PSC acreditado por INDOTEL. '
              'La firma usa OpenSSL en este equipo (XMLDSig RSA-SHA256).',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              text: 'Guardar configuración',
              onPressed: _guardar,
            ),
            const SizedBox(height: 16),
            Text(
              'Certificado digital, XSD y envío a DGII se configuran en fases posteriores. '
              'Fase 0 solo prepara la base del módulo.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }
}
