import 'package:fiscogest_rd/features/e_cf/domain/entities/ecfe_documento.dart';
import 'package:fiscogest_rd/features/e_cf/domain/services/ecfe_siguiente_accion.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/estado_ecf_interno.dart';
import 'package:fiscogest_rd/features/e_cf/data/repositories/ecfe_secuencia_service.dart';
import 'package:intl/intl.dart';
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
    _tabs = TabController(length: 3, vsync: this);
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
      subtitle: 'Caja igual · vea la pestaña Cómo usar',
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
                    Tab(text: 'Cómo usar'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: const [
                      _ColaTab(),
                      _ConfigTab(),
          const _GuiaTab(),
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



class _ColaTab extends ConsumerStatefulWidget {
  const _ColaTab();

  @override
  ConsumerState<_ColaTab> createState() => _ColaTabState();
}

class _ColaTabState extends ConsumerState<_ColaTab> {
  String? _filtro;

  static const _filtros = <(String?, String)>[
    (null, 'Todos'),
    ('pendiente', 'Pendientes'),
    ('enviado', 'Enviados'),
    ('error', 'Errores'),
    ('aceptado', 'Aceptados'),
  ];

  List<EcfeDocumento> _filtrar(List<EcfeDocumento> lista) {
    final f = _filtro;
    if (f == null) return lista;
    return lista.where((EcfeDocumento d) {
      final e = d.estado;
      switch (f) {
        case 'pendiente':
          return e == EstadoEcfInterno.borrador ||
              e == EstadoEcfInterno.validacionFallida ||
              e == EstadoEcfInterno.xmlListo ||
              e == EstadoEcfInterno.firmado;
        case 'enviado':
          return e == EstadoEcfInterno.enviado ||
              e == EstadoEcfInterno.enProceso;
        case 'error':
          return e == EstadoEcfInterno.errorTecnico ||
              e == EstadoEcfInterno.rechazado;
        case 'aceptado':
          return e.esTerminalExito;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ecfeColaProvider);
    final certAsync = ref.watch(certificadoInfoProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        certAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (info) {
            if (info == null || !info.requiereAviso) {
              return const SizedBox.shrink();
            }
            return Material(
              color: info.vencido
                  ? AppColors.error.withValues(alpha: 0.12)
                  : const Color(0xFFFFF3E0),
              child: ListTile(
                dense: true,
                leading: Icon(
                  Icons.warning_amber_rounded,
                  color: info.vencido ? AppColors.error : const Color(0xFFE65100),
                ),
                title: Text(
                  info.mensaje,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Renueva el certificado del PSC antes de firmar/enviar.',
                ),
              ),
            );
          },
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              for (final entry in _filtros)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(entry.$2),
                    selected: _filtro == entry.$1,
                    onSelected: (_) => setState(() => _filtro = entry.$1),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (lista) {
              final view = _filtrar(lista);
              if (view.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      lista.isEmpty
                          ? 'Sin comprobantes e-CF en cola.\n'
                              'Se encolan al facturar si el módulo está habilitado.'
                          : 'No hay documentos en este filtro.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(ecfeColaProvider);
                  ref.invalidate(certificadoInfoProvider);
                  await ref.read(ecfeColaProvider.future);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: view.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final EcfeDocumento d = view[i];
                    final String accion = EcfeSiguienteAccion.etiqueta(
                      d.estado,
                      trackId: d.trackId,
                    );
                    final String err =
                        (d.ultimoError ?? d.mensajeDgii ?? '').trim();
                    final String track = (d.trackId ?? '').trim();
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      title: Text(
                        '${d.tipoEcf.codigo} · ${d.tipoEcf.descripcion}',
                      ),
                      subtitle: Text(
                        '${d.estado.etiqueta}'
                        '${d.encf != null ? ' · ${d.encf}' : ''}'
                        '${d.ventaId != null ? ' · venta #${d.ventaId}' : ''}'
                        '${track.isNotEmpty ? ' · Track $track' : ''}'
                        '\n→ $accion'
                        '${err.isNotEmpty ? '\n⚠ $err' : ''}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/ecfe/${d.id}'),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
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
  final _rutaXsd = TextEditingController();
  bool _habilitado = false;
  AmbienteDgii _ambiente = AmbienteDgii.deshabilitado;
  bool _loaded = false;

  @override
  void dispose() {
    _rnc.dispose();
    _razon.dispose();
    _rutaCert.dispose();
    _claveCert.dispose();
    _rutaXsd.dispose();
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
    _rutaXsd.text = c.xsdVersion;
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
      xsdVersion: _rutaXsd.text.trim(),
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
            Consumer(
              builder: (context, ref, _) {
                final cert = ref.watch(certificadoInfoProvider);
                return cert.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('$e', style: AppTypography.bodySmall),
                  data: (info) {
                    if (info == null) {
                      return Text(
                        'Indica ruta y clave del .p12 para verificar vencimiento.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      );
                    }
                    final color = info.vencido
                        ? AppColors.error
                        : (info.requiereAviso
                            ? const Color(0xFFE65100)
                            : AppColors.success);
                    return Text(
                      info.mensaje,
                      style: AppTypography.bodySmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                );
              },
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
            AppTextField(
              label: 'Ruta XSD oficial DGII (.xsd o carpeta)',
              controller: _rutaXsd,
            ),
            const SizedBox(height: 8),
            Text(
              'Descarga el paquete de esquemas e-CF de la DGII y apunta al .xsd raíz. '
              'Validación XSD: xmllint/libxml2 en el PATH (Linux: apt install libxml2-utils · Windows: instale xmllint y agréguelo al PATH). '
              'Sin XSD solo aplica validación estructural interna.',
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
            const _SecuenciasEncfSection(),
          ],
        );
      },
    );
  }
}

/// Rangos e-NCF (autorización DGII) — obligatorio antes de generar XML.
class _SecuenciasEncfSection extends ConsumerWidget {
  const _SecuenciasEncfSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ecfeSecuenciasProvider);
    final fmt = DateFormat('dd/MM/yyyy');
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('$e'),
      data: (list) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              'Secuencias e-NCF',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Usa los rangos autorizados por la DGII. Sin secuencia activa '
              'no se puede generar XML. Formato: E + tipo + 10 dígitos.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            for (final s in list)
              Card(
                child: ListTile(
                  title: Text(s.tipoLabel),
                  subtitle: Text(
                    'Actual: ${s.secuenciaActual} · '
                    'Rango: ${s.secuenciaDesde}–${s.secuenciaHasta} · '
                    'Disp.: ${s.disponibles}'
                    '${s.fechaVencimiento != null ? ' · Vence: ${fmt.format(s.fechaVencimiento!)}' : ''}'
                    '${s.vencida ? ' · VENCIDA' : ''}'
                    '${s.activo ? '' : ' · INACTIVA'}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editar(context, ref, s),
                  ),
                ),
              ),
            TextButton.icon(
              onPressed: () => _editar(context, ref, null),
              icon: const Icon(Icons.add),
              label: const Text('Agregar / otro tipo'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editar(
    BuildContext context,
    WidgetRef ref,
    EcfeSecuenciaInfo? existing,
  ) async {
    final tipoCtrl = TextEditingController(
      text: '${existing?.tipoEcf ?? 31}',
    );
    final actualCtrl = TextEditingController(
      text: '${existing?.secuenciaActual ?? 0}',
    );
    final desdeCtrl = TextEditingController(
      text: '${existing?.secuenciaDesde ?? 1}',
    );
    final hastaCtrl = TextEditingController(
      text: '${existing?.secuenciaHasta ?? 100}',
    );
    var activo = existing?.activo ?? true;
    DateTime? venc = existing?.fechaVencimiento ??
        DateTime(DateTime.now().year + 1, 12, 31);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            return AlertDialog(
              title: Text(existing == null ? 'Nueva secuencia' : 'Editar secuencia'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: tipoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tipo e-CF (31, 32, 34…)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: actualCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Último usado (actual)',
                        border: OutlineInputBorder(),
                        helperText: 'El próximo será actual+1',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: desdeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Desde',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: hastaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Hasta',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SwitchListTile(
                      title: const Text('Activa'),
                      value: activo,
                      onChanged: (v) => setSt(() => activo = v),
                    ),
                    ListTile(
                      title: Text(
                        venc == null
                            ? 'Sin vencimiento'
                            : 'Vence: ${DateFormat('dd/MM/yyyy').format(venc!)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: venc ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2040),
                        );
                        if (d != null) setSt(() => venc = d);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok != true) return;
    try {
      await ref.read(ecfeSecuenciaServiceProvider).guardar(
            id: existing?.id,
            tipoEcf: int.parse(tipoCtrl.text.trim()),
            secuenciaActual: int.parse(actualCtrl.text.trim()),
            secuenciaDesde: int.parse(desdeCtrl.text.trim()),
            secuenciaHasta: int.parse(hastaCtrl.text.trim()),
            fechaVencimiento: venc,
            activo: activo,
          );
      ref.invalidate(ecfeSecuenciasProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Secuencia e-NCF guardada')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}


class _GuiaTab extends StatelessWidget {
  const _GuiaTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text(
          'Cómo usar e-CF',
          style: AppTypography.h4.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Esto es la factura electrónica de la DGII. '
          'En caja usted cobra igual. Aquí solo se mira si el comprobante '
          'ya se envió bien.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),

        const _GuiaPaso(
          numero: '1',
          color: Color(0xFF1565C0),
          icon: Icons.point_of_sale_outlined,
          titulo: 'Usted vende normal',
          texto:
              'Haga la venta como siempre. '
              'Si e-CF está activo, el sistema prepara el comprobante solo. '
              'No tiene que hacer nada raro en caja.',
        ),
        const _GuiaPaso(
          numero: '2',
          color: Color(0xFF6A1B9A),
          icon: Icons.list_alt_outlined,
          titulo: 'Mire la Cola',
          texto:
              'Entre a la pestaña Cola. '
              'Ahí salen los comprobantes: pendientes, enviados, errores o aceptados. '
              'Toque uno para ver el detalle.',
        ),
        const _GuiaPaso(
          numero: '3',
          color: Color(0xFF2E7D32),
          icon: Icons.play_arrow_rounded,
          titulo: 'Siga el botón que le indica',
          texto:
              'En el detalle vaya en este orden:\n'
              '① Generar XML\n'
              '② Firmar\n'
              '③ Enviar a la DGII\n'
              '④ Consultar estado\n'
              '⑤ Imprimir RI (si necesita el papel con QR)\n\n'
              'La tarjeta de la Cola le dice qué falta (ejemplo: “Firmar XML”).',
        ),
        const _GuiaPaso(
          numero: '4',
          color: Color(0xFF00838F),
          icon: Icons.verified_outlined,
          titulo: '¿Qué significa cada estado?',
          texto:
              '• Pendiente / borrador: aún no se envió.\n'
              '• Firmado: listo para enviar.\n'
              '• Enviado / en proceso: ya está en la DGII; espere o consulte.\n'
              '• Aceptado: listo, cumplió.\n'
              '• Error o rechazado: lea el mensaje rojo y avise a quien administra el sistema.\n'
              '• Anulado: se detuvo a propósito; no se vuelve a enviar.',
        ),
        const _GuiaPaso(
          numero: '5',
          color: Color(0xFFEF6C00),
          icon: Icons.print_outlined,
          titulo: 'Imprimir la representación (RI)',
          texto:
              'Cuando el comprobante ya tiene su número e-NCF, use '
              '“Imprimir RI (QR)”. '
              'Eso es el papel o PDF con el código y el cuadrito QR para consultar.',
        ),
        const _GuiaPaso(
          numero: '6',
          color: Color(0xFFC62828),
          icon: Icons.warning_amber_rounded,
          titulo: 'Si algo falla',
          texto:
              '1. Lea el mensaje en el detalle (está en español).\n'
              '2. Si dice “ya estaba enviado”, no reenvíe: use Consultar estado.\n'
              '3. Si no firma: el certificado (.p12) o la clave están mal o vencidos.\n'
              '4. Si no hay internet, el envío espera; cuando haya red, reintente.\n'
              '5. Si no entiende el error, no invente: llame a quien le instaló FiscoGest.',
        ),

        const SizedBox(height: 8),
        Text(
          'Solo para quien configura el sistema',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const _GuiaMini(
          icon: Icons.settings_outlined,
          titulo: 'Configuración',
          texto:
              'Ahí se prende el módulo, se elige si es prueba o producción, '
              'se pone el certificado y los números e-NCF autorizados. '
              'El cajero no necesita entrar aquí todos los días.',
        ),
        const _GuiaMini(
          icon: Icons.note_alt_outlined,
          titulo: 'Nota de crédito (tipo 34)',
          texto:
              'Antes de generar el XML hay que poner el e-NCF de la factura '
              'que se está corrigiendo (botón “e-NCF de referencia”).',
        ),
        const _GuiaMini(
          icon: Icons.schedule_outlined,
          titulo: 'Certificado por vencer',
          texto:
              'Si sale un aviso naranja o rojo arriba en la Cola, '
              'hay que renovar el certificado con el PSC. '
              'Si se vence, no se puede firmar ni enviar.',
        ),

        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          ),
          child: Text(
            'Resumen en una frase:\n'
            'Venda normal → mire la Cola → abra el comprobante → '
            'pulse el botón que falta → cuando diga Aceptado, ya cumplió con la DGII.',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _GuiaPaso extends StatelessWidget {
  const _GuiaPaso({
    required this.numero,
    required this.color,
    required this.icon,
    required this.titulo,
    required this.texto,
  });

  final String numero;
  final Color color;
  final IconData icon;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color,
              radius: 18,
              child: Text(
                numero,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 20, color: color),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          titulo,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    texto,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuiaMini extends StatelessWidget {
  const _GuiaMini({
    required this.icon,
    required this.titulo,
    required this.texto,
  });

  final IconData icon;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  texto,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
