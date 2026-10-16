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
    this.bottomBar,
    this.contentMaxWidth,
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

  /// Barra inferior (acciones Guardar/Cancelar).
  final Widget? bottomBar;

  /// Si se indica, AppPage usa este maxWidth (formularios ~720).
  final double? contentMaxWidth;

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
        : (useAppPage
              ? AppPage(maxWidth: contentMaxWidth, child: contenido)
              : contenido);

    return Scaffold(
      backgroundColor: backgroundColor ?? const Color(0xFFEEF2F6),
      appBar: showAppBar ? (appBar ?? _buildAppBar(context)) : null,
      body: bodyWidget == null ? null : AppAtmosphere(child: bodyWidget),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomBar,
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
      // Con menú fijo (AppShell) nunca mostrar hamburguesa en desktop/tablet
      final isDesktop = MediaQuery.of(context).size.width >= 900;

      if (principal && underShell && !isDesktop) {
        // Solo mostrar hamburguesa en móvil/tablet
        resolvedLeading = IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Menú',
          onPressed: () => ShellDrawerScope.open(context),
          style: IconButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else if (!principal) {
        resolvedLeading = IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Atrás',
          onPressed: () => safeBack(context),
          style: IconButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }

    final leadingWidget = resolvedLeading == null
        ? null
        : IconButtonTheme(
            data: IconButtonThemeData(
              style: IconButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            child: resolvedLeading,
          );

    return AppBar(
      toolbarHeight: subtitle != null ? 56 : 48,
      automaticallyImplyLeading: false,
      leading: leadingWidget,
      backgroundColor: AppColors.primary,
      flexibleSpace: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [AppColors.primaryDark, AppColors.primary],
          ),
        ),
      ),
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
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.18),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                          iconButtonTheme: IconButtonThemeData(
                            style: IconButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.1,
                              ),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          filledButtonTheme: FilledButtonThemeData(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primaryDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                          ),
                          elevatedButtonTheme: ElevatedButtonThemeData(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primaryDark,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          outlinedButtonTheme: OutlinedButtonThemeData(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
      bottom:
          bottom ??
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
