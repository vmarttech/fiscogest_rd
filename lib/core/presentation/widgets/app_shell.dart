import 'package:fiscogest_rd/features/configuracion/presentation/providers/configuracion_providers.dart';
import 'package:fiscogest_rd/core/auth/sesion_provider.dart';
import 'package:fiscogest_rd/core/auth/permisos_roles.dart';
import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/presentation/widgets/shell_drawer_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/features/licencias/presentation/providers/licencia_providers.dart';
import 'package:fiscogest_rd/features/licencias/presentation/providers/pedidos_pendientes_provider.dart';
import 'package:fiscogest_rd/core/auth/dueno_plataforma.dart';
import 'package:fiscogest_rd/features/licencias/domain/licencia_gates.dart';
import 'package:fiscogest_rd/core/sync/supabase/sesion_nube.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  // Ancho del menú fijo en escritorio (Opción 1)
  static const double _sidebarWidth = 200.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modoSimplificado = ref.watch(modoSimplificadoProvider);
    final sesion = ref.watch(sesionProvider);
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
    final isDesktop = AppBreakpoints.isDesktop(context);

    // ─────────────────────────────────────────────
    // ESCRITORIO → Menú fijo + Header
    // ─────────────────────────────────────────────
    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: Column(
          children: [
            // Una sola barra superior a todo el ancho (como la imagen guía)
            _buildDesktopHeader(
              context: context,
              ref: ref,
              nombreEmpresa: nombreEmpresa,
              rncEmpresa: rncEmpresa,
              direccionEmpresa: direccionEmpresa,
              operadorLabel: operadorLabel,
              onLogout: () {
                ref.read(sesionProvider.notifier).state = null;
                SesionNube.clear();
                context.go('/login');
              },
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMenu(
                    width: _sidebarWidth,
                    currentPath: currentPath,
                    context: context,
                    nombreEmpresa: nombreEmpresa,
                    modoSimplificado: modoSimplificado,
                    esAdmin: esAdmin,
                    esVendedor: esVendedor,
                    esCajero: esCajero,
                    operadorLabel: operadorLabel,
                    rolUsuario: sesion?.rol ?? '',
                    usernameSesion: sesion?.username ?? '',
                    onLogout: () {
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
                    hideBrandHeader: true,
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
      drawer: SizedBox(
        width: 280,
        child: _buildMenu(
          width: 280,
          currentPath: currentPath,
          context: context,
          nombreEmpresa: nombreEmpresa,
          modoSimplificado: modoSimplificado,
          esAdmin: esAdmin,
          esVendedor: esVendedor,
          esCajero: esCajero,
          operadorLabel: operadorLabel,
          rolUsuario: sesion?.rol ?? '',
          usernameSesion: sesion?.username ?? '',
          onLogout: () {
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
    final labelCorto = operadorLabel.length > 16
        ? '${operadorLabel.substring(0, 14)}…'
        : operadorLabel;
    final rncText = rncEmpresa.trim();
    final dirText = direccionEmpresa.trim();

    Future<void> ejecutarBusqueda(String raw) async {
      final q = raw.trim();
      if (q.isEmpty) return;
      final qLower = q.toLowerCase();
      try {
        final productos = ref.read(productoControllerProvider).valueOrNull ?? [];
        final matchProd = productos.where((p) {
          final nombre = p.nombre.toLowerCase();
          final codigo = p.codigo.toLowerCase();
          final barras = (p.codigoBarras ?? '').toLowerCase();
          return nombre.contains(qLower) ||
              codigo.contains(qLower) ||
              barras.contains(qLower);
        }).toList();
        if (matchProd.isNotEmpty) {
          final exact = matchProd
              .where((p) => p.nombre.toLowerCase() == qLower)
              .toList();
          final elegido = exact.isNotEmpty ? exact.first : matchProd.first;
          if (context.mounted) {
            context.push('/inventario');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Producto encontrado: ${elegido.nombre}'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
          return;
        }
      } catch (_) {}
      if (qLower.contains('cliente')) {
        context.push('/clientes');
        return;
      }
      if (qLower.contains('venta') ||
          qLower.contains('historial') ||
          qLower.contains('factura') ||
          qLower.contains('cotiz')) {
        context.push('/ventas');
        return;
      }
      if (qLower.contains('inventario') ||
          qLower.contains('producto') ||
          qLower.contains('stock')) {
        context.push('/inventario');
        return;
      }
      if (qLower.contains('credito') ||
          qLower.contains('crédito') ||
          qLower.contains('cxc')) {
        context.push('/creditos');
        return;
      }
      if (qLower.contains('caja')) {
        context.push('/ventas/cobro');
        return;
      }
      context.push('/clientes');
    }

    // Barra superior ÚNICA a todo el ancho — estilo imagen guía
    return Container(
      height: 56,
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Logo producto (como FiscoGest en la guía)
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FiscoGest',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  height: 1.1,
                ),
              ),
              Text(
                'Gestión Fiscal y Créditos',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                  height: 1.2,
                ),
              ),
            ],
          ),
          // Separador
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            width: 1,
            height: 28,
            color: const Color(0xFF334155),
          ),
          // Empresa + RNC + dirección — pegado al buscador
          Flexible(
            flex: 0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 160, maxWidth: 280),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombreEmpresa,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      height: 1.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (rncText.isNotEmpty || dirText.isNotEmpty)
                    Text(
                      [
                        if (rncText.isNotEmpty) 'RNC: $rncText',
                        if (dirText.isNotEmpty) dirText,
                      ].join(' · '),
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        height: 1.25,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Buscador (junto a empresa)
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    cursorColor: const Color(0xFF0F766E),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Buscar clientes, facturas, créditos, productos...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF64748B),
                        size: 18,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF0F766E),
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (q) {
                      final s = q.trim();
                      if (s.length < 2) return;
                      try {
                        final productos =
                            ref.read(productoControllerProvider).valueOrNull ??
                                [];
                        final qLower = s.toLowerCase();
                        final exact = productos
                            .where((p) =>
                                p.nombre.toLowerCase() == qLower ||
                                p.codigo.toLowerCase() == qLower ||
                                (p.codigoBarras ?? '').toLowerCase() == qLower)
                            .toList();
                        if (exact.isNotEmpty) ejecutarBusqueda(s);
                      } catch (_) {}
                    },
                    onSubmitted: (q) => ejecutarBusqueda(q),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sin notificaciones nuevas'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Cuenta',
            offset: const Offset(0, 42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            onSelected: (value) {
              if (value == 'logout') onLogout();
              if (value == 'config') context.push('/configuracion');
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  labelCorto,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'config',
                child: Row(children: [
                  Icon(Icons.settings_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Configuración'),
                ]),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(children: [
                  Icon(Icons.logout, size: 18, color: Color(0xFFDC2626)),
                  SizedBox(width: 8),
                  Text(
                    'Cerrar sesión',
                    style: TextStyle(color: Color(0xFFDC2626)),
                  ),
                ]),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 11,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 90),
                    child: Text(
                      labelCorto,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white70,
                    size: 16,
                  ),
                ],
              ),
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

    return Material(
      color: AppColors.sidebarBackground,
      child: SizedBox(
        width: width,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── HEADER DEL MENÚ (oculto en desktop: va en barra superior) ───
              if (!hideBrandHeader)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        color: AppColors.primaryLight,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombreEmpresa,
                            style: AppTypography.h4.copyWith(
                              color: AppColors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            operadorLabel,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.grey400,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.divider, height: 1),

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
                        permiteFiscalLicencia &&
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
                    if (puede(Permiso.cajaCobrar))
                      _buildNavItem(context, '/ventas/cobro', 'Caja',
                          Icons.payments_outlined, currentPath, isPermanent),
                    if (modoSimplificado &&
                        permiteFiaoLicencia &&
                        puede(Permiso.fiaoUsar))
                      _buildNavItem(context, '/ventas/fios', 'Fiao',
                          Icons.edit_note_rounded, currentPath, isPermanent),
                    if (!modoSimplificado &&
                        permiteCreditoFormalLicencia &&
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
                      if (permiteAlmacenesLicencia)
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
                    if (puede(Permiso.catalogoGestionar) &&
                        permiteAlmacenesLicencia)
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
                    if (!modoColmadoFlag &&
                        esAdmin &&
                        permiteFiscalLicencia) ...[
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
                    if (puede(Permiso.configAdmin))
                      _buildNavItem(context, '/configuracion', 'Configuración',
                          Icons.settings_outlined, currentPath, isPermanent),

                    const SizedBox(height: 8),
                    const Divider(color: AppColors.divider, height: 24),
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      leading: const Icon(Icons.logout,
                          color: AppColors.grey400, size: 20),
                      title: Text(
                        'Cerrar sesión',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.grey300,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      onTap: onLogout,
                    ),
                  ],
                ),
              ),

              // ─── PIE ───
              const Divider(color: AppColors.divider, height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Text(
                  'v3.0 Pro',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.grey500,
                    fontSize: 10.5,
                  ),
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
          color: AppColors.grey400,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          fontSize: 10,
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
            ? AppColors.primary.withValues(alpha: 0.18)
            : Colors.transparent,
        borderRadius: AppRadius.allM,
        child: InkWell(
          borderRadius: AppRadius.allM,
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
                      ? AppColors.primaryLight
                      : AppColors.grey400,
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: AppTypography.labelMedium.copyWith(
                      color: esSeleccionado
                          ? AppColors.white
                          : AppColors.grey400,
                      fontWeight:
                          esSeleccionado ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
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
}
