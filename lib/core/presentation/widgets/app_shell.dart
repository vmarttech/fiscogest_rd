import 'package:fiscogest_rd/core/services/update_checker.dart';
import 'dart:io';
import 'package:fiscogest_rd/features/configuracion/presentation/providers/configuracion_providers.dart';
import 'package:fiscogest_rd/core/auth/sesion_provider.dart';
import 'package:fiscogest_rd/core/auth/permisos_roles.dart';
import 'package:flutter/material.dart';
import 'package:fiscogest_rd/features/notificaciones/presentation/campana_notificaciones.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/presentation/widgets/shell_drawer_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/features/licencias/presentation/providers/licencia_providers.dart';
import 'package:fiscogest_rd/features/licencias/presentation/providers/pedidos_pendientes_provider.dart';
import 'package:fiscogest_rd/core/auth/dueno_plataforma.dart';
import 'package:fiscogest_rd/features/licencias/domain/licencia_gates.dart';
import 'package:fiscogest_rd/core/sync/supabase/sesion_nube.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  // Ancho del menú fijo en escritorio (Opción 1)
  static const double _sidebarWidth = 200.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modoSimplificado = ref.watch(modoSimplificadoProvider);
    final sesion = ref.watch(sesionProvider);
    if (sesion != null && !UpdateChecker.promptsEnabled) {
      UpdateChecker.promptsEnabled = true;
    }
    if (sesion != null && !_UpdatePromptGate.done) {
      _UpdatePromptGate.done = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(const Duration(milliseconds: 600), () {
          if (context.mounted && UpdateChecker.promptsEnabled) {
            UpdateChecker.checkAndPrompt(context);
          }
        });
      });
    }

    final esAdmin = sesion?.esAdmin ?? false;
    final pendientesAsync = ref.watch(pedidosPendientesCountProvider);
    final pedidosPendientes = pendientesAsync.maybeWhen(
      data: (n) => n,
      orElse: () => 0,
    );
    final rolNorm = (sesion?.rol ?? '').toLowerCase().trim();
    final esVendedor = rolNorm.contains('vendedor');
    final esCajero = rolNorm.contains('cajero');
    // Label limpio y corto para el menú
    final operadorLabel = sesion == null
        ? 'Sin sesión'
        : (sesion.nombre.isNotEmpty 
            ? sesion.nombre.split(' ').first 
            : sesion.username);
    final cfg = ref.watch(configuracionControllerProvider).valueOrNull;
    final nombreEmpresa = (cfg?.nombreComercial.trim().isNotEmpty == true)
        ? cfg!.nombreComercial.trim()
        : 'Mi negocio';
    final rncEmpresa = (cfg?.rnc.trim().isNotEmpty == true)
        ? cfg!.rnc.trim()
        : '';
    final direccionEmpresa = (cfg?.direccion.trim().isNotEmpty == true)
        ? cfg!.direccion.trim()
        : '';

    final gatesLic = ref
        .watch(licenciaActualProvider)
        .maybeWhen(
          data: (lic) => LicenciaGates(lic),
          orElse: () => const LicenciaGates(null),
        );
    final permiteFiscalLicencia = gatesLic.permiteFiscal;
    final permiteFiaoLicencia = gatesLic.permiteFiao;
    final permiteCreditoFormalLicencia = gatesLic.permiteCreditoFormal;
    final permiteAlmacenesLicencia = gatesLic.permiteAlmacenes;

    final currentPath = GoRouterState.of(context).uri.path;
    // Tablet horizontal y ≥900: mismo chrome que escritorio (evita desbordes del layout móvil).
    final isDesktop = AppBreakpoints.useWideChrome(context);

    // ─────────────────────────────────────────────
    // ESCRITORIO → Menú fijo + Header
    // ─────────────────────────────────────────────
    if (isDesktop) {
      // Mock: sidebar altura completa + header claro solo sobre el contenido
      return Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMenu(
              width: _sidebarWidth,
              currentPath: currentPath,
              context: context,
              nombreEmpresa: nombreEmpresa,
              logoUrl: (cfg?.logoUrl.trim().isNotEmpty == true) ? cfg!.logoUrl.trim() : '',
              modoSimplificado: modoSimplificado,
              esAdmin: esAdmin,
              esVendedor: esVendedor,
              esCajero: esCajero,
              operadorLabel: operadorLabel,
              rolUsuario: sesion?.rol ?? '',
              usernameSesion: sesion?.username ?? '',
              onLogout: () {
                UpdateChecker.promptsEnabled = false;
      ref.read(sesionProvider.notifier).state = null;
                SesionNube.clear();
                context.go('/login');
              },
              permiteFiscalLicencia: permiteFiscalLicencia,
              permiteFiaoLicencia: permiteFiaoLicencia,
              permiteCreditoFormalLicencia: permiteCreditoFormalLicencia,
              permiteAlmacenesLicencia: permiteAlmacenesLicencia,
              pedidosPendientes: pedidosPendientes,
              isPermanent: true,
              hideBrandHeader: false,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDesktopHeader(
                    context: context,
                    ref: ref,
                    nombreEmpresa: nombreEmpresa,
                    rncEmpresa: rncEmpresa,
                    direccionEmpresa: direccionEmpresa,
                    operadorLabel: operadorLabel,
                    onLogout: () {
                      UpdateChecker.promptsEnabled = false;
      ref.read(sesionProvider.notifier).state = null;
                      SesionNube.clear();
                      context.go('/login');
                    },
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ─────────────────────────────────────────────
    // MÓVIL / TABLET → Drawer (comportamiento actual)
    // ─────────────────────────────────────────────
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      drawer: Builder(
        builder: (drawerCtx) {
          final screenW = MediaQuery.sizeOf(drawerCtx).width;
          final drawerW = (screenW * 0.85).clamp(220.0, 280.0);
          return SizedBox(
            width: drawerW,
            child: _buildMenu(
              width: drawerW,
              currentPath: currentPath,
              context: context,
              nombreEmpresa: nombreEmpresa,
              logoUrl: (cfg?.logoUrl.trim().isNotEmpty == true)
                  ? cfg!.logoUrl.trim()
                  : '',
              modoSimplificado: modoSimplificado,
              esAdmin: esAdmin,
              esVendedor: esVendedor,
              esCajero: esCajero,
              operadorLabel: operadorLabel,
              rolUsuario: sesion?.rol ?? '',
              usernameSesion: sesion?.username ?? '',
              onLogout: () {
                UpdateChecker.promptsEnabled = false;
      ref.read(sesionProvider.notifier).state = null;
                SesionNube.clear();
                context.go('/login');
              },
              permiteFiscalLicencia: permiteFiscalLicencia,
              permiteFiaoLicencia: permiteFiaoLicencia,
              permiteCreditoFormalLicencia: permiteCreditoFormalLicencia,
              permiteAlmacenesLicencia: permiteAlmacenesLicencia,
              pedidosPendientes: pedidosPendientes,
              isPermanent: false,
            ),
          );
        },
      ),
      body: Builder(
        builder: (scaffoldContext) {
          return ShellDrawerScope(
            openDrawer: () {
              final s = Scaffold.maybeOf(scaffoldContext);
              if (s != null && s.hasDrawer) s.openDrawer();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: child),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HEADER SUPERIOR (solo escritorio)
  // ─────────────────────────────────────────────
  Widget _buildDesktopHeader({
    required BuildContext context,
    required WidgetRef ref,
    required String nombreEmpresa,
    required String rncEmpresa,
    required String direccionEmpresa,
    required String operadorLabel,
    required VoidCallback onLogout,
  }) {
    final rnc = rncEmpresa;
    final fecha = DateFormat("EEEE, d 'de' MMMM yyyy", 'es').format(DateTime.now());
    final fechaCap = fecha.isEmpty ? fecha : '${fecha[0].toUpperCase()}${fecha.substring(1)}';

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // mismo que sidebar navy-900
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Company chip (HTML enterprise)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.business_outlined, size: 15, color: Color(0xFF60A5FA)),
                const SizedBox(width: 8),
                Text(
                  nombreEmpresa,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                if (rnc.isNotEmpty) ...[
                  const Text('  •  ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  Text(
                    'RNC: $rnc',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Search
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: SizedBox(
                height: 40,
                child: TextField(
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar clientes, facturas, e-CF, créditos...',
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          // Date
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Text(
                fechaCap,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFCBD5E1),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Sistema Operativo badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Sistema Operativo',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF047857),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Campana de alertas operativas
          const CampanaNotificaciones(),
          const SizedBox(width: 4),
          // Exportar Resumen
          FilledButton.icon(
            onPressed: () => context.push('/reports'),
            icon: const Icon(Icons.download_outlined, size: 16),
            label: const Text(
              'Exportar Resumen',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildMenu({
    required double width,
    required String currentPath,
    required BuildContext context,
    required String nombreEmpresa,
    required String logoUrl,
    required bool modoSimplificado,
    required bool esAdmin,
    required bool esVendedor,
    required bool esCajero,
    required String operadorLabel,
    required String rolUsuario,
    required String usernameSesion,
    required VoidCallback onLogout,
    bool hideBrandHeader = false,
    required bool permiteFiscalLicencia,
    required bool permiteFiaoLicencia,
    required bool permiteCreditoFormalLicencia,
    required bool permiteAlmacenesLicencia,
    required int pedidosPendientes,
    required bool isPermanent,
  }) {
    final bool modoColmadoFlag =
        modoSimplificado && rolTienePermiso(rolUsuario, Permiso.fiaoUsar);

    bool puede(String permiso) => rolTienePermiso(rolUsuario, permiso);

    // Móvil: degradado teal profundo (barra app → oscuro).
    // Desktop (isPermanent): fondo sidebar actual.
    final menuBg = isPermanent
        ? null
        : const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF00796B), // verde AppBar
                Color(0xFF00695C),
                Color(0xFF004D40),
                Color(0xFF003D36),
                Color(0xFF0A1F1C), // pie profundo
              ],
              stops: [0.0, 0.25, 0.5, 0.75, 1.0],
            ),
          );
    return Material(
      color: isPermanent
          ? AppColors.sidebarBackground
          : Colors.transparent,
      child: Container(
        width: width,
        decoration: menuBg,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── HEADER DEL MENÚ (oculto en desktop: va en barra superior) ───
              if (!hideBrandHeader)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
                child: Row(
                  children: [
                    _buildBusinessLogo(logoUrl, nombreEmpresa),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombreEmpresa,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Gestión Fiscal y Créditos',
                            style: TextStyle(
                              color: Color(0xFF9DB5DA),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                color: isPermanent
                    ? AppColors.divider
                    : Colors.white.withValues(alpha: 0.18),
                height: 1,
              ),

              // ─── ÍTEMS DEL MENÚ ───
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(10, 14, 10, 20),
                  children: [
                    _buildSectionTitle('OPERACIONES'),
                    if (usernameSesion.isEmpty ||
                        usernameSesion.toLowerCase() == 'invitado') ...[
                      _buildNavItem(context, '/setup-cuenta', 'Registro',
                          Icons.person_add_outlined, currentPath, isPermanent),
                      _buildNavItem(context, '/login', 'Iniciar sesión',
                          Icons.login_outlined, currentPath, isPermanent),
                    ],
                    if (puede(Permiso.dashboardVer))
                      _buildNavItem(
                        context,
                        '/',
                        modoColmadoFlag ? 'Inicio' : 'Dashboard',
                        Icons.home_outlined,
                        currentPath,
                        isPermanent,
                      ),
                    if (!modoColmadoFlag &&
                        puede(Permiso.facturacionGestionar))
                      _buildNavItem(
                        context,
                        '/sales',
                        'Facturación y NC',
                        Icons.point_of_sale_outlined,
                        currentPath,
                        isPermanent,
                      ),
                    if (puede(Permiso.ventasCotizar))
                      _buildNavItem(context, '/ventas/cotizaciones/nueva', 'Ventas',
                          Icons.point_of_sale, currentPath, isPermanent),
                    if (puede(Permiso.cajaCobrar) && !AppBreakpoints.isMobile(context))
                      if (!modoSimplificado)
                        _buildNavItem(context, '/ventas/cobro', 'Caja',
                          Icons.payments_outlined, currentPath, isPermanent),
                    if (modoSimplificado &&
                        puede(Permiso.fiaoUsar))
                      _buildNavItem(context, '/ventas/fios', 'Fiao',
                          Icons.edit_note_rounded, currentPath, isPermanent),
                    if (!modoSimplificado &&
                        puede(Permiso.creditosGestionar))
                      _buildNavItem(context, '/creditos', 'Crédito',
                          Icons.credit_score_outlined, currentPath, isPermanent),
                    if (puede(Permiso.comprasGestionar))
                      _buildNavItem(context, '/compras', 'Compras',
                          Icons.shopping_cart_outlined, currentPath, isPermanent),
                    if (puede(Permiso.reportesVer) || esAdmin)
                      _buildNavItem(context, '/gastos', 'Gastos',
                          Icons.money_off_csred_outlined, currentPath, isPermanent),

                    const SizedBox(height: 16),
                    _buildSectionTitle('INVENTARIO'),
                    if (puede(Permiso.inventarioVer))
                      _buildNavItem(context, '/inventario', 'Productos',
                          Icons.inventory_2_outlined, currentPath, isPermanent),
                    if (!modoColmadoFlag && puede(Permiso.kardexVer)) ...[
                      _buildNavItem(context, '/kardex', 'Kárdex',
                          Icons.receipt_long_outlined, currentPath, isPermanent),
                      _buildNavItem(
                          context,
                          '/inventario-fisico',
                          'Inventario Físico',
                          Icons.fact_check_outlined,
                          currentPath,
                          isPermanent),
                      _buildNavItem(context, '/lista-ajustes', 'Ajustes',
                          Icons.tune_outlined, currentPath, isPermanent),
                      _buildNavItem(
                            context,
                            '/transferencias/registrar',
                            'Transferencias',
                            Icons.swap_horiz_outlined,
                            currentPath,
                            isPermanent),
                    ],

                    const SizedBox(height: 16),
                    _buildSectionTitle('CATÁLOGOS'),
                    if (puede(Permiso.clientesVer))
                      _buildNavItem(context, '/clientes', 'Clientes',
                          Icons.people_outline, currentPath, isPermanent),
                    if (puede(Permiso.catalogoGestionar))
                      _buildNavItem(context, '/proveedores', 'Proveedores',
                          Icons.business_outlined, currentPath, isPermanent),
                    if (puede(Permiso.catalogoGestionar))
                      _buildNavItem(context, '/categorias', 'Categorías',
                          Icons.category_outlined, currentPath, isPermanent),
                    if (puede(Permiso.catalogoGestionar))
                      _buildNavItem(context, '/marcas', 'Marcas',
                          Icons.branding_watermark_outlined, currentPath, isPermanent),
                    if (puede(Permiso.catalogoGestionar))
                      _buildNavItem(context, '/unidades', 'Unidades',
                          Icons.straighten_outlined, currentPath, isPermanent),
                    if (puede(Permiso.catalogoGestionar))
                      _buildNavItem(context, '/almacenes', 'Almacenes',
                          Icons.warehouse_outlined, currentPath, isPermanent),
                    if (puede(Permiso.catalogoGestionar))
                      _buildNavItem(context, '/presentaciones', 'Presentaciones',
                          Icons.view_module_outlined, currentPath, isPermanent),

                    const SizedBox(height: 16),
                    _buildSectionTitle('SISTEMA'),
                    if (puede(Permiso.reportesVer) ||
                        modoSimplificado ||
                        esAdmin)
                      _buildNavItem(context, '/reports', 'Reportes',
                          Icons.assessment_outlined, currentPath, isPermanent),
                    if (!modoColmadoFlag && esAdmin) ...[
                      _buildNavItem(context, '/ecfe', 'e-CF · DGII',
                          Icons.cloud_sync_outlined, currentPath, isPermanent),
                      _buildNavItem(context, '/impuestos', 'Impuestos',
                          Icons.calculate_outlined, currentPath, isPermanent),
                      _buildNavItem(context, '/import-export', 'Importar / Exportar',
                          Icons.import_export, currentPath, isPermanent),
                    ],
                    if (puede(Permiso.usuariosGestionar))
                      _buildNavItem(context, '/usuarios', 'Usuarios',
                          Icons.manage_accounts_outlined, currentPath, isPermanent),
                    if (esDuenoPlataforma(usernameSesion))
                      _buildNavItem(
                        context,
                        '/licencia/admin',
                        'Pedidos licencia',
                        Icons.receipt_long_outlined,
                        currentPath,
                        isPermanent,
                        badgeCount: pedidosPendientes,
                      ),
                    _buildNavItem(
                      context,
                      '/licencia/comprar',
                      'Planes y pago',
                      Icons.workspace_premium_outlined,
                      currentPath,
                      isPermanent,
                    ),
                    _buildNavItem(
                      context,
                      '/licencia',
                      'Mi licencia',
                      Icons.verified_outlined,
                      currentPath,
                      isPermanent,
                    ),
                    if (puede(Permiso.configAdmin))
                      _buildNavItem(context, '/configuracion', 'Configuración',
                          Icons.settings_outlined, currentPath, isPermanent),
                    _buildNavAction(
                      context,
                      title: 'Contactar',
                      icon: Icons.mail_outline,
                      isPermanent: isPermanent,
                      onTap: () async {
                        final uri = Uri(
                          scheme: 'mailto',
                          path: 'fiscogestrd@gmail.com',
                          queryParameters: {
                            'subject': 'Contacto FiscoGest',
                          },
                        );
                        try {
                          final ok = await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No hay una app de correo configurada. '
                                  'Escríbenos a fiscogestrd@gmail.com',
                                ),
                              ),
                            );
                          }
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No se pudo abrir el correo. '
                                  'Escríbenos a fiscogestrd@gmail.com',
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                    _buildNavItem(
                      context,
                      '/legal/terminos',
                      'Términos y\ncondiciones',
                      Icons.description_outlined,
                      currentPath,
                      isPermanent,
                    ),
                    _buildNavItem(
                      context,
                      '/legal/privacidad',
                      'Privacidad',
                      Icons.privacy_tip_outlined,
                      currentPath,
                      isPermanent,
                    ),
                    _buildNavAction(
                      context,
                      title: 'Acerca de la App',
                      icon: Icons.info_outline,
                      isPermanent: isPermanent,
                      onTap: () async {
                        final uri = Uri.parse('https://fiscogest-web.web.app');
                        try {
                          final ok = await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No se pudo abrir el sitio. Revisa la conexión o el navegador.',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('No se pudo abrir el enlace: $e'),
                              ),
                            );
                          }
                        }
                      },
                    ),

                    const SizedBox(height: 8),
                    Divider(
                      color: isPermanent
                          ? AppColors.divider
                          : Colors.white.withValues(alpha: 0.15),
                      height: 24,
                    ),
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      // Splash visible sobre sidebar navy (evita assert Flutter)
                      hoverColor: const Color(0x33FFFFFF),
                      splashColor: const Color(0x44FFFFFF),
                      focusColor: const Color(0x22FFFFFF),
                      leading: const Icon(Icons.logout,
                          color: AppColors.grey400, size: 20),
                      title: Text(
                        'Cerrar sesión',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      onTap: onLogout,
                    ),
                  ],
                ),
              ),


            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 7),
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          fontSize: 10,
        ),
      ),
    );
  }


  /// Acción externa (correo / web) con el mismo look del menú lateral.
  Widget _buildNavAction(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isPermanent,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: AppRadius.allM,
          hoverColor: const Color(0x33FFFFFF),
          splashColor: const Color(0x44FFFFFF),
          highlightColor: const Color(0x22FFFFFF),
          onTap: () {
            if (!isPermanent &&
                (Scaffold.maybeOf(context)?.isDrawerOpen ?? false)) {
              Navigator.of(context).pop();
            }
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF9DB5DA), size: 19),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String routePath,
    String title,
    IconData icon,
    String currentPath,
    bool isPermanent, {
    int badgeCount = 0,
  }) {
    final esSeleccionado =
        currentPath == routePath || currentPath.startsWith('$routePath/');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Material(
        color: esSeleccionado
            ? const Color(0xFF1A3A6B) // azul marino (no brillante)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: AppRadius.allM,
          hoverColor: const Color(0x33FFFFFF),
          splashColor: const Color(0x44FFFFFF),
          highlightColor: const Color(0x22FFFFFF),
          onTap: () {
            if (!isPermanent &&
                (Scaffold.maybeOf(context)?.isDrawerOpen ?? false)) {
              Navigator.of(context).pop();
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.push(routePath);
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: esSeleccionado
                      ? Colors.white
                      : const Color(0xFF9DB5DA),
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      height: 1.2,
                    ),
                  ),
                ),
                if (badgeCount > 0) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB91C1C),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                if (esSeleccionado)
                  Container(
                    width: 3.5,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessLogo(String logoUrl, String nombreEmpresa) {
    final tieneLogo = logoUrl.isNotEmpty && File(logoUrl).existsSync();
    final iniciales = nombreEmpresa
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF0F2A52),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFF1E3A6B)),
      ),
      clipBehavior: Clip.antiAlias,
      child: tieneLogo
          ? Image.file(
              File(logoUrl),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  iniciales.isEmpty ? 'FG' : iniciales,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                iniciales.isEmpty ? 'FG' : iniciales,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
    );
  }
}


class _UpdatePromptGate {
  static bool done = false;
}
