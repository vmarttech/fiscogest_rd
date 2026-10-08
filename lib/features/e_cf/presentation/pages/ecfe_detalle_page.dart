import 'package:fiscogest_rd/features/e_cf/presentation/ecfe_solo_lectura.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/tipo_ecf.dart';
import 'package:fiscogest_rd/features/e_cf/domain/entities/ecfe_documento.dart';
import 'package:fiscogest_rd/features/e_cf/application/anular_ecfe.dart';
import 'package:fiscogest_rd/features/e_cf/application/consultar_ecfe.dart';
import 'package:fiscogest_rd/features/e_cf/application/enviar_ecfe.dart';
import 'package:fiscogest_rd/features/e_cf/application/firmar_xml_ecfe.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/ambiente_dgii.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/estado_ecf_interno.dart';
import 'package:fiscogest_rd/features/e_cf/presentation/pdf/representacion_impresa_pdf.dart';
import 'package:fiscogest_rd/features/e_cf/presentation/providers/ecfe_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/listas_ventas_providers.dart';
import 'package:fiscogest_rd/features/configuracion/presentation/providers/configuracion_providers.dart';
import 'package:fiscogest_rd/features/configuracion/domain/entities/configuracion_entity.dart';

class EcfeDetallePage extends ConsumerStatefulWidget {
  const EcfeDetallePage({super.key, required this.documentoId});
  final int documentoId;
  static const routeName = 'ecfe-detalle';

  @override
  ConsumerState<EcfeDetallePage> createState() => _EcfeDetallePageState();
}

class _EcfeDetallePageState extends ConsumerState<EcfeDetallePage> {
  bool _generando = false;
  String? _xmlPreview;


