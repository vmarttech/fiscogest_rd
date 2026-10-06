import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/store/store_channel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_dropdown.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/features/configuracion/domain/entities/configuracion_entity.dart';
import 'package:fiscogest_rd/features/configuracion/presentation/providers/configuracion_providers.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';

enum _SeccionConfig {
  empresa,
  documentos,
  ventas,
  caja,
  credito,
  ncf,
  impuestos,
  sistema,
}

class ConfiguracionPage extends ConsumerStatefulWidget {
  const ConfiguracionPage({super.key});

  static const String routeName = 'configuracion';

  @override
  ConsumerState<ConfiguracionPage> createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends ConsumerState<ConfiguracionPage> {
  _SeccionConfig _seccion = _SeccionConfig.empresa;

  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _rncController = TextEditingController();
  final _itbisController = TextEditingController(text: '18.0');
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();

  String _monedaSeleccionada = 'DOP';
  String _idiomaSeleccionado = 'Español';
  String? _logoPath;
  bool _datosCargados = false;
  bool _guardando = false;

  // Documentos / factura
  bool _docLogo = true;
  bool _docRnc = true;
  bool _docDireccion = true;
  bool _docTelefono = true;
  bool _docCorreo = true;
  bool _docNcf = true;
  bool _docCliente = true;
  bool _docItbisDesglose = true;
  final _pieController = TextEditingController(
    text: 'Gracias por su preferencia',
  );
  final _prefijoContadoController = TextEditingController(text: 'C');
  final _prefijoCreditoController = TextEditingController(text: 'CR');
  String _cajaFormaPagoDefault = 'efectivo';
  bool _cajaPermitirTarjeta = true;
  bool _cajaPermitirTransferencia = true;
  bool _cajaPermitirCheque = false;
  bool _cajaExigirSesion = false;
  bool _modoSimplificado = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _rncController.dispose();
    _itbisController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _pieController.dispose();
    _prefijoContadoController.dispose();
    _prefijoCreditoController.dispose();
    super.dispose();
  }

  void _aplicarConfig(ConfiguracionEntity cfg) {
    _nombreController.text = cfg.nombreComercial;
    _rncController.text = cfg.rnc;
    _direccionController.text = cfg.direccion;
    _telefonoController.text = cfg.telefono;
    _correoController.text = cfg.correo;
    _itbisController.text = cfg.impuestoPorcentaje.toString();
    _monedaSeleccionada = cfg.moneda.contains('DOP') ? 'DOP' : cfg.moneda;
    _idiomaSeleccionado = cfg.idioma;
    _logoPath = cfg.logoUrl.isEmpty ? null : cfg.logoUrl;
    _docLogo = cfg.docMostrarLogo;
    _docRnc = cfg.docMostrarRnc;
    _docDireccion = cfg.docMostrarDireccion;
    _docTelefono = cfg.docMostrarTelefono;
    _docCorreo = cfg.docMostrarCorreo;
    _docNcf = cfg.docMostrarNcf;
    _docCliente = cfg.docMostrarCliente;
    _docItbisDesglose = cfg.docMostrarItbisDesglose;
    _pieController.text = cfg.docPiePagina;
    _prefijoContadoController.text = cfg.prefijoContado;
    _prefijoCreditoController.text = cfg.prefijoCredito;
    _cajaFormaPagoDefault = cfg.cajaFormaPagoDefault;
    _cajaPermitirTarjeta = cfg.cajaPermitirTarjeta;
    _cajaPermitirTransferencia = cfg.cajaPermitirTransferencia;
    _cajaPermitirCheque = cfg.cajaPermitirCheque;
    _cajaExigirSesion = cfg.cajaExigirSesion;
    _modoSimplificado = cfg.modoSimplificado;
    _datosCargados = true;
  }

