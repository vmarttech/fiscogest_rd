import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app_shell.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/sales/presentation/pages/sales_page.dart';
import '../../features/inventario/presentation/pages/productos_page.dart';
import '../../features/clientes/presentation/pages/clientes_page.dart';
import '../../features/proveedores/presentation/pages/proveedores_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/impuestos/presentation/pages/impuestos_page.dart';
import '../../features/import_export/presentation/pages/import_export_page.dart';
import '../../features/configuracion/presentation/pages/configuracion_page.dart';
import '../../features/categorias/presentation/pages/categorias_page.dart';
import '../../features/marcas/presentation/pages/marcas_page.dart';
import '../../features/presentaciones/presentation/pages/presentaciones_page.dart';
import '../../features/unidades/presentation/pages/unidades_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/sales',
            builder: (context, state) => const SalesPage(),
          ),
          GoRoute(
            path: '/inventory',
            builder: (context, state) => const ProductosPage(),
          ),
          GoRoute(
            path: '/customers',
            builder: (context, state) => const ClientesPage(),
          ),
          GoRoute(
            path: '/suppliers',
            builder: (context, state) => const ProveedoresPage(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsPage(),
          ),
          GoRoute(
            path: '/taxes',
            builder: (context, state) => const ImpuestosPage(),
          ),
          GoRoute(
            path: '/import-export',
            builder: (context, state) => const ImportExportPage(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const ConfiguracionPage(),
          ),
          GoRoute(
            path: '/categorias',
            builder: (context, state) => const CategoriasPage(),
          ),
          GoRoute(
            path: '/marcas',
            builder: (context, state) => const MarcasPage(),
          ),
          GoRoute(
            path: '/presentaciones',
            builder: (context, state) => const PresentacionesPage(),
          ),
          GoRoute(
            path: '/unidades',
            builder: (context, state) => const UnidadesPage(),
          ),
        ],
      ),
    ],
  );
});
