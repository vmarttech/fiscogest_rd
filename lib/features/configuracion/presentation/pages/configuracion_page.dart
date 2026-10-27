import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
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
  final _razonSocialController = TextEditingController();
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
  final _transfTituloCtrl = TextEditingController();
  final _transfSubtituloCtrl = TextEditingController();
  final _transfTransportistaCtrl = TextEditingController();
  final _transfObsCtrl = TextEditingController();
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
  bool _transfImprimirManifiesto = true;
  bool _transfMostrarFirmas = true;
  bool _historialColapsado = false;
  final List<String> _historialEntradas = [
    '10:30 - RNC updated',
    'Yesterday - Logo changed',
    'Yesterday - Logo changed',
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    _razonSocialController.dispose();
    _rncController.dispose();
    _itbisController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _pieController.dispose();
    _prefijoContadoController.dispose();
    _prefijoCreditoController.dispose();
    _transfTituloCtrl.dispose();
    _transfSubtituloCtrl.dispose();
    _transfTransportistaCtrl.dispose();
    _transfObsCtrl.dispose();
    super.dispose();
  }

  void _aplicarConfig(ConfiguracionEntity cfg) {
    _nombreController.text = cfg.nombreComercial;
    _razonSocialController.text = cfg.razonSocial;
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
    _transfImprimirManifiesto = cfg.transfImprimirManifiesto;
    _transfMostrarFirmas = cfg.transfMostrarFirmas;
    _transfTituloCtrl.text = cfg.transfTituloManifiesto;
    _transfSubtituloCtrl.text = cfg.transfSubtituloManifiesto;
    _transfTransportistaCtrl.text = cfg.transfTransportistaDefault;
    _transfObsCtrl.text = cfg.transfObservacionesDefault;
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
      transfImprimirManifiesto: _transfImprimirManifiesto,
      transfTituloManifiesto: _transfTituloCtrl.text.trim(),
      transfSubtituloManifiesto: _transfSubtituloCtrl.text.trim(),
      transfTransportistaDefault: _transfTransportistaCtrl.text.trim(),
      transfObservacionesDefault: _transfObsCtrl.text.trim(),
      transfMostrarFirmas: _transfMostrarFirmas,
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
      showAppBar: isMobile,
      title: isMobile ? 'Configuración Global' : null,
      subtitle: isMobile
          ? 'Mantenimiento de parámetros del sistema y documentos'
          : null,
      leading: isMobile
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            )
          : null,
      body: asyncCfg.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (_) => isMobile ? _buildMobile() : _buildDesktop(),
      ),
    );
  }

  Widget _buildDesktop() {
    final secciones = _SeccionConfig.values.toList();

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // —— Tarjetas de sección (mock HTML 8 cards) ——
                    // Una sola fila de 8 tarjetas (mock HTML: min-height ~100px)
                    LayoutBuilder(
                      builder: (context, c) {
                        final w = c.maxWidth;
                        // Forzar 8 en desktop ancho; 4 solo si no caben
                        final cols = w >= 980 ? 8 : (w >= 560 ? 4 : 2);
                        // Más anchas que altas → fila compacta como el mock
                        final ratio = cols == 8 ? 1.35 : (cols == 4 ? 1.2 : 1.4);
                        return GridView.count(
                          crossAxisCount: cols,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 13,
                          crossAxisSpacing: 13,
                          childAspectRatio: ratio,
                          children: [
                            for (final s in secciones)
                              _TarjetaSeccionConfig(
                                icon: _iconoSeccion(s),
                                label: _tituloSeccion(s),
                                selected: s == _seccion,
                                onTap: () => setState(() => _seccion = s),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    _contenidoSeccion(),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Historial flotante (mock)
        Positioned(
          right: 20,
          bottom: 18,
          child: _HistorialModificacionesCard(
            collapsed: _historialColapsado,
            onToggle: () =>
                setState(() => _historialColapsado = !_historialColapsado),
            entradas: _historialEntradas,
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
    InputDecoration fieldDeco({String? hint}) => InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFF77828A),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFCBD2D7)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFCBD2D7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF21877C), width: 1.5),
          ),
        );

    // Contorno con sombra negra 1.5% alrededor del campo
    Widget shadowedField(Widget child) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );
    }

    Widget field(String label, Widget input, {String? hintBelow}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D252B),
            ),
          ),
          const SizedBox(height: 5),
          shadowedField(input),
          if (hintBelow != null) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Text(
                hintBelow,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF77828A),
                ),
              ),
            ),
          ],
        ],
      );
    }

    final hasLogo = _logoPath != null &&
        _logoPath!.isNotEmpty &&
        File(_logoPath!).existsSync();

    return Form(
      key: _formKey,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 420),
        padding: const EdgeInsets.fromLTRB(19, 19, 19, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: const Color(0xFFD8DFE4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // panel-head (compacto en móvil para no romper con el título)
            Builder(
              builder: (context) {
                final isMobile = AppBreakpoints.isMobile(context);
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Identidad',
                        style: TextStyle(
                          fontSize: isMobile ? 17 : 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF17212B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _validarEmpresa() && !_guardando
                          ? () async {
                              await _guardarEmpresa();
                              if (!mounted) return;
                              setState(() {
                                _historialEntradas.insert(
                                  0,
                                  '${TimeOfDay.now().format(context)} - Configuración actualizada',
                                );
                              });
                            }
                          : null,
                      icon: Icon(Icons.save_rounded, size: isMobile ? 16 : 18),
                      label: Text(
                        _guardando
                            ? 'Guardando...'
                            : (isMobile ? 'Guardar' : 'Guardar Cambios'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 13 : 14,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF21877C),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFCBD5E1),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 17,
                          vertical: isMobile ? 8 : 12,
                        ),
                        visualDensity: isMobile
                            ? VisualDensity.compact
                            : VisualDensity.standard,
                        minimumSize: isMobile ? const Size(0, 36) : null,
                        tapTargetSize: isMobile
                            ? MaterialTapTargetSize.shrinkWrap
                            : MaterialTapTargetSize.padded,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(isMobile ? 9 : 11),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 27),
            // form-layout: logo | fields
            LayoutBuilder(
              builder: (context, c) {
                final side = c.maxWidth >= 640;
                final logoCol = Column(
                  children: [
                    const SizedBox(height: 20),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(21),
                            gradient: hasLogo
                                ? null
                                : const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF148779), Color(0xFF07584F)],
                                  ),
                            image: hasLogo
                                ? DecorationImage(
                                    image: FileImage(File(_logoPath!)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0A514B).withValues(alpha: 0.21),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: hasLogo
                              ? null
                              : const Center(
                                  child: Text(
                                    'F',
                                    style: TextStyle(
                                      fontSize: 43,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFE1FFF7),
                                    ),
                                  ),
                                ),
                        ),
                        Positioned(
                          right: -10,
                          top: -10,
                          child: Material(
                            color: const Color(0xFFD8F1ED),
                            shape: const CircleBorder(
                              side: BorderSide(color: Colors.white, width: 2),
                            ),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _elegirLogo,
                              child: const SizedBox(
                                width: 34,
                                height: 34,
                                child: Icon(
                                  Icons.refresh_rounded,
                                  size: 18,
                                  color: Color(0xFF236D65),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    TextButton.icon(
                      onPressed: _elegirLogo,
                      icon: const Icon(Icons.image_outlined, size: 16),
                      label: const Text(
                        'Cambiar logo',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF315A58),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF315A58),
                      ),
                    ),
                  ],
                );

                final fields = Column(
                  children: [
                    // Fila 1: otras funciones (izq) | datos principales (der)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: field(
                            'Moneda',
                            DropdownButtonFormField<String>(
                              key: ValueKey(_monedaSeleccionada),
                              initialValue: _monedaSeleccionada,
                              decoration: fieldDeco(),
                              items: const [
                                DropdownMenuItem(
                                  value: 'DOP',
                                  child: Text(
                                    'DOP (RD\$)',
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'USD',
                                  child: Text(
                                    'USD',
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _monedaSeleccionada = v);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          child: field(
                            'Nombre comercial *',
                            TextFormField(
                              controller: _nombreController,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: fieldDeco(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: field(
                            'ITBIS (%) *',
                            TextFormField(
                              controller: _itbisController,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: fieldDeco(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          child: field(
                            'RNC / Cédula *',
                            TextFormField(
                              controller: _rncController,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: fieldDeco(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    field(
                      'Razón social *',
                      TextFormField(
                        controller: _razonSocialController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: fieldDeco(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    field(
                      'Dirección',
                      TextFormField(
                        controller: _direccionController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: fieldDeco(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    field(
                      'Teléfono',
                      TextFormField(
                        controller: _telefonoController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: fieldDeco(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    field(
                      'Correo',
                      TextFormField(
                        controller: _correoController,
                        onChanged: (_) => setState(() {}),
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: fieldDeco(hint: 'Correo'),
                      ),
                    ),
                  ],
                );

                if (!side) {
                  return Column(
                    children: [
                      logoCol,
                      const SizedBox(height: 20),
                      fields,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 180, child: logoCol),
                    const SizedBox(width: 28),
                    Expanded(child: fields),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }


  /// Panel blanco unificado (mismo estilo que Identidad).
  /// En móvil: título más chico + botón Guardar compacto para no romper el layout.
  Widget _panelSeccion({
    required String titulo,
    required Widget body,
    VoidCallback? onGuardar,
  }) {
    return Builder(
      builder: (context) {
        final isMobile = AppBreakpoints.isMobile(context);
        return Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: isMobile ? 120 : 200),
          padding: EdgeInsets.fromLTRB(
            isMobile ? 14 : 19,
            isMobile ? 14 : 19,
            isMobile ? 14 : 19,
            isMobile ? 20 : 28,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isMobile ? 14 : 19),
            border: Border.all(color: const Color(0xFFD8DFE4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      titulo,
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF17212B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onGuardar != null) ...[
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _guardando ? null : onGuardar,
                      icon: Icon(Icons.save_rounded, size: isMobile ? 16 : 18),
                      label: Text(
                        _guardando
                            ? 'Guardando...'
                            : (isMobile ? 'Guardar' : 'Guardar Cambios'),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: isMobile ? 13 : 14,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF21877C),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFCBD5E1),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 17,
                          vertical: isMobile ? 8 : 12,
                        ),
                        visualDensity: isMobile
                            ? VisualDensity.compact
                            : VisualDensity.standard,
                        minimumSize: isMobile ? const Size(0, 36) : null,
                        tapTargetSize: isMobile
                            ? MaterialTapTargetSize.shrinkWrap
                            : MaterialTapTargetSize.padded,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(isMobile ? 9 : 11),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: isMobile ? 14 : 20),
              body,
            ],
          ),
        );
      },
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

    return _panelSeccion(
      titulo: 'Documentos e impresión',
      onGuardar: _guardarDocumentos,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        const Text(
          'Campos visibles en la factura / ticket que emite caja. '
          'Activa o desactiva según tu operación.',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        const Text(
          'Manifiesto de transferencia (packing list)',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 4),
        const Text(
          'Edita el contenido del PDF que se genera al transferir entre almacenes.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          tileColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Imprimir manifiesto al transferir',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          subtitle: const Text(
            'Si está activo, al completar una transferencia se abre el PDF.',
            style: TextStyle(fontSize: 12),
          ),
          value: _transfImprimirManifiesto,
          activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
          onChanged: (v) => setState(() => _transfImprimirManifiesto = v),
        ),
        if (_transfImprimirManifiesto) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _transfTituloCtrl,
            decoration: const InputDecoration(
              labelText: 'Título del documento',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _transfSubtituloCtrl,
            decoration: const InputDecoration(
              labelText: 'Subtítulo',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _transfTransportistaCtrl,
            decoration: const InputDecoration(
              labelText: 'Transportista / Operador (por defecto)',
              hintText: 'Ej. TransLogística S.A.',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _transfObsCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Observaciones / instrucciones de carga',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
          SwitchListTile.adaptive(
          tileColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Mostrar bloque de firmas',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            subtitle: const Text(
              'Despachado / Transportista / Recibido',
              style: TextStyle(fontSize: 11),
            ),
            value: _transfMostrarFirmas,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
            onChanged: (v) => setState(() => _transfMostrarFirmas = v),
          ),
          const Text(
            'Guarda con el botón de esta sección para aplicar los cambios al próximo manifiesto.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ],
      ),
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

    return _panelSeccion(
      titulo: 'Caja',
      onGuardar: _guardarEmpresa,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        const Text(
          'Formas de pago y reglas al cobrar en caja.',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 16),
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
      ),
    );
  }

  Widget _seccionVentas() {
    return _panelSeccion(
      titulo: 'Ventas y cotizaciones',
      onGuardar: _guardarEmpresa,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        const Text(
          'Prefijos del número de cotización (Contado / Crédito).',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 16),
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
      ),
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
    Widget tile({
      required IconData icon,
      required String title,
      required String subtitle,
      VoidCallback? onTap,
      Color? accent,
    }) {
      final c = accent ?? const Color(0xFF17212B);
      return Material(
        color: Colors.white,
        child: ListTile(
          tileColor: Colors.white,
          selectedTileColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          leading: Icon(icon, color: c),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: c,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          trailing: onTap == null
              ? null
              : Icon(Icons.chevron_right, color: c),
          onTap: onTap,
        ),
      );
    }

    return _panelSeccion(
      titulo: 'Sistema',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: const Color(0xFF0F766E).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            child: ListTile(
              tileColor: const Color(0xFF0F766E).withValues(alpha: 0.10),
              selectedTileColor: const Color(0xFF0F766E).withValues(alpha: 0.14),
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
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing:
                  const Icon(Icons.chevron_right, color: Color(0xFF0F766E)),
              onTap: () => context.push('/licencia'),
            ),
          ),
          const SizedBox(height: 8),
          tile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacidad',
            subtitle: 'Datos locales y politica del software',
            onTap: () => context.push('/legal/privacidad'),
          ),
          tile(
            icon: Icons.gavel_outlined,
            title: 'Terminos de uso',
            subtitle: 'Licencia de uso del software',
            onTap: () => context.push('/legal/terminos'),
          ),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snap) {
              final info = snap.data;
              final label = info == null
                  ? 'Cargando…'
                  : 'FiscoGest RD ${info.version} (${info.buildNumber})';
              return tile(
                icon: Icons.info_outline,
                title: 'Version',
                subtitle: label,
              );
            },
          ),
          tile(
            icon: Icons.storage_outlined,
            title: 'Base de datos',
            subtitle: 'SQLite local (Drift)',
          ),
          tile(
            icon: Icons.schedule_outlined,
            title: 'Zona horaria',
            subtitle: 'America/Santo_Domingo',
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
    return _panelSeccion(
      titulo: titulo,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            descripcion,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(
                boton,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF21877C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}


class _TarjetaSeccionConfig extends StatelessWidget {
  const _TarjetaSeccionConfig({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFD8EEEB) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFFBFD5D2) : const Color(0xFFD5DCE1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 26,
                color: selected ? const Color(0xFF173E3C) : const Color(0xFF101820),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? const Color(0xFF173E3C) : const Color(0xFF101820),
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistorialModificacionesCard extends StatelessWidget {
  const _HistorialModificacionesCard({
    required this.collapsed,
    required this.onToggle,
    required this.entradas,
  });

  final bool collapsed;
  final VoidCallback onToggle;
  final List<String> entradas;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(17),
      color: Colors.white,
      child: Container(
        width: collapsed ? 300 : 360,
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFD8DFE4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Historial de Modificaciones',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF17212B),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onToggle,
                  icon: Icon(
                    collapsed
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (!collapsed) ...[
              const SizedBox(height: 8),
              for (final e in entradas.take(8))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 18,
                        color: Color(0xFF6D7A82),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          e,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF17212B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
