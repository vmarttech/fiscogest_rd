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
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/ventas_contenedor_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/nueva_venta_borrador_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/cotizaciones_historial_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/apartados_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/devoluciones_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/cobrar_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/pagar_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/descuentos_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/ofertas_page.dart';
import 'package:fiscogest_rd/features/clientes/presentation/pages/clientes_page.dart';
import 'package:fiscogest_rd/features/clientes/presentation/pages/clientes_gestion_page.dart';
import 'package:fiscogest_rd/features/proveedores/presentation/pages/proveedores_page.dart';
import 'package:fiscogest_rd/features/reports/presentation/pages/reports_page.dart';
import 'package:fiscogest_rd/features/impuestos/presentation/pages/impuestos_page.dart';
import 'package:fiscogest_rd/features/import_export/presentation/pages/import_export_page.dart';
import 'package:fiscogest_rd/features/configuracion/presentation/pages/configuracion_page.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/presentation/pages/lista_ajustes_page.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/presentation/pages/registrar_ajuste_page.dart';
import 'package:fiscogest_rd/features/transferencias/presentation/pages/registrar_transferencia_page.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/recepcion/registrar_recepcion_page.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/dashboard_compras_page.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/lista_compras_page.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/registrar_compra_page.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/detalle_compra_page.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/historial_costos_page.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/cuentas_pagar/lista_cuentas_pagar_page.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/cuentas_pagar/detalle_cuenta_pagar_page.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/cuentas_pagar/registrar_abono_page.dart';
import 'package:fiscogest_rd/features/presentaciones/presentation/pages/presentaciones_page.dart';
import 'package:fiscogest_rd/features/categorias/presentation/pages/categorias_page.dart';
import 'package:fiscogest_rd/features/marcas/presentation/pages/marcas_page.dart';
import 'package:fiscogest_rd/features/unidades/presentation/pages/unidades_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: DashboardPage.routeName,
        builder: (_, __) => const AppShell(child: DashboardPage()),
      ),
      GoRoute(
        path: '/sales',
        name: SalesPage.routeName,
        builder: (_, __) => const AppShell(child: SalesPage()),
      ),
      GoRoute(
        path: '/ventas',
        name: VentasContenedorPage.nombreRuta,
        builder: (_, __) => const AppShell(child: VentasContenedorPage()),
        routes: [
          GoRoute(
            path: 'registrar',
            builder: (_, __) => const AppShell(child: NuevaVentaBorradorPage()),
          ),
          GoRoute(
            path: 'cotizaciones/nueva',
            builder: (_, __) => const AppShell(child: NuevaVentaBorradorPage()),
          ),
          GoRoute(
            path: 'cotizaciones/historial',
            name: CotizacionesHistorialPage.routeName,
            builder: (_, __) => const AppShell(child: CotizacionesHistorialPage()),
          ),
          GoRoute(
            path: 'apartados',
            name: ApartadosPage.routeName,
            builder: (_, __) => const AppShell(child: ApartadosPage()),
          ),
          GoRoute(
            path: 'devoluciones',
            name: DevolucionesPage.routeName,
            builder: (_, __) => const AppShell(child: DevolucionesPage()),
          ),
          GoRoute(
            path: 'cobrar',
            name: CobrarPage.routeName,
            builder: (_, __) => const AppShell(child: CobrarPage()),
          ),
          GoRoute(
            path: 'pagar',
            name: PagarPage.routeName,
            builder: (_, __) => const AppShell(child: PagarPage()),
          ),
          GoRoute(
            path: 'descuentos',
            name: DescuentosPage.routeName,
            builder: (_, __) => const AppShell(child: DescuentosPage()),
          ),
          GoRoute(
            path: 'ofertas',
            name: OfertasPage.routeName,
            builder: (_, __) => const AppShell(child: OfertasPage()),
          ),
        ],
      ),
      GoRoute(
        path: '/compras',
        name: DashboardComprasPage.routeName,
        builder: (_, __) => const AppShell(child: DashboardComprasPage()),
        routes: [
          GoRoute(
            path: 'lista',
            name: ListaComprasPage.routeName,
            builder: (_, __) => const AppShell(child: ListaComprasPage()),
          ),
          GoRoute(
            path: 'registrar',
            name: RegistrarCompraPage.routeName,
            builder: (_, __) => const AppShell(child: RegistrarCompraPage()),
          ),
          GoRoute(
            path: 'detalle/:compraId',
            name: DetalleCompraPage.routeName,
            builder: (context, state) {
              int compraId = 0;
              final idDesdePath = state.pathParameters['compraId'];
              if (idDesdePath != null && idDesdePath.isNotEmpty) {
                final soloDigitos = idDesdePath.replaceAll(RegExp(r'[^0-9]'), '');
                compraId = int.tryParse(soloDigitos) ?? 0;
              }
              if (compraId == 0 && state.extra != null) {
                final extra = state.extra;
                if (extra is int) {
                  compraId = extra;
                } else if (extra is String) {
                  final soloDigitos = extra.replaceAll(RegExp(r'[^0-9]'), '');
                  compraId = int.tryParse(soloDigitos) ?? 0;
                }
              }
              return AppShell(child: DetalleCompraPage(compraId: compraId));
            },
          ),
          GoRoute(
            path: 'historial-costos/:productoId',
            name: HistorialCostosPage.routeName,
            builder: (context, state) {
              final idCrudo = state.pathParameters['productoId'] ?? '0';
              final soloDigitos = idCrudo.replaceAll(RegExp(r'[^0-9]'), '');
              final productoId = int.tryParse(soloDigitos) ?? 0;
              return AppShell(
                child: HistorialCostosPage(productoId: productoId),
              );
            },
          ),
          GoRoute(
            path: 'cuentas-pagar',
            name: ListaCuentasPagarPage.routeName,
            builder: (_, __) => const AppShell(child: ListaCuentasPagarPage()),
          ),
          GoRoute(
            path: 'cuentas-pagar/detalle/:cuentaId',
            name: DetalleCuentaPagarPage.routeName,
            builder: (context, state) {
              final idCrudo = state.pathParameters['cuentaId'] ?? '0';
              final soloDigitos = idCrudo.replaceAll(RegExp(r'[^0-9]'), '');
              final cuentaId = int.tryParse(soloDigitos) ?? 0;
              return AppShell(
                child: DetalleCuentaPagarPage(cuentaId: cuentaId),
              );
            },
          ),
          GoRoute(
            path: 'cuentas-pagar/registrar-abono/:cuentaId',
            name: RegistrarAbonoPage.routeName,
            builder: (context, state) {
              final idCrudo = state.pathParameters['cuentaId'] ?? '0';
              final soloDigitos = idCrudo.replaceAll(RegExp(r'[^0-9]'), '');
              final cuentaId = int.tryParse(soloDigitos) ?? 0;
              return AppShell(
                child: RegistrarAbonoPage(cuentaId: cuentaId),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/inventario',
        name: ProductosPage.routeName,
        builder: (_, __) => const AppShell(child: ProductosPage()),
      ),
      GoRoute(
        path: '/kardex',
        name: KardexPage.routeName,
        builder: (_, __) => const AppShell(child: KardexPage()),
      ),
      GoRoute(
        path: '/productos/nuevo',
        name: NuevoProductoPage.routeName,
        builder: (_, __) => const AppShell(child: NuevoProductoPage()),
      ),
      GoRoute(
        path: '/inventario/entrada/:productoId/:nombreProducto',
        name: RegistrarEntradaPage.routeName,
        builder: (context, state) {
          final productoIdCrudo = state.pathParameters['productoId'] ?? '0';
          final soloDigitosProd = productoIdCrudo.replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );
          final productoId = int.tryParse(soloDigitosProd) ?? 0;
          final nombreProducto = Uri.decodeComponent(
            state.pathParameters['nombreProducto'] ?? '',
          );
          return AppShell(
            child: RegistrarEntradaPage(
              productoId: productoId,
              nombreProducto: nombreProducto,
            ),
          );
        },
      ),
      GoRoute(
        path: '/inventario/salida/:productoId/:nombreProducto',
        name: RegistrarSalidaPage.routeName,
        builder: (context, state) {
          final productoIdCrudo = state.pathParameters['productoId'] ?? '0';
          final soloDigitosProd = productoIdCrudo.replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );
          final productoId = int.tryParse(soloDigitosProd) ?? 0;
          final nombreProducto = Uri.decodeComponent(
            state.pathParameters['nombreProducto'] ?? '',
          );
          return AppShell(
            child: RegistrarSalidaPage(
              productoId: productoId,
              nombreProducto: nombreProducto,
            ),
          );
        },
      ),
      GoRoute(
        path: '/inventario-fisico',
        name: RegistrarConteoPage.routeName,
        builder: (_, __) => const AppShell(child: RegistrarConteoPage()),
      ),
      GoRoute(
        path: '/inventario-fisico/listar',
        name: ListarConteosPage.routeName,
        builder: (_, __) => const AppShell(child: ListarConteosPage()),
      ),
      GoRoute(
        path: '/diferencias-conteo-fisico/:conteoId',
        name: DiferenciasConteoPage.routeName,
        builder: (context, state) {
          final conteoIdCrudo = state.pathParameters['conteoId'] ?? '0';
          final soloDigitosConteo = conteoIdCrudo.replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );
          final conteoId = int.tryParse(soloDigitosConteo) ?? 0;
          return AppShell(child: DiferenciasConteoPage(conteoId: conteoId));
        },
      ),
      GoRoute(
        path: '/lista-ajustes',
        name: ListaAjustesPage.routeName,
        builder: (_, __) => const AppShell(child: ListaAjustesPage()),
      ),
      GoRoute(
        path: '/registrar-ajuste',
        name: RegistrarAjustePage.routeName,
        builder: (_, __) => const AppShell(child: RegistrarAjustePage()),
      ),
      GoRoute(
        path: '/clientes',
        name: ClientesGestionPage.routeName,
        builder: (_, __) => const AppShell(child: ClientesGestionPage()),
      ),
      GoRoute(path: '/customers', redirect: (_, __) => '/clientes'),
      GoRoute(path: '/clients', redirect: (_, __) => '/clientes'),
      GoRoute(
        path: '/clientes/gestion',
        name: ClientesPage.routeName,
        builder: (_, __) => const AppShell(child: ClientesPage()),
      ),
      GoRoute(
        path: '/proveedores',
        name: ProveedoresPage.routeName,
        builder: (_, __) => const AppShell(child: ProveedoresPage()),
      ),
      GoRoute(path: '/suppliers', redirect: (_, __) => '/proveedores'),
      GoRoute(
        path: '/recepcion/:compraId/:proveedorId',
        name: RegistrarRecepcionPage.routeName,
        builder: (context, state) {
          final idCompraCrudo = state.pathParameters['compraId']!;
          final compraIdLimpio = idCompraCrudo.replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );
          final compraId = int.tryParse(compraIdLimpio) ?? 0;
          final idProvCrudo = state.pathParameters['proveedorId']!;
          final provIdLimpio = idProvCrudo.replaceAll(RegExp(r'[^0-9]'), '');
          final proveedorId = int.tryParse(provIdLimpio) ?? 0;
          return AppShell(
            child: RegistrarRecepcionPage(
              compraId: compraId,
              proveedorId: proveedorId,
            ),
          );
        },
      ),
      GoRoute(
        path: '/transferencias/registrar',
        name: RegistrarTransferenciaPage.routeName,
        builder: (_, __) => const AppShell(child: RegistrarTransferenciaPage()),
      ),
      GoRoute(
        path: '/presentaciones',
        name: PresentacionesPage.routeName,
        builder: (_, __) => const AppShell(child: PresentacionesPage()),
      ),
      GoRoute(
        path: '/categorias',
        name: CategoriasPage.routeName,
        builder: (_, __) => const AppShell(child: CategoriasPage()),
      ),
      GoRoute(
        path: '/marcas',
        name: MarcasPage.routeName,
        builder: (_, __) => const AppShell(child: MarcasPage()),
      ),
      GoRoute(
        path: '/unidades',
        name: UnidadesPage.routeName,
        builder: (_, __) => const AppShell(child: UnidadesPage()),
      ),
      GoRoute(
        path: '/reports',
        name: ReportsPage.routeName,
        builder: (_, __) => const AppShell(child: ReportsPage()),
      ),
      GoRoute(
        path: '/impuestos',
        name: ImpuestosPage.routeName,
        builder: (_, __) => const AppShell(child: ImpuestosPage()),
      ),
      GoRoute(path: '/taxes', redirect: (_, __) => '/impuestos'),
      GoRoute(
        path: '/import-export',
        name: ImportExportPage.routeName,
        builder: (_, __) => const AppShell(child: ImportExportPage()),
      ),
      GoRoute(path: '/import', redirect: (_, __) => '/import-export'),
      GoRoute(
        path: '/configuracion',
        name: ConfiguracionPage.routeName,
        builder: (_, __) => const AppShell(child: ConfiguracionPage()),
      ),
      GoRoute(path: '/settings', redirect: (_, __) => '/configuracion'),
    ],
  );
});