  bool _validarEmpresa() {
    final nombre = _nombreController.text.trim();
    final rnc = _rncController.text.trim();
    final itbis = double.tryParse(_itbisController.text.trim());
    final correo = _correoController.text.trim();
    if (nombre.isEmpty || nombre.length > 120) return false;
    if (rnc.isEmpty || rnc.length < 9 || rnc.length > 13) return false;
    if (itbis == null || itbis < 0 || itbis > 100) return false;
    if (correo.isNotEmpty &&
        !RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(correo)) {
      return false;
    }
    return true;
  }

  Future<void> _elegirLogo() async {
    try {
      String? sourcePath;
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null &&
          result.files.isNotEmpty &&
          (result.files.single.path?.isNotEmpty ?? false)) {
        sourcePath = result.files.single.path;
      }
      if (sourcePath == null) return;

      final dir = await getApplicationDocumentsDirectory();
      final logosDir = Directory(p.join(dir.path, 'logos'));
      if (!await logosDir.exists()) {
        await logosDir.create(recursive: true);
      }
      final ext = p.extension(sourcePath).isEmpty
          ? '.jpg'
          : p.extension(sourcePath);
      final dest = File(p.join(logosDir.path, 'logo_negocio$ext'));
      await File(sourcePath).copy(dest.path);
      if (!mounted) return;
      setState(() => _logoPath = dest.path);
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('Logo listo. Pulsa Guardar para persistirlo.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(content: Text('No se pudo cargar el logo: $e')),
      );
    }
  }

  Future<void> _guardarEmpresa() async {
    // Form solo existe en sección Empresa; en Ventas/Documentos no validar Form
    final form = _formKey.currentState;
    if (form != null && !form.validate()) return;
    if (_seccion == _SeccionConfig.empresa && !_validarEmpresa()) return;
    setState(() => _guardando = true);
    final entity = ConfiguracionEntity(
      id: '1',
      nombreComercial: _nombreController.text.trim(),
      razonSocial: _nombreController.text.trim(),
      rnc: _rncController.text.trim(),
      direccion: _direccionController.text.trim(),
      telefono: _telefonoController.text.trim(),
      correo: _correoController.text.trim(),
      logoUrl: _logoPath ?? '',
      moneda: _monedaSeleccionada,
      zonaHoraria: 'America/Santo_Domingo',
      formatoImpresion: 'Ticket 80mm',
      formatoFecha: 'DD/MM/YYYY',
      impuestoPorcentaje: double.tryParse(_itbisController.text.trim()) ?? 18.0,
      idioma: _idiomaSeleccionado,
      docMostrarLogo: _docLogo,
      docMostrarRnc: _docRnc,
      docMostrarDireccion: _docDireccion,
      docMostrarTelefono: _docTelefono,
      docMostrarCorreo: _docCorreo,
      docMostrarNcf: _docNcf,
      docMostrarCliente: _docCliente,
      docMostrarItbisDesglose: _docItbisDesglose,
      docPiePagina: _pieController.text.trim().isEmpty
          ? 'Gracias por su preferencia'
          : _pieController.text.trim(),
      prefijoContado: _prefijoContadoController.text.trim().isEmpty
          ? 'C'
          : _prefijoContadoController.text.trim(),
      prefijoCredito: _prefijoCreditoController.text.trim().isEmpty
          ? 'CR'
          : _prefijoCreditoController.text.trim(),
      cajaFormaPagoDefault: _cajaFormaPagoDefault,
      cajaPermitirTarjeta: _cajaPermitirTarjeta,
      cajaPermitirTransferencia: _cajaPermitirTransferencia,
      cajaPermitirCheque: _cajaPermitirCheque,
      cajaExigirSesion: _cajaExigirSesion,
      modoSimplificado: _modoSimplificado,
    );
    try {
      await ref.read(configuracionControllerProvider.notifier).guardar(entity);
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: const Text('Configuración de empresa guardada'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.allM),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _guardarDocumentos() async {
    // Reutiliza guardar empresa con flags actuales de documentos
    await _guardarEmpresa();
  }

  @override
  Widget build(BuildContext context) {
    final asyncCfg = ref.watch(configuracionControllerProvider);
    // Carga única sin listen (evita freeze al hacer pop)
    if (!_datosCargados && asyncCfg.hasValue && asyncCfg.value != null) {
      final cfg = asyncCfg.value!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _datosCargados) return;
        setState(() => _aplicarConfig(cfg));
      });
    }

    final isMobile = AppBreakpoints.isMobile(context);

    return AppScaffold(
      title: 'Configuración Global',
      subtitle: 'Mantenimiento de parámetros del sistema y documentos',
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
      body: asyncCfg.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (_) => isMobile ? _buildMobile() : _buildDesktop(),
      ),
    );
  }

  Widget _buildDesktop() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sidebar unificada
        Container(
          width: 248,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              right: BorderSide(color: AppColors.border.withValues(alpha: 0.9)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                child: Text(
                  'SECCIONES',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ..._itemsMenu(),
            ],
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: _contenidoSeccion(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobile() {
    final secciones = _SeccionConfig.values.where((s) {
      if (!_modoSimplificado) return true;
      return s != _SeccionConfig.ncf && s != _SeccionConfig.impuestos;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Chips de sección (misma identidad que el resto de la app)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: secciones.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final s = secciones[i];
                final sel = s == _seccion;
                return FilterChip(
                  selected: sel,
                  showCheckmark: false,
                  avatar: Icon(
                    _iconoSeccion(s),
                    size: 16,
                    color: sel ? AppColors.primary : AppColors.textSecondary,
                  ),
                  label: Text(_tituloSeccion(s)),
                  labelStyle: AppTypography.labelMedium.copyWith(
                    color: sel ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  ),
                  selectedColor: AppColors.primary.withValues(alpha: 0.14),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: sel
                        ? AppColors.primary.withValues(alpha: 0.45)
                        : AppColors.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onSelected: (_) => setState(() => _seccion = s),
                );
              },
            ),
          ),
        ),
        Divider(height: 1, color: AppColors.border.withValues(alpha: 0.8)),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: _contenidoSeccion(),
          ),
        ),
      ],
    );
  }

  List<Widget> _itemsMenu() {
    final secciones = _SeccionConfig.values.where((s) {
      if (!_modoSimplificado) return true;
      return s != _SeccionConfig.ncf && s != _SeccionConfig.impuestos;
    });
    return secciones.map((s) {
      final sel = s == _seccion;
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Material(
          color: sel ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _seccion = s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: sel
                    ? Border.all(color: AppColors.primary.withValues(alpha: 0.25))
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.grey50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _iconoSeccion(s),
                      color: sel ? AppColors.primary : AppColors.grey600,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _tituloSeccion(s),
                      style: AppTypography.labelMedium.copyWith(
                        color: sel ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  String _tituloSeccion(_SeccionConfig s) {
    switch (s) {
      case _SeccionConfig.empresa:
        return 'Empresa';
      case _SeccionConfig.documentos:
        return 'Documentos';
      case _SeccionConfig.ventas:
        return 'Ventas';
      case _SeccionConfig.caja:
        return 'Caja';
      case _SeccionConfig.credito:
        return 'Crédito';
      case _SeccionConfig.ncf:
        return 'NCF / Secuencias';
      case _SeccionConfig.impuestos:
        return 'Impuestos';
      case _SeccionConfig.sistema:
        return 'Sistema';
    }
  }

  IconData _iconoSeccion(_SeccionConfig s) {
    switch (s) {
      case _SeccionConfig.empresa:
        return Icons.storefront_outlined;
      case _SeccionConfig.documentos:
        return Icons.description_outlined;
      case _SeccionConfig.ventas:
        return Icons.point_of_sale_outlined;
      case _SeccionConfig.caja:
        return Icons.payments_outlined;
      case _SeccionConfig.credito:
        return Icons.account_balance_wallet_outlined;
      case _SeccionConfig.ncf:
        return Icons.tag_outlined;
      case _SeccionConfig.impuestos:
        return Icons.receipt_long_outlined;
      case _SeccionConfig.sistema:
        return Icons.settings_outlined;
    }
  }

  Widget _contenidoSeccion() {
    switch (_seccion) {
      case _SeccionConfig.empresa:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _seccionEmpresa(),
            AppLayout.vL,
            _seccionEmpresaModoSimplificadoCard(),
          ],
        );
      case _SeccionConfig.documentos:
        return _seccionDocumentos();
      case _SeccionConfig.ventas:
        return _seccionVentas();
      case _SeccionConfig.caja:
        return _seccionCaja();
      case _SeccionConfig.credito:
        return _seccionEnlace(
          titulo: 'Crédito / Cuentas por cobrar',
          descripcion:
              'Tasa, cuotas, plazo máximo, días de gracia, mora y plantillas PDF.',
          boton: 'Configuración de crédito',
          onTap: () => context.push('/creditos/config'),
        );
      case _SeccionConfig.ncf:
        return _seccionEnlace(
          titulo: 'NCF y secuencias',
          descripcion: 'Rangos B01 / B02 y numeración fiscal.',
          boton: 'Abrir secuencias NCF',
          onTap: () {
            context.push('/sales/secuencias-ncf');
          },
        );
      case _SeccionConfig.impuestos:
        return _seccionEnlace(
          titulo: 'Impuestos e ITBIS',
          descripcion: 'Configuración tributaria e ITBIS del sistema.',
          boton: 'Abrir impuestos',
          onTap: () => context.push('/impuestos'),
        );
      case _SeccionConfig.sistema:
        return _seccionSistema();
    }
  }

  Widget _seccionEmpresa() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final narrow = c.maxWidth < 480;
              final title = Text(
                'Empresa y fiscal',
                style: AppTypography.h3.copyWith(fontWeight: FontWeight.w800),
              );
              final btn = AppButton(
                text: _guardando ? 'Guardando...' : 'Guardar',
                icon: Icons.save_rounded,
                onPressed: _validarEmpresa() && !_guardando
                    ? _guardarEmpresa
                    : null,
              );
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    title,
                    const SizedBox(height: 12),
                    btn,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: title),
                  btn,
                ],
              );
            },
          ),
          AppLayout.vS,
          Text(
            'Datos del emisor en facturas, tickets y reportes.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppLayout.vL,
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Identidad', style: AppTypography.h4),
                AppLayout.vM,
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _elegirLogo,
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: AppColors.grey300,
                          backgroundImage:
                              (_logoPath != null &&
                                  _logoPath!.isNotEmpty &&
                                  File(_logoPath!).existsSync())
                              ? FileImage(File(_logoPath!))
                              : null,
                          child:
                              (_logoPath == null ||
                                  _logoPath!.isEmpty ||
                                  !File(_logoPath!).existsSync())
                              ? const Icon(Icons.add_a_photo, size: 32)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _elegirLogo,
                        icon: const Icon(Icons.image_outlined, size: 18),
                        label: Text(
                          _logoPath == null || _logoPath!.isEmpty
                              ? 'Subir logo del negocio'
                              : 'Cambiar logo',
                        ),
                      ),
                    ],
                  ),
                ),
                AppLayout.vM,

                AppTextField(
                  label: 'Nombre comercial *',
                  controller: _nombreController,
                  onChanged: (_) => setState(() {}),
                ),
                AppLayout.vM,
                AppTextField(
                  label: 'RNC / Cédula *',
                  controller: _rncController,
                  onChanged: (_) => setState(() {}),
                ),
                AppLayout.vM,
                AppTextField(
                  label: 'Dirección',
                  controller: _direccionController,
                  onChanged: (_) => setState(() {}),
                ),
                AppLayout.vM,
                AppTextField(
                  label: 'Teléfono',
                  controller: _telefonoController,
                  onChanged: (_) => setState(() {}),
                ),
                AppLayout.vM,
                AppTextField(
                  label: 'Correo',
                  controller: _correoController,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          AppLayout.vL,
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Parámetros', style: AppTypography.h4),
                AppLayout.vM,
                AppTextField(
                  label: 'ITBIS (%) *',
                  controller: _itbisController,
                  onChanged: (_) => setState(() {}),
                ),
                AppLayout.vM,
                AppDropdown<String>(
                  label: 'Moneda',
                  initialValue: _monedaSeleccionada,
                  items: const [
                    DropdownMenuItem(value: 'DOP', child: Text('DOP (RD\$)')),
                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _monedaSeleccionada = v);
                  },
                ),
                AppLayout.vM,
                AppDropdown<String>(
                  label: 'Idioma',
                  initialValue: _idiomaSeleccionado,
                  items: const [
                    DropdownMenuItem(value: 'Español', child: Text('Español')),
                    DropdownMenuItem(value: 'English', child: Text('English')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _idiomaSeleccionado = v);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _seccionDocumentos() {
    Widget switchCampo(
      String titulo,
      bool valor,
      ValueChanged<bool> onChanged,
    ) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                titulo,
                style: AppTypography.labelMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Switch.adaptive(
              value: valor,
              activeThumbColor: AppColors.primary,
              onChanged: onChanged,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          LayoutBuilder(
            builder: (context, c) {
              final narrow = c.maxWidth < 420;
              final titleW = Text(
                'Documentos e impresión',
                style: AppTypography.h3.copyWith(fontWeight: FontWeight.w800),
              );
              final btn = AppButton(
                text: _guardando ? 'Guardando...' : 'Guardar',
                icon: Icons.save_rounded,
                onPressed: _guardando ? null : _guardarDocumentos,
              );
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    titleW,
                    const SizedBox(height: 12),
                    btn,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: titleW),
                  const SizedBox(width: 12),
                  Flexible(child: btn),
                ],
              );
            },
          ),
        AppLayout.vS,
        Text(
          'Campos visibles en la factura / ticket que emite caja. '
          'Activa o desactiva según tu operación.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        AppLayout.vL,
        LayoutBuilder(
          builder: (context, c) {
            final ancho = c.maxWidth;
            final preview = AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vista previa (ticket)', style: AppTypography.h4),
                  const Divider(),
                  if (_docLogo)
                    const Center(
                      child: Icon(
                        Icons.store,
                        size: 36,
                        color: AppColors.primary,
                      ),
                    ),
                  Center(
                    child: Text(
                      _nombreController.text.isEmpty
                          ? 'Nombre del negocio'
                          : _nombreController.text,
                      style: AppTypography.labelLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (_docRnc)
                    Center(
                      child: Text(
                        'RNC: ${_rncController.text.isEmpty ? '—' : _rncController.text}',
                        style: AppTypography.bodySmall,
                      ),
                    ),
                  if (_docDireccion && _direccionController.text.isNotEmpty)
                    Center(
                      child: Text(
                        _direccionController.text,
                        style: AppTypography.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_docTelefono && _telefonoController.text.isNotEmpty)
                    Center(
                      child: Text(
                        'Tel: ${_telefonoController.text}',
                        style: AppTypography.bodySmall,
                      ),
                    ),
                  const Divider(),
                  if (_docCliente)
                    const Text(
                      'Cliente: Consumidor Final',
                      style: AppTypography.bodySmall,
                    ),
                  if (_docNcf)
                    const Text(
                      'NCF: B0200000001',
                      style: AppTypography.bodySmall,
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'Producto ejemplo × 1',
                    style: AppTypography.bodySmall,
                  ),
                  const Text('RD\$ 1,000.00', style: AppTypography.bodySmall),
                  const Divider(),
                  if (_docItbisDesglose) ...[
                    const Text(
                      'Subtotal  RD\$ 847.46',
                      style: AppTypography.bodySmall,
                    ),
                    const Text(
                      'ITBIS    RD\$ 152.54',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                  const Text(
                    'TOTAL    RD\$ 1,000.00',
                    style: AppTypography.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _pieController.text,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );

            final form = AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Campos del comprobante', style: AppTypography.h4),
                  switchCampo(
                    'Logo',
                    _docLogo,
                    (v) => setState(() => _docLogo = v),
                  ),
                  switchCampo(
                    'RNC del emisor',
                    _docRnc,
                    (v) => setState(() => _docRnc = v),
                  ),
                  switchCampo(
                    'Dirección',
                    _docDireccion,
                    (v) => setState(() => _docDireccion = v),
                  ),
                  switchCampo(
                    'Teléfono',
                    _docTelefono,
                    (v) => setState(() => _docTelefono = v),
                  ),
                  switchCampo(
                    'Correo',
                    _docCorreo,
                    (v) => setState(() => _docCorreo = v),
                  ),
                  switchCampo(
                    'NCF',
                    _docNcf,
                    (v) => setState(() => _docNcf = v),
                  ),
                  switchCampo(
                    'Datos del cliente',
                    _docCliente,
                    (v) => setState(() => _docCliente = v),
                  ),
                  switchCampo(
                    'Desglose ITBIS',
                    _docItbisDesglose,
                    (v) => setState(() => _docItbisDesglose = v),
                  ),
                  AppLayout.vM,
                  AppTextField(
                    label: 'Pie de página',
                    controller: _pieController,
                    onChanged: (_) => setState(() {}),
                  ),
                  AppLayout.vM,
                  Text(
                    'La persistencia de estos switches se enlazará al PDF/ticket en el siguiente paso.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );

            if (ancho > 700) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: form),
                  AppLayout.hL,
                  Expanded(flex: 4, child: preview),
                ],
              );
            }
            return Column(children: [form, AppLayout.vL, preview]);
          },
        ),
      ],
    );
  }

  Widget _seccionCaja() {
    Widget filaSwitch(String titulo, bool valor, ValueChanged<bool> onChanged) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                titulo,
                style: AppTypography.labelMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Switch.adaptive(
              value: valor,
              activeThumbColor: AppColors.primary,
              onChanged: onChanged,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          LayoutBuilder(
            builder: (context, c) {
              final narrow = c.maxWidth < 420;
              final titleW = Text(
                'Caja',
                style: AppTypography.h3.copyWith(fontWeight: FontWeight.w800),
              );
              final btn = AppButton(
                text: _guardando ? 'Guardando...' : 'Guardar',
                icon: Icons.save_rounded,
                onPressed: _guardando ? null : _guardarEmpresa,
              );
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    titleW,
                    const SizedBox(height: 12),
                    btn,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: titleW),
                  const SizedBox(width: 12),
                  Flexible(child: btn),
                ],
              );
            },
          ),
        AppLayout.vS,
        Text(
          'Formas de pago y reglas al cobrar en caja.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        AppLayout.vL,
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Forma de pago por defecto', style: AppTypography.h4),
              AppLayout.vM,
              Wrap(
                spacing: 8,
                children: [
                  for (final e in const [
                    ('efectivo', 'Efectivo'),
                    ('tarjeta', 'Tarjeta'),
                    ('transferencia', 'Transferencia'),
                  ])
                    ChoiceChip(
                      label: Text(e.$2),
                      selected: _cajaFormaPagoDefault == e.$1,
                      onSelected: (_) =>
                          setState(() => _cajaFormaPagoDefault = e.$1),
                    ),
                ],
              ),
            ],
          ),
        ),
        AppLayout.vM,
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Métodos habilitados', style: AppTypography.h4),
              AppLayout.vS,
              filaSwitch('Tarjeta', _cajaPermitirTarjeta, (v) {
                setState(() => _cajaPermitirTarjeta = v);
              }),
              filaSwitch('Transferencia', _cajaPermitirTransferencia, (v) {
                setState(() => _cajaPermitirTransferencia = v);
              }),
              filaSwitch('Cheque', _cajaPermitirCheque, (v) {
                setState(() => _cajaPermitirCheque = v);
              }),
            ],
          ),
        ),
        AppLayout.vM,
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sesión de caja', style: AppTypography.h4),
              AppLayout.vS,
              filaSwitch(
                'Exigir sesión abierta para cobrar',
                _cajaExigirSesion,
                (v) => setState(() => _cajaExigirSesion = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _seccionVentas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          LayoutBuilder(
            builder: (context, c) {
              final narrow = c.maxWidth < 420;
              final titleW = Text(
                'Ventas y cotizaciones',
                style: AppTypography.h3.copyWith(fontWeight: FontWeight.w800),
              );
              final btn = AppButton(
                text: _guardando ? 'Guardando...' : 'Guardar',
                icon: Icons.save_rounded,
                onPressed: _guardando ? null : _guardarEmpresa,
              );
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    titleW,
                    const SizedBox(height: 12),
                    btn,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: titleW),
                  const SizedBox(width: 12),
                  Flexible(child: btn),
                ],
              );
            },
          ),
        AppLayout.vS,
        Text(
          'Prefijos del número de cotización (Contado / Crédito).',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        AppLayout.vL,
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Numeración', style: AppTypography.h4),
              AppLayout.vM,
              AppTextField(
                label: 'Prefijo contado',
                hint: 'C',
                controller: _prefijoContadoController,
                onChanged: (_) => setState(() {}),
              ),
              AppLayout.vM,
              AppTextField(
                label: 'Prefijo crédito',
                hint: 'CR',
                controller: _prefijoCreditoController,
                onChanged: (_) => setState(() {}),
              ),
              AppLayout.vS,
              Text(
                'Ejemplo: ${_prefijoContadoController.text}-000001 · ${_prefijoCreditoController.text}-000001',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _seccionEmpresaModoSimplificadoCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Modo simplificado', style: AppTypography.h4),
          AppLayout.vS,
          Text(
            'Oculta NCF e ITBIS en pantallas y documentos. '
            'Ideal para operación interna o sin facturación fiscal.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppLayout.vS,
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Activar modo simplificado',
                  style: AppTypography.labelMedium,
                ),
              ),
              Switch.adaptive(
                value: _modoSimplificado,
                activeThumbColor: AppColors.primary,
                onChanged: (v) {
                  setState(() => _modoSimplificado = v);
                  // UI inmediata; Guardar confirma en BD
                  ref.read(modoSimplificadoCacheProvider.notifier).state = v;
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _seccionSistema() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sistema', style: AppTypography.h3),
          AppLayout.vM,
          Material(
            color: const Color(0xFF0F766E).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFF0F766E), width: 1.2),
              ),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF0F766E),
                child: Icon(Icons.workspace_premium, color: Colors.white, size: 22),
              ),
              title: const Text(
                'Licencia y pagos',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F766E),
                ),
              ),
              subtitle: Text(
                storeOcultaCompraTransferencia
                    ? 'Plan activo · Activar con codigo · Tienda'
                    : 'Elige tu plan · Toke o transferencia · Referencia FG-',
              ),
              trailing:
                  const Icon(Icons.chevron_right, color: Color(0xFF0F766E)),
              onTap: () => context.push('/licencia'),
            ),
          ),
          const SizedBox(height: 4),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacidad'),
            subtitle: const Text('Datos locales y politica del software'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/legal/privacidad'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('Terminos de uso'),
            subtitle: const Text('Licencia de uso del software'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/legal/terminos'),
          ),
          const SizedBox(height: 8),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('FiscoGest RD v3.0 Pro'),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.storage_outlined),
            title: Text('Base de datos'),
            subtitle: Text('SQLite local (Drift)'),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.schedule_outlined),
            title: Text('Zona horaria'),
            subtitle: Text('America/Santo_Domingo'),
          ),
        ],
      ),
    );
  }

  Widget _seccionEnlace({
    required String titulo,
    required String descripcion,
    required String boton,
    required VoidCallback onTap,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titulo, style: AppTypography.h3),
          AppLayout.vS,
          Text(descripcion, style: AppTypography.bodyMedium),
          AppLayout.vL,
          // Ancho completo evita overflow del Row interno del AppButton en móvil
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: boton,
              icon: Icons.open_in_new,
              onPressed: onTap,
            ),
          ),
        ],
      ),
    );
  }
}