  Future<void> _imprimirRi() async {
    setState(() => _generando = true);
    try {
      final repo = ref.read(ecfeRepositoryProvider);
      final doc = await repo.obtenerPorId(widget.documentoId);
      if (doc == null) throw StateError('Documento no encontrado');
      if (doc.ventaId == null) throw StateError('Sin venta asociada');
      final venta = await ref.read(ventasRepositoryProvider).obtenerVentaPorId(doc.ventaId!);
      if (venta == null) throw StateError('Venta no encontrada');
      final cfg = await repo.obtenerConfig();
      final empresa = ref.read(configuracionControllerProvider).valueOrNull;
      final xml = await repo.obtenerXmlFirmado(doc.id!);
      final encf = (doc.encf ?? '').trim();
      if (encf.isEmpty) throw StateError('Sin e-NCF aún; genera/firma el XML primero');
      await RepresentacionImpresaPdf.imprimir(
        venta: venta,
        encf: encf,
        tipoEcf: doc.tipoEcf,
        rncEmisor: cfg.rncEmisor.isNotEmpty ? cfg.rncEmisor : (empresa?.rnc ?? ''),
        razonSocialEmisor: cfg.razonSocialEmisor.isNotEmpty
            ? cfg.razonSocialEmisor
            : (empresa?.razonSocial ?? ''),
        ambiente: cfg.ambiente,
        xmlFirmado: xml,
        trackId: doc.trackId,
        codigoSeguridad: doc.codigoSeguridad,
        empresa: empresa,
      );
    } catch (e) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('RI: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  Future<void> _generarXml() async {
    if (ecfeSoloLectura) {
      avisoEcfeVersionPc(context);
      return;
    }
    await _generarXmlCore();
  }

  Future<void> _generarXmlCore() async {
    if (ecfeSoloLectura) {
      avisoEcfeVersionPc(context);
      return;
    }
    setState(() => _generando = true);
    try {
      final repoEcfe = ref.read(ecfeRepositoryProvider);
      final doc = await repoEcfe.obtenerPorId(widget.documentoId);
      if (doc == null || doc.ventaId == null) {
        throw StateError('Documento sin venta asociada');
      }
      final ventasRepo = ref.read(ventasRepositoryProvider);
      final venta = await ventasRepo.obtenerVentaPorId(doc.ventaId!);
      if (venta == null) throw StateError('Venta no encontrada');

      final detalles = venta.detalles;
      if (detalles.isEmpty) {
        throw StateError('La venta no tiene líneas de detalle');
      }

      final ConfiguracionEntity? empresa =
          ref.read(configuracionControllerProvider).valueOrNull;
      final ecfeCfg = await repoEcfe.obtenerConfig();

      final rncEmisor = ecfeCfg.rncEmisor.isNotEmpty
          ? ecfeCfg.rncEmisor
          : (empresa?.rnc ?? '');
      final razon = ecfeCfg.razonSocialEmisor.isNotEmpty
          ? ecfeCfg.razonSocialEmisor
          : (empresa?.razonSocial ?? empresa?.nombreComercial ?? '');

      final result = await ref.read(generarXmlEcfeProvider)(
        documentoId: widget.documentoId,
        venta: venta,
        detalles: detalles,
        rncEmisor: rncEmisor,
        razonSocialEmisor: razon,
        direccionEmisor: empresa?.direccion ?? 'N/D',
        telefonoEmisor: empresa?.telefono,
        correoEmisor: empresa?.correo,
        rncCliente: '',
        nombreCliente: venta.nombreCliente ?? '',
        tasaItbis: empresa?.impuestoPorcentaje ?? 18.0,
        rutaXsd: ecfeCfg.xsdVersion.isEmpty ? null : ecfeCfg.xsdVersion,
        exigirXsd: ecfeCfg.ambiente == AmbienteDgii.certificacion ||
            ecfeCfg.ambiente == AmbienteDgii.produccion,
      );

      ref.invalidate(ecfeDocumentoProvider(widget.documentoId));
      ref.invalidate(ecfeEventosProvider(widget.documentoId));
      ref.invalidate(ecfeColaProvider);

      if (!mounted) return;
      setState(() => _xmlPreview = result.xml);

      FiscoGestNotifications.show(
        SnackBar(
          content: Text(
            result.ok
                ? 'XML generado (${result.encf}) · validación OK'
                : 'XML con errores: ${result.errores.take(2).join('; ')}',
          ),
          backgroundColor:
              result.ok ? AppColors.success : AppColors.warning,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('Error al generar XML: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }




  /// Generar XML → Firmar → Enviar a DGII (un solo flujo).
  Future<void> _procesarEcfe() async {
    if (ecfeSoloLectura) {
      avisoEcfeVersionPc(context);
      return;
    }
    setState(() => _generando = true);
    final pasos = <String>[];
    try {
      final repo = ref.read(ecfeRepositoryProvider);
      var doc = await repo.obtenerPorId(widget.documentoId);
      if (doc == null) {
        throw StateError('Documento no encontrado');
      }

      // 1) Generar XML si aún no está listo o firmado
      if (doc.estado == EstadoEcfInterno.borrador ||
          doc.estado == EstadoEcfInterno.validacionFallida) {
        // _generarXml gestiona UI; evitamos doble flag: llamamos y releemos
        final was = _generando;
        await _generarXmlCore();
        doc = await repo.obtenerPorId(widget.documentoId);
        if (doc == null ||
            (doc.estado != EstadoEcfInterno.xmlListo &&
                doc.estado != EstadoEcfInterno.firmado)) {
          throw StateError(
            'Generación incompleta (${doc?.estado.etiqueta ?? '?'}). '
            'Revise el error del documento.',
          );
        }
        pasos.add('XML generado');
        setState(() => _generando = was);
      } else if (doc.estado == EstadoEcfInterno.xmlListo) {
        pasos.add('XML ya listo');
      }

      // 2) Firmar
      doc = await repo.obtenerPorId(widget.documentoId);
      if (doc != null &&
          (doc.estado == EstadoEcfInterno.xmlListo ||
              doc.estado == EstadoEcfInterno.errorTecnico)) {
        final fr = await FirmarXmlEcfe(repo: repo).call(
          documentoId: widget.documentoId,
        );
        if (!fr.ok) {
          throw StateError(fr.errores.join(' · '));
        }
        if (fr.xmlFirmado != null) {
          setState(() => _xmlPreview = fr.xmlFirmado);
        }
        pasos.add('Firmado');
      } else if (doc?.estado == EstadoEcfInterno.firmado) {
        pasos.add('Ya firmado');
      }

      // 3) Enviar
      final er = await EnviarEcfe(repo: repo).call(
        documentoId: widget.documentoId,
      );
      if (!er.ok) {
        throw StateError(er.errores.join(' · '));
      }
      pasos.add(
        er.yaEnviado
            ? 'TrackId existente ${er.trackId}'
            : 'Enviado · TrackId ${er.trackId}',
      );

      ref.invalidate(ecfeDocumentoProvider(widget.documentoId));
      ref.invalidate(ecfeEventosProvider(widget.documentoId));
      ref.invalidate(ecfeColaProvider);
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('Procesar e-CF: ${pasos.join(' → ')}'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ref.invalidate(ecfeDocumentoProvider(widget.documentoId));
      ref.invalidate(ecfeEventosProvider(widget.documentoId));
      ref.invalidate(ecfeColaProvider);
      if (mounted) {
        FiscoGestNotifications.show(
          SnackBar(
            content: Text('Procesar e-CF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }


  Future<void> _firmarXml() async {
    if (ecfeSoloLectura) {
      avisoEcfeVersionPc(context);
      return;
    }
    setState(() => _generando = true);
    try {
      final result = await FirmarXmlEcfe(repo: ref.read(ecfeRepositoryProvider))
          .call(documentoId: widget.documentoId);
      ref.invalidate(ecfeDocumentoProvider(widget.documentoId));
      ref.invalidate(ecfeEventosProvider(widget.documentoId));
      ref.invalidate(ecfeColaProvider);
      if (!mounted) return;
      if (result.ok) {
        setState(() => _xmlPreview = result.xmlFirmado);
        FiscoGestNotifications.show(
          const SnackBar(
            content: Text('XML firmado (listo para enviar a DGII)'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        FiscoGestNotifications.show(
          SnackBar(
            content: Text(result.errores.join(' · ')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        FiscoGestNotifications.show(
          SnackBar(
            content: Text('Error al firmar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  Future<void> _enviarDgii() async {
    if (ecfeSoloLectura) {
      avisoEcfeVersionPc(context);
      return;
    }
    setState(() => _generando = true);
    try {
      final result = await EnviarEcfe(repo: ref.read(ecfeRepositoryProvider))
          .call(documentoId: widget.documentoId);
      ref.invalidate(ecfeDocumentoProvider(widget.documentoId));
      ref.invalidate(ecfeEventosProvider(widget.documentoId));
      ref.invalidate(ecfeColaProvider);
      if (!mounted) return;
      if (result.ok) {
        final msg = result.yaEnviado
            ? 'Ya estaba enviado (TrackId ${result.trackId}). Consulta el estado.'
            : 'Enviado a DGII · TrackId ${result.trackId}';
        FiscoGestNotifications.show(SnackBar(content: Text(msg)));
      } else {
        FiscoGestNotifications.show(SnackBar(content: Text(result.errores.join(' · ')), backgroundColor: AppColors.error));
      }
    } catch (e) {
      if (mounted) {
        FiscoGestNotifications.show(SnackBar(content: Text('$e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  Future<void> _consultarEstado() async {
    if (ecfeSoloLectura) {
      avisoEcfeVersionPc(context);
      return;
    }
    setState(() => _generando = true);
    try {
      final result = await ConsultarEcfe(repo: ref.read(ecfeRepositoryProvider))
          .call(documentoId: widget.documentoId);
      ref.invalidate(ecfeDocumentoProvider(widget.documentoId));
      ref.invalidate(ecfeEventosProvider(widget.documentoId));
      ref.invalidate(ecfeColaProvider);
      if (!mounted) return;
      if (result.ok) {
        final label = result.estado?.etiqueta ?? result.estadoDgii ?? 'OK';
        final extra = result.mensaje != null ? ' · ${result.mensaje}' : '';
        FiscoGestNotifications.show(SnackBar(content: Text('DGII: $label$extra')));
      } else {
        FiscoGestNotifications.show(SnackBar(content: Text(result.errores.join(' · ')), backgroundColor: AppColors.error));
      }
    } catch (e) {
      if (mounted) {
        FiscoGestNotifications.show(SnackBar(content: Text('$e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }


  Future<void> _editarEncfReferencia(EcfeDocumento doc) async {
    if (ecfeSoloLectura) {
      avisoEcfeVersionPc(context);
      return;
    }
    final ctrl = TextEditingController(text: doc.encfReferencia ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('e-NCF de referencia (NC)'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'e-NCF modificado (E31… / E32…)',
            border: OutlineInputBorder(),
            helperText: 'Obligatorio para nota de crédito electrónica (34)',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(ecfeRepositoryProvider).guardarEncfReferencia(
            id: widget.documentoId,
            encfReferencia: ctrl.text,
          );
      ref.invalidate(ecfeDocumentoProvider(widget.documentoId));
      FiscoGestNotifications.show(
        const SnackBar(content: Text('e-NCF de referencia guardado')),
      );
    } catch (e) {
      FiscoGestNotifications.show(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _anularDocumento(EcfeDocumento doc) async {
    if (ecfeSoloLectura) {
      avisoEcfeVersionPc(context);
      return;
    }
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anular documento e-CF'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Motivo',
            border: OutlineInputBorder(),
            helperText: 'Queda registrado en el historial del documento',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Anular')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _generando = true);
    try {
      final r = await AnularEcfe(repo: ref.read(ecfeRepositoryProvider)).call(
        documentoId: widget.documentoId,
        motivo: ctrl.text,
      );
      ref.invalidate(ecfeDocumentoProvider(widget.documentoId));
      ref.invalidate(ecfeEventosProvider(widget.documentoId));
      ref.invalidate(ecfeColaProvider);
      if (!mounted) return;
      if (r.ok) {
        FiscoGestNotifications.show(
          const SnackBar(content: Text('Documento anulado')),
        );
      } else {
        FiscoGestNotifications.show(
          SnackBar(
            content: Text(r.errores.join(' · ')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    final async = ref.watch(ecfeDocumentoProvider(widget.documentoId));
    final eventos = ref.watch(ecfeEventosProvider(widget.documentoId));
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    return AppScaffold(
      title: 'Detalle e-CF',
      subtitle: 'Documento #${widget.documentoId}',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/ecfe');
          }
        },
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: mobile ? 720 : 800),
            child: async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (doc) {
                if (doc == null) {
                  return const Center(
                    child: Text('Documento no encontrado'),
                  );
                }
                final puedeXml = doc.estado == EstadoEcfInterno.borrador ||
                    doc.estado == EstadoEcfInterno.validacionFallida ||
                    doc.estado == EstadoEcfInterno.errorTecnico ||
                    doc.estado == EstadoEcfInterno.xmlListo;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const EcfeSoloLecturaBanner(),
                    _card(
                      children: [
                        _row(
                          'Tipo',
                          '${doc.tipoEcf.codigo} · ${doc.tipoEcf.descripcion}',
                        ),
                        _row('Estado', doc.estado.etiqueta),
                        _row('e-NCF', doc.encf ?? '—'),
                        _row(
                          'Venta',
                          doc.ventaId != null ? '#${doc.ventaId}' : '—',
                        ),
                        _row('TrackId', doc.trackId ?? '—'),
                        _row('Cód. seguridad', doc.codigoSeguridad ?? '—'),
                        if (doc.tipoEcf == TipoEcf.notaCredito)
                          _row('e-NCF ref.', doc.encfReferencia ?? '—'),
                        if (doc.estado == EstadoEcfInterno.anulado)
                          _row('Motivo anulación', doc.motivoAnulacion ?? '—'),
                        if (doc.ultimoError != null &&
                            doc.ultimoError!.isNotEmpty)
                          _row('Error', doc.ultimoError!, error: true),
                        _row('Creado', fmt.format(doc.creadoEn)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (puedeXml ||
                        doc.estado == EstadoEcfInterno.xmlListo ||
                        doc.estado == EstadoEcfInterno.firmado ||
                        doc.estado == EstadoEcfInterno.errorTecnico)
                      AppButton(
                        text: _generando
                            ? 'Procesando…'
                            : 'Procesar e-CF (generar → firmar → enviar)',
                        onPressed: _generando ? null : _procesarEcfe,
                      ),
                    if (puedeXml) ...[
                      const SizedBox(height: 10),
                      AppButton(
                        text: _generando
                            ? 'Generando…'
                            : 'Generar / validar XML',
                        onPressed: _generando ? null : _generarXml,
                      ),
                    ],
                    if (_xmlPreview != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Vista previa XML',
                            style: AppTypography.h4
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: _xmlPreview!),
                              );
                              FiscoGestNotifications.show(
                                const SnackBar(
                                  content: Text('XML copiado'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('Copiar'),
                          ),
                        ],
                      ),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxHeight: 280),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            _xmlPreview!,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (doc.estado == EstadoEcfInterno.xmlListo ||
                        doc.estado == EstadoEcfInterno.errorTecnico) ...[
                      const SizedBox(height: 10),
                      AppButton(
                        text: _generando ? 'Procesando…' : 'Firmar XML',
                        onPressed: _generando ? null : _firmarXml,
                      ),
                    ],
                    if (doc.estado == EstadoEcfInterno.firmado ||
                        (doc.estado == EstadoEcfInterno.errorTecnico &&
                            (doc.trackId ?? '').isEmpty)) ...[
                      const SizedBox(height: 10),
                      AppButton(
                        text: _generando ? 'Procesando…' : 'Enviar a DGII',
                        onPressed: _generando ? null : _enviarDgii,
                      ),
                    ],
                    if ((doc.trackId ?? '').isNotEmpty) ...[
                      const SizedBox(height: 10),
                      AppButton(
                        text: _generando
                            ? 'Procesando…'
                            : 'Consultar estado DGII',
                        onPressed: _generando ? null : _consultarEstado,
                      ),
                    ],
                    if ((doc.encf ?? '').isNotEmpty) ...[
                      const SizedBox(height: 10),
                      AppButton(
                        text: _generando ? 'Procesando…' : 'Imprimir RI (QR)',
                        onPressed: _generando ? null : _imprimirRi,
                      ),
                      if (doc.tipoEcf == TipoEcf.notaCredito &&
                          doc.estado != EstadoEcfInterno.anulado)
                        AppButton(
                          text: 'e-NCF de referencia (NC)',
                          onPressed: _generando
                              ? null
                              : () => _editarEncfReferencia(doc),
                        ),
                      if (doc.estado != EstadoEcfInterno.anulado &&
                          !doc.estado.esTerminalExito)
                        AppButton(
                          text: 'Anular e-CF (interno)',
                          onPressed:
                              _generando ? null : () => _anularDocumento(doc),
                        ),
                    ],

                    const SizedBox(height: 16),
                    Text(
                      'Historial de eventos',
                      style: AppTypography.h4
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    eventos.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('$e'),
                      data: (evs) {
                        if (evs.isEmpty) {
                          return Text(
                            'Sin eventos',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          );
                        }
                        return Column(
                          children: [
                            for (final e in evs)
                              ListTile(
                                dense: true,
                                leading: Icon(
                                  e.ok
                                      ? Icons.check_circle
                                      : Icons.error_outline,
                                  color: e.ok
                                      ? AppColors.success
                                      : AppColors.error,
                                  size: 22,
                                ),
                                title: Text(e.paso),
                                subtitle: Text(
                                  '${fmt.format(e.creadoEn)}'
                                  '${e.detalle != null ? '\n${e.detalle}' : ''}',
                                ),
                                isThreeLine: e.detalle != null,
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Fase 2: XML + validación estructural. '
                      'Firma y envío DGII en fases 3–4.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _row(String k, String v, {bool error = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              k,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: error ? AppColors.error : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
