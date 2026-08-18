import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/presentation/widgets/app_shell.dart';
import 'package:fiscogest_rd/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:fiscogest_rd/features/inventario/presentation/pages/productos_page.dart';
import 'package:fiscogest_rd/features/inventario/presentation/pages/kardex_page.dart';
import 'package:fiscogest_rd/features/inventario/presentation/pages/nuevo_producto_page.dart';
import 'package:fiscogest_rd/features/inventario/presentation/pages/registrar_entrada_page.dart';
import 'package:fiscogest_rd/features/inventario/presentation/pages/registrar_salida_page.dart';
import 'package:fiscogest_rd/features/inventario_fisico/presentation/pages/registrar_conteo_page.dart';
import 'package:fiscogest_rd/features/inventario_fisico/presentation/pages/diferencias_conteo_page.dart';
import 'package:fiscogest_rd/features/inventario_fisico/presentation/pages/listar_conteos_page.dart';
import 'package:fiscogest_rd/features/sales/presentation/pages/sales_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/ventas_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/registrar_venta_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/cotizaciones_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/apartados_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/devoluciones_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/cobrar_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/pagar_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/descuentos_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/ofertas_page.dart';
import 'package:fiscogest_rd/features/clientes/presentation/pages/clientes_page.dart';
import 'package:fiscogest_rd/features/proveedores/presentation/pages/proveedores_page.dart';
import 'package:fiscogest_rd/features/reports/presentation/pages/reports_page.dart';
import 'package:fiscogest_rd/features/impuestos/presentation/pages/impuestos_page.dart';
import 'package:fiscogest_rd/features/import_export/presentation/pages/import_export_page.dart';
import 'package:fiscogest_rd/features/configuracion/presentation/pages/configuracion_page.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/presentation/pages/lista_ajustes_page.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/presentation/pages/registrar_ajuste_page.dart';
import 'package:fiscogest_rd/features/transferencias/presentation/pages/registrar_transferencia_page.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/recepcion/registrar_recepcion_page.dart';
import 'package:fiscogest_rd/features/presentaciones/presentation/pages/presentaciones_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', name: 'dashboard', builder: (_, __) => const AppShell(child: DashboardPage())),
      GoRoute(path: '/sales', name: 'facturacion', builder: (_, __) => const AppShell(child: SalesPage())),
      GoRoute(
        path: '/ventas',
        name: VentasPage.routeName,
        builder: (_, __) => const AppShell(child: VentasPage()),
        routes: [
          GoRoute(path: 'registrar', name: RegistrarVentaPage.routeName, builder: (_, __) => const AppShell(child: RegistrarVentaPage())),
          GoRoute(path: 'cotizaciones', name: CotizacionesPage.routeName, builder: (_, __) => const AppShell(child: CotizacionesPage())),
          GoRoute(path: 'apartados', name: ApartadosPage.routeName, builder: (_, __) => const AppShell(child: ApartadosPage())),
          GoRoute(path: 'devoluciones', name: DevolucionesPage.routeName, builder: (_, __) => const AppShell(child: DevolucionesPage())),
          GoRoute(path: 'cobrar', name: CobrarPage.routeName, builder: (_, __) => const AppShell(child: CobrarPage())),
          GoRoute(path: 'pagar', name: PagarPage.routeName, builder: (_, __) => const AppShell(child: PagarPage())),
          GoRoute(path: 'descuentos', name: DescuentosPage.routeName, builder: (_, __) => const AppShell(child: DescuentosPage())),
          GoRoute(path: 'ofertas', name: OfertasPage.routeName, builder: (_, __) => const AppShell(child: OfertasPage())),
        ],
      ),
      GoRoute(path: '/inventory', name: 'inventario', builder: (_, __) => const AppShell(child: ProductosPage())),
      GoRoute(path: '/kardex', name: 'kardex', builder: (_, __) => const AppShell(child: KardexPage())),
      GoRoute(path: '/productos/nuevo', name: 'nuevo-producto', builder: (_, __) => const AppShell(child: NuevoProductoPage())),

      GoRoute(
        path: '/inventario/entrada/:productoId/:nombreProducto',
        name: RegistrarEntradaPage.routeName,
        builder: (context, state) {
          final productoId = int.tryParse(state.pathParameters['productoId'] ?? '0') ?? 0;
          final nombreProducto = Uri.decodeComponent(state.pathParameters['nombreProducto'] ?? '');
          return AppShell(child: RegistrarEntradaPage(productoId: productoId, nombreProducto: nombreProducto));
        },
      ),
      GoRoute(
        path: '/inventario/salida/:productoId/:nombreProducto',
        name: RegistrarSalidaPage.routeName,
        builder: (context, state) {
          final productoId = int.tryParse(state.pathParameters['productoId'] ?? '0') ?? 0;
          final nombreProducto = Uri.decodeComponent(state.pathParameters['nombreProducto'] ?? '');
          return AppShell(child: RegistrarSalidaPage(productoId: productoId, nombreProducto: nombreProducto));
        },
      ),

      GoRoute(path: '/inventario-fisico', name: 'inventario_fisico', builder: (_, __) => const AppShell(child: RegistrarConteoPage())),
      GoRoute(path: '/inventario-fisico/listar', name: ListarConteosPage.routeName, builder: (_, __) => const AppShell(child: ListarConteosPage())),
      GoRoute(path: '/lista-ajustes', name: ListaAjustesPage.routeName, builder: (_, __) => const AppShell(child: ListaAjustesPage())),
      GoRoute(path: '/registrar-ajuste', name: RegistrarAjustePage.routeName, builder: (_, __) => const AppShell(child: RegistrarAjustePage())),
      GoRoute(path: '/clientes', name: 'clientes', builder: (_, __) => const AppShell(child: ClientesPage())),
      GoRoute(path: '/proveedores', name: 'proveedores', builder: (_, __) => const AppShell(child: ProveedoresPage())),
      GoRoute(path: '/reports', name: 'reportes', builder: (_, __) => const AppShell(child: ReportsPage())),
      GoRoute(path: '/impuestos', name: 'impuestos', builder: (_, __) => const AppShell(child: ImpuestosPage())),
      GoRoute(path: '/import-export', name: 'importar_exportar', builder: (_, __) => const AppShell(child: ImportExportPage())),
      GoRoute(path: '/configuracion', name: 'configuracion', builder: (_, __) => const AppShell(child: ConfiguracionPage())),
      GoRoute(path: '/registrar-conteo-fisico', name: RegistrarConteoPage.routeName, builder: (_, __) => const AppShell(child: RegistrarConteoPage())),

      GoRoute(
        path: '/diferencias-conteo-fisico/:conteoId',
        name: DiferenciasConteoPage.routeName,
        builder: (context, state) {
          final conteoId = int.parse(state.pathParameters['conteoId']!);
          return AppShell(child: DiferenciasConteoPage(conteoId: conteoId));
        },
      ),

      GoRoute(path: '/transferencias/registrar', name: RegistrarTransferenciaPage.routeName, builder: (_, __) => const AppShell(child: RegistrarTransferenciaPage())),

      GoRoute(
        path: '/recepcion/:compraId/:proveedorId',
        name: RegistrarRecepcionPage.routeName,
        builder: (context, state) {
          final compraId = state.pathParameters['compraId'] ?? '';
          final proveedorId = state.pathParameters['proveedorId'] ?? '';
          return AppShell(child: RegistrarRecepcionPage(compraId: compraId, proveedorId: proveedorId));
        },
      ),

      GoRoute(path: '/presentaciones', name: PresentacionesPage.routeName, builder: (_, __) => const AppShell(child: PresentacionesPage())),
    ],
  );
});
