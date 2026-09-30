import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_page.dart';
import 'package:fiscogest_rd/core/ui/app_atmosphere.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/presentation/widgets/app_shell.dart';
import 'package:fiscogest_rd/core/presentation/widgets/shell_drawer_scope.dart';
import 'package:fiscogest_rd/core/navigation/safe_back.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    this.subtitle,
    this.body,
    this.backgroundColor,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.appBar,
    this.bottom,
    this.padding,
    this.floatingActionButton,
    this.centerTitle = false,
    this.showAppBar = true,
    this.useAppPage = true,
  });

  final String? title;
  final String? subtitle;
  final Widget? body;
  final Color? backgroundColor;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final PreferredSizeWidget? appBar;
  final PreferredSizeWidget? bottom;
  final EdgeInsetsGeometry? padding;
  final Widget? floatingActionButton;
  final bool centerTitle;
  final bool showAppBar;
  /// Limita y centra el body (PC con menú oculto).
  final bool useAppPage;

  /// Rutas de módulo: menú sándwich, sin flecha atrás.
  static const rutasPrincipales = {
    '/',
    '/ventas',
    '/ventas/cobro',
    '/creditos',
    '/compras',
    '/inventario',
    '/clientes',
    '/proveedores',
    '/sales',
    '/reports',
    '/impuestos',
    '/import-export',
    '/configuracion',
    '/kardex',
    '/categorias',
    '/marcas',
    '/unidades',
    '/presentaciones',
    '/ajustes-inventario',
    '/lista-ajustes',
    '/inventario-fisico',
    '/inventario-fisico/listar',
  };

  static bool esRutaPrincipal(String path) => rutasPrincipales.contains(path);

  @override
  Widget build(BuildContext context) {
    final Widget? contenido = padding != null && body != null
        ? Padding(padding: padding!, child: body!)
        : body;

    final Widget? bodyWidget = contenido == null
        ? null
        : (useAppPage ? AppPage(child: contenido) : contenido);

    return Scaffold(
      backgroundColor: backgroundColor ?? const Color(0xFFEEF2F6),
      appBar: showAppBar ? (appBar ?? _buildAppBar(context)) : null,
      body: bodyWidget == null
          ? null
          : AppAtmosphere(child: bodyWidget),
      floatingActionButton: floatingActionButton,
    );
  }

  PreferredSizeWidget? _buildAppBar(BuildContext context) {
    if (title == null && bottom == null) return null;

    final path = GoRouterState.of(context).uri.path;
    final principal = esRutaPrincipal(path);
    final underShell =
        context.findAncestorWidgetOfExactType<AppShell>() != null;

    Widget? resolvedLeading = leading;
    if (resolvedLeading == null && showBackButton) {
      if (principal && underShell) {
        resolvedLeading = IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Menú',
          onPressed: () => ShellDrawerScope.open(context),
        );
      } else if (!principal) {
        resolvedLeading = IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Atrás',
          onPressed: () => safeBack(context),
        );
      }
    }

    return AppBar(
      toolbarHeight: subtitle != null ? 56 : 48,
      automaticallyImplyLeading: false,
      leading: resolvedLeading,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      titleSpacing: 4,
      centerTitle: centerTitle,
      title: title == null
          ? null
          : Column(
              crossAxisAlignment: centerTitle
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h4.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
      actions: actions == null
          ? null
          : [
              for (final action in actions!)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: IconTheme(
                    data: const IconThemeData(color: Colors.white, size: 22),
                    child: DefaultTextStyle(
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                          ),
                          iconButtonTheme: IconButtonThemeData(
                            style: IconButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        child: action,
                      ),
                    ),
                  ),
                ),
            ],
      iconTheme: const IconThemeData(color: Colors.white, size: 24),
      actionsIconTheme: const IconThemeData(color: Colors.white, size: 23),
      bottom: bottom ??
          PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
    );
  }
}
